#' Add `sparql` as knit-engine to knitr package
#'
#' The \code{sparql} engine can be activated via
#'
#' ```
#' knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)
#' ```
#'
#' This will be set within an R Markdown document's setup chunk. Do not use eng_sparql function elsewhere.
#'
#' @description Pointing knitr to this function alows you to run SPARQL chunks from R Markdown: `knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)`. Usage is internal.
#' @usage eng_sparql(opts)
#' @param opts Chunk options, as provided by \code{knitr} during chunk execution. Chunk option for this is \code{sparql}. Note that we avoid calling this "options" to avoid conflict with an R system function name.
#' @return Data in dataframe or list form (depending on opts). The function only returns when no output.var to store its result into is defined.
#' @author [André Ourednik](https://ourednik.info)
#' @examples library(SPARQLchunks)
#' knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)
#' @references André Ourednik (2021). Execute SPARQL chunks in Rmarkdown Available at:  https://ourednik.info/maps/2021/12/14/execute-sparql-chunks-in-r-markdown/
#' @family important functions
#' @keywords documentation
#' @importFrom utils capture.output
#' @export
eng_sparql <- function(opts) {
	code <- paste(opts$code, collapse = "\n")
	if (!is.null(opts$endpoint)) {
		ep <- opts$endpoint
	} else {
		stop("No endpoint defined")
	}
	if (!is.null(opts$autoproxy)) {
		autoproxy <- opts$autoproxy
	} else {
		autoproxy <- FALSE
	}
	if (!is.null(opts$auth)) {
		auth <- opts$auth
	} else {
		auth <- NULL # This needs to be NULL, not FALSE, or the call to sparql2list and sparql2df will generate chaotic errors
	}
	qm <- paste(
		ep, "?", "query", "=",
		gsub("\\+", "%2B", utils::URLencode(code, reserved = TRUE)), "",
		sep = ""
	)
	if (is.null(opts$output.type)) {
		output_type <- "dataframe"
	} else {
		output_type <- opts$output.type
	}
	if (output_type == "list") {
		out <- sparql2list(ep, code, autoproxy, auth)
		nresults <- length(out$sparql$results)
	} else {
		out <- sparql2df(ep, code, autoproxy, auth)
		nresults <- nrow(out)
	}
	varname <- opts$output.var
	# chunkout <- ifelse(!is.null(varname), qm, out)
	if (!is.null(varname)) {
		chunkout <- qm
	} else {
		chunkout <- capture.output(print(out))  # ensures output is printable text
	}
	message(paste("The SPARQL query returned", nresults, "results"))
	if (!is.null(varname)) {
		assign(varname, out, envir = knitr::knit_global())
	} else {
		warning("No output variable defined")
		return(out)
	}
	knitr::engine_output(opts, opts$code, chunkout)
}

#' Fetch data from a SPARQL endpoint and store the output in a dataframe
#' @param endpoint The SPARQL endpoint (a URL)
#' @param query The SPARQL query (character)
#' @param autoproxy Try to detect a proxy automatically (boolean). Useful on Windows machines behind corporate firewalls
#' @param auth Authentication Information (httr-authenticate-object)
#' @return SPARQL query result in data.frame format
#' @examples library(SPARQLchunks)
#' endpoint <- "https://lindas.admin.ch/query"
#' query <- "PREFIX schema: <http://schema.org/>
#'   SELECT * WHERE {
#'   ?sub a schema:DataCatalog .
#'   ?subtype a schema:DataType .
#' }"
#' result_df <- sparql2df(endpoint, query)
#' @export
sparql2df <- function(endpoint, query, autoproxy = FALSE, auth = NULL) {
	proxy_config <- ifelse(
		autoproxy,
		autoproxyconfig(endpoint),
		httr::use_proxy(url = NULL)
	)
  acceptype <- "text/csv"
  outcontent <- get_outcontent(endpoint, query, acceptype, proxy_config, auth)
  tryCatch(
  	content <- textConnection(outcontent$content),
  	error = function(e) {
  		stop(
  			sprintf(
  				"There is something wrong with the output content: %s",
  				outcontent
  			)
  		)
  	}
  )
  tryCatch(
    {
      df <- utils::read.csv(content)
    },
    error = function(e) {
      # utils::browseURL(outcontent$httpquery)
      stop(
        sprintf(
          "Reply from SPARQL endpoint received but could not convert it to a data.frame.\nVerify the query result in a web browser:\n%s",
          outcontent$httpquery
        )
      )
    }
  )
  return(df)
}

#' Fetch data from a SPARQL endpoint and store the output in a list
#' @param endpoint The SPARQL endpoint (URL)
#' @param query The SPARQL query (character)
#' @param autoproxy Try to detect a proxy automatically (boolean). Useful on Windows machines behind corporate firewalls
#' @param auth Authentication Information (httr-authenticate-object)
#' @return SPARQL query result in the form of a list
#' @examples endpoint <- "https://lindas.admin.ch/query"
#' query <- "PREFIX schema: <http://schema.org/>
#'   SELECT * WHERE {
#'   ?sub a schema:DataCatalog .
#'   ?subtype a schema:DataType .
#' }"
#' result_list <- sparql2list(endpoint, query)
#' @export
sparql2list <- function(endpoint, query, autoproxy = FALSE, auth = NULL) {
	proxy_config <- ifelse(
		autoproxy,
		autoproxyconfig(endpoint),
		httr::use_proxy(url = NULL)
	)
  acceptype <- "application/xml"
  outcontent <- get_outcontent(endpoint, query, acceptype, proxy_config, auth)
  tryCatch(
  	content <- outcontent$content,
  	error = function(e) {
  		stop(
  			sprintf(
  				"There is something wrong with the retrieved data: %s",
  				outcontent
  			)
  		)
  	}
  )
  tryCatch(
    {
      list <- xml2::as_list(
      	xml2::read_xml(content)
      )
    },
    error = function(e) {
      warning("Query could not be parsetd as xml. Returning unparsed query return values.")
      list <- list(warning="non parsable", content=content)
    }
  )
  # if (!is.list(list) || is.null(list$sparql)) {
  # 	warning("The response is not a valid SPARQL XML result. Cannot parse.")
  # }
  return(list)
}

#' Get the content from the endpoint
#' @param endpoint The SPARQL endpoint (URL)
#' @param query The SPARQL query (character)
#' @param acceptype 'text/csv' or 'text/xml' (character)
#' @param proxy_config Detected proxy configuration (list)
#' @param auth Authentication Information (httr-authenticate-object)
#' @return The result of the SPARQL query as a list or, if this fails, failure message.
#' @noRd
get_outcontent <- function(endpoint, query, acceptype, proxy_config, auth = NULL) {
  qm <- paste(endpoint, "?", "query", "=",
    gsub("\\+", "%2B", utils::URLencode(query, reserved = TRUE)), "",
    sep = ""
  )
  message("Preparing to send query to: ", endpoint)
  message("SPARQL string:\n", query)
  message("Query URL:\n", qm )
  content <- tryCatch(
    {
      out <- httr::GET(
        qm,
        proxy_config, auth,
        httr::timeout(60),
        httr::add_headers(c(Accept = acceptype)),
        httr::user_agent("R client SPARQLChunks")
      )
      if (out$status == 401) {warning(
      	"Authentication required. Provide valid authentication with the auth parameter"
      )} else {
      	httr::warn_for_status(out)
      }
      httr::content(out, "text", encoding = "UTF-8") # Don't use return(...). If you use return(...) inside a block that is being assigned (x <- tryCatch({...})), you're exiting the function, not just returning a value for assignment.
    },
    error = function(e) {
      # @see https://github.com/r-lib/httr/issues/417
      # The download.file function in base R uses IE settings, including proxy password, when you use download
      # method wininet which is now the default on windows.
      if (is_windows()) {
        tempfile <- file.path(tempdir(), "temp.txt")
        utils::download.file(qm,
          method = "wininet",
          headers = c(Accept = acceptype),
          tempfile
        )
        temp <- paste(readLines(tempfile), collapse = "\n")
        unlink(tempfile)
        temp
      }
    }
  )
  if (is.null(content) || nchar(content) < 1) {
    warning(
    	sprintf("First query attempt result is empty. Trying without Accept=%s header. The result is not guaranteed to be a list.",
    	acceptype)
    )
    content <- tryCatch(
      {
        out <- httr::GET(
          qm,
          proxy_config, auth,
          httr::timeout(60),
          httr::user_agent("R client SPARQLChunks")
        )
        if (out$status == 401) {warning(
        	"Authentication required. Provide valid authentication with the auth parameter"
        )} else {
          httr::warn_for_status(out)
        }
        httr::content(out, "text", encoding = "UTF-8")
      },
      error = function(e) {
        if (is_windows()) {
          tempfile <- file.path(tempdir(), "temp.txt")
          utils::download.file(qm, method = "wininet", tempfile)
          temp <- paste(readLines(tempfile), collapse = "\n")
          unlink(tempfile)
          temp
        }
      }
    )
    if (is.null(content) || nchar(content) < 1) {
      warning("The query result is still empty")
    }
  }
  if (inherits(content, "response")) {
  	if (httr::status_code(content) >= 400) {
  		stop(sprintf("HTTP error %s: %s", httr::status_code(content), httr::http_status(content)$message))
  	}
  }
  return(list(
    content = content,
    httpquery = qm
  ))
}

#' Try to determine the proxy settings automatically
#' @param endpoint The SPARQL endpoint (URL)
#' @return Confirmation of the proxy setting
#' @noRd
autoproxyconfig <- function(endpoint) {
	message("Trying to determine proxy parameters")
	proxy_url <- tryCatch(
		{
			curl::ie_get_proxy_for_url(endpoint)
		},
		error = function(e) {
			message("Automatic proxy detection with curl::curl::ie_get_proxy_for_url() failed.")
			return(NULL)
		}
	)
	if (!is.null(proxy_url)) {
		message(paste("Using proxy:", proxy_url))
	} else {
		message(paste("No proxy found, nor needed, to access the endpoint", endpoint))
	}
	return(httr::use_proxy(url = proxy_url))
}

#' Verify if platform is Windows
#' @return TRUE if platform is Windows, FALSE otherwise
#' @noRd
is_windows <- function() {
	.Platform$OS.type == "windows"
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Run `knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)` in your Rmd setup chunk to be able to execute SPARQL chunks.")
}
