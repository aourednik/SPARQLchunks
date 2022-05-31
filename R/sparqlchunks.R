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
  code <- paste(options$code, collapse = '\n')
  ep<- options$endpoint
  qm <- paste(ep, "?", "query", "=", gsub("\\+", "%2B", utils::URLencode(code, reserved = TRUE)), "", sep = "")
  proxy_url <- curl::ie_get_proxy_for_url(ep)
  proxy_config <- httr::use_proxy(url=proxy_url)
  varname <- options$output.var
  if(is.null(options$output.type)) {
    output_type <- "dataframe"
  } else {
    output_type <- options$output.type
  }
  if (output_type=="list") {
    out <- httr::GET(qm,proxy_config, httr::timeout(60)) %>% xml2::read_xml() %>% xml2::as_list()
    nresults <- length(out$sparql$results)
  } else {
    queryres_csv <- httr::GET(qm,proxy_config, httr::timeout(60), httr::add_headers(c(Accept = "text/csv")))
    out <- rawToChar(queryres_csv$content)
    out <- textConnection(out)
    out <- utils::read.csv(out)
    nresults <- nrow(out)
  }
  chunkout <- ifelse(!is.null(varname),qm,out)
  text <- paste("The SPARQL query returned",nresults,"results")
  if (!is.null(varname)) assign(varname, out, envir = knitr::knit_global())
  knitr::engine_output(options, options$code, chunkout, extra=text)
}

#' Fetch data from a SPARQL endpoint and store the output in a dataframe
#' @param endpoint The SPARQL endpoint (a URL)
#' @param query The SPARQL query (character)
#' @examples library(SPARQLchunks)
#' endpoint <- "https://lindas.admin.ch/query"
#' query <- "PREFIX schema: <http://schema.org/>
#'   SELECT * WHERE {
#'   ?sub a schema:DataCatalog .
#'   ?subtype a schema:DataType .
#' }"
#' result_df <- sparql2df(endpoint,query)
#' @export
sparql2df <- function(endpoint,query) {
	proxy_url <- curl::ie_get_proxy_for_url(endpoint)
	proxy_config <- httr::use_proxy(url=proxy_url)
	qm <- paste(endpoint, "?", "query", "=", gsub("\\+", "%2B", utils::URLencode(query, reserved = TRUE)), "", sep = "")
	queryres_csv <- httr::GET(qm,proxy_config, httr::timeout(60), httr::add_headers(c(Accept = "text/csv")))
	out <- rawToChar(queryres_csv$content)
	out <- textConnection(out)
	out <- utils::read.csv(out)
	return(out)
}

#' Fetch data from a SPARQL endpoint and store the output in a list
#' @param endpoint The SPARQL endpoint (a URL)
#' @param query The SPARQL query (character)
#' @examples library(SPARQLchunks)
#' endpoint <- "https://lindas.admin.ch/query"
#' query <- "PREFIX schema: <http://schema.org/>
#'   SELECT * WHERE {
#'   ?sub a schema:DataCatalog .
#'   ?subtype a schema:DataType .
#' }"
#' result_list <- sparql2list(endpoint,query)
#' @export
sparql2list <- function(endpoint,query) {
	proxy_url <- curl::ie_get_proxy_for_url(endpoint)
	proxy_config <- httr::use_proxy(url=proxy_url)
	qm <- paste(endpoint, "?", "query", "=", gsub("\\+", "%2B", utils::URLencode(query, reserved = TRUE)), "", sep = "")
	out <- httr::GET(qm,proxy_config, httr::timeout(60)) %>% xml2::read_xml() %>% xml2::as_list()
	return(out)
}

.onAttach <- function(libname, pkgname) {
	packageStartupMessage("Run `knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)` in your Rmd setup chunk to be able to execute SPARQL chunks.")
}
