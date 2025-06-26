library(testthat)
library(mockery)

test_that("Calls sparql2list when output.type = 'list'", {
	query <- "PREFIX schema: <http://schema.org/>
		SELECT * WHERE {
			?sub a schema:DataCatalog .
			?subtype a schema:DataType .
	}"
	endpoint <- "https://lindas.admin.ch/query"
	opt <- list(
		code = query,
		endpoint = endpoint,
		output.type = "list",
		engine = "sparql",
		echo = F,
		label = "test",
		results = "markup"     # required to avoid 'missing value' error
	)
	mock_sparql2list <- function(...) {
		list(sparql = list(results = list(1, 2, 3)))
	}
	mockery::stub(eng_sparql, "sparql2list", mock_sparql2list) # calls mock_sparql2list instead of sparql2list
	output <- eng_sparql(opt)
	expect_true(grepl("results", output))
})


test_that("Calls sparql2df when output.type = 'dataframe'", {
	query <- "PREFIX schema: <http://schema.org/>
		SELECT * WHERE {
			?sub a schema:DataCatalog .
			?subtype a schema:DataType .
	}"
	endpoint <- "https://lindas.admin.ch/query"
	opt <- list(
		code = query,
		endpoint = endpoint,
		output.type = "dataframe",
		engine = "sparql",
		echo = F,
		label = "test",
		results = "markup"     # required to avoid 'missing value' error
	)
	mock_sparql2df <- mockery::mock(
		data.frame(column1 = c("a", "b", "c"), column2 = c("d", "e", "f"))
	)
	mockery::stub(eng_sparql, "sparql2df", mock_sparql2df) # calls mock_sparql2list instead of sparql2list
	output <- eng_sparql(opt)
	mockery::expect_called(mock_sparql2df, 1)
	testthat::expect_type(output, "character")
	expect_true(any(grepl("a|b|c", output)))  # based on mock df content
})


test_that("sparql2list throws error with sprintf when content access fails", {
	# Force get_outcontent to return a string instead of list
	broken_outcontent <- "not_a_list"

	# Create a mock for get_outcontent that returns a broken object
	mock_get_outcontent <- mockery::mock(broken_outcontent)

	# Stub get_outcontent inside sparql2list
	mockery::stub(sparql2list, "get_outcontent", mock_get_outcontent)

	expect_error(
		sparql2list("http://example.org", "SELECT * WHERE {?s ?p ?o}"),
		regexp = "There is something wrong with the retrieved data: not_a_list"
	)
})


test_that("return is of correct type", {
	skip_on_cran()  # if network access is needed
	skip_if_not_installed("httr")
	skip_if_not_installed("curl")
	skip_if_not_installed("knitr")
	skip_if_not_installed("magrittr")
	skip_if_not_installed("xml2")
	endpoint <- "https://lindas.admin.ch/query"
	query <- "PREFIX schema: <http://schema.org/>
	   SELECT * WHERE {
	   ?sub a schema:DataCatalog .
     ?subtype a schema:DataType .
	}"
	acceptype <- "text/xml"
	proxy_config <- httr::use_proxy(url = NULL)
	expect_type(get_outcontent(endpoint, query, acceptype, proxy_config), "list")
})


test_that("Windows fallback is used when httr::GET fails", {
	# Mock platform as Windows
	stub(get_outcontent, "is_windows", function() TRUE)
	# Force httr::GET to throw an error
	stub(get_outcontent, "httr::GET", function(...) stop("Simulated GET failure"))
	# Stub download.file and related functions
	stub(get_outcontent, "utils::download.file", function(...) invisible(NULL))
	stub(get_outcontent, "readLines", function(...) "mock response")
	stub(get_outcontent, "unlink", function(...) invisible(NULL))
	result <- get_outcontent(
		endpoint = "http://example.org/sparql",
		query = "SELECT * WHERE {?s ?p ?o}",
		acceptype = "application/sparql-results+json",
		proxy_config = NULL
	)
	expect_equal(result$content, "mock response")
})
