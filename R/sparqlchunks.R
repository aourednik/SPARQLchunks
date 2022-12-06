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
#' @usage eng_sparql(options)
#' @param options Chunk options, as provided by \code{knitr} during chunk execution. Chunk option for this is \code{sparql}
#' @return Data in dataframe or list form (depending on options)
#' @author [André Ourednik](https://ourednik.info)
#' @examples library(SPARQLchunks)
#' knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)
#' @references André Ourednik (2021). Execute SPARQL chunks in Rmarkdown Available at:  https://ourednik.info/maps/2021/12/14/execute-sparql-chunks-in-r-markdown/
#' @family important functions
#' @keywords documentation
#' @export
eng_sparql <- function(options) {
  code <- paste(options$code, collapse = "\n")
  ep <- options$endpoint
  if (!is.null(options$autoproxy)) {
    autoproxy <- options$autoproxy
  } else {
    autoproxy <- FALSE
  }
  if (!is.null(options$auth)) {
    auth <- options$auth
  } else {
    auth <- FALSE
  }
  qm <- paste(ep, "?", "query", "=",
    gsub("\\+", "%2B", utils::URLencode(code, reserved = TRUE)), "",
    sep = ""
  )
  varname <- options$output.var
  if (is.null(options$output.type)) {
    output_type <- "dataframe"
  } else {
    output_type <- options$output.type
  }
  if (output_type == "list") {
    out <- sparql2list(ep, code, autoproxy, auth)
    nresults <- length(out$sparql$results)
  } else {
    out <- sparql2df(ep, code, autoproxy, auth)
    nresults <- nrow(out)
  }
  chunkout <- ifelse(!is.null(varname), qm, out)
  message(paste("The SPARQL query returned", nresults, "results"))
  if (!is.null(varname)) {
    assign(varname, out, envir = knitr::knit_global())
  }
  knitr::engine_output(options, options$code, chunkout)
}

#' Fetch data from a SPARQL endpoint and store the output in a dataframe
#' @param endpoint The SPARQL endpoint (a URL)
#' @param query The SPARQL query (character)
#' @param autoproxy Try to detect a proxy automatically (boolean). Useful on Windows machines behind corporate firewalls
#' @param auth Authentication Information (httr-authenticate-object)
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
  if (autoproxy) {
    proxy_config <- autoproxyconfig(endpoint)
  } else {
    proxy_config <- httr::use_proxy(url = NULL)
  }
  acceptype <- "text/csv"
  outcontent <- get_outcontent(endpoint, query, acceptype, proxy_config, auth)
  out <- textConnection(outcontent)
  df <- utils::read.csv(out)
  return(df)
}

#' Fetch data from a SPARQL endpoint and store the output in a list
#' @param endpoint The SPARQL endpoint (URL)
#' @param query The SPARQL query (character)
#' @param autoproxy Try to detect a proxy automatically (boolean). Useful on Windows machines behind corporate firewalls
#' @param auth Authentication Information (httr-authenticate-object)
#' @examples library(SPARQLchunks)
#' endpoint <- "https://lindas.admin.ch/query"
#' query <- "PREFIX schema: <http://schema.org/>
#'   SELECT * WHERE {
#'   ?sub a schema:DataCatalog .
#'   ?subtype a schema:DataType .
#' }"
#' result_list <- sparql2list(endpoint, query)
#' @export
sparql2list <- function(endpoint, query, autoproxy = FALSE, auth = NULL) {
  if (autoproxy) {
    proxy_config <- autoproxyconfig(endpoint)
  } else {
    proxy_config <- httr::use_proxy(url = NULL)
  }
  acceptype <- "text/xml"
  outcontent <- get_outcontent(endpoint, query, acceptype, proxy_config, auth)
  list <- xml2::read_xml(outcontent) %>% xml2::as_list()
  return(list)
}

#' Try to determine the proxy settings automatically
#' @param endpoint The SPARQL endpoint (URL)
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
    message(paste("No proxy found or needed to access the endpoint", endpoint))
  }
  return(httr::use_proxy(url = proxy_url))
}

#' Get the content from the endpoint
#' @param endpoint The SPARQL endpoint (URL)
#' @param query The SPARQL query (character)
#' @param acceptype 'text/csv' or 'text/xml' (character)
#' @param proxy_config Detected proxy configuration (list)
#' @param auth Authentication Information (httr-authenticate-object)
get_outcontent <- function(endpoint, query, acceptype, proxy_config, auth = NULL) {
  qm <- paste(endpoint, "?", "query", "=",
    gsub("\\+", "%2B", utils::URLencode(query, reserved = TRUE)), "",
    sep = ""
  )

  outcontent <- tryCatch(
    {
      out <- httr::GET(
        qm,
        proxy_config, auth,
        httr::timeout(60),
        httr::add_headers(c(Accept = acceptype))
      )
      httr::content(out, "text", encoding = "UTF-8")
    },
    error = function(e) {
      # @see https://github.com/r-lib/httr/issues/417 The download.file function in base R uses IE settings, including proxy password, when you use download
      # method wininet which is now the default on windows.
      if (.Platform$OS.type == "windows") {
        tempfile <- file.path(tempdir(), "temp.txt")
        utils::download.file(qm,
          method = "wininet",
          headers = c(Accept = acceptype),
          tempfile
        )
        temp <- paste(readLines(tempfile), collapse = "\n")
        unlink(tempfile)
        return(temp)
      }
    }
  )
  if (nchar(outcontent) < 1) {
    warning(paste0(
      "First query attempt result is empty. Trying without '",
      acceptype,
      "' header. The result is not guaranteed to be a list."
    ))
    outcontent <- tryCatch(
      {
        out <- httr::GET(
          qm,
          proxy_config, auth,
          httr::timeout(60)
        )
        if (out$status == 401){
          warning("Authentication required. Provide valid authentication with the auth parameter")
        } else {
          httr::warn_for_status(out)
        }
        httr::content(out, "text", encoding = "UTF-8")
      },
      error = function(e) {
        if (.Platform$OS.type == "windows") {
          tempfile <- file.path(tempdir(), "temp.txt")
          utils::download.file(qm, method = "wininet", tempfile)
          temp <- paste(readLines(tempfile), collapse = "\n")
          unlink(tempfile)
          return(temp)
        }
      }
    )
    if (nchar(outcontent) < 1) {
      warning("The query result is still empty")
    }
  }
  return(outcontent)
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Run `knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)` in your Rmd setup chunk to be able to execute SPARQL chunks.")
}
