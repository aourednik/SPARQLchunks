library(testthat)
skip_on_cran()  # network access is needed for this package to work
skip_if_not_installed("httr")
skip_if_not_installed("curl")
skip_if_not_installed("knitr")
skip_if_not_installed("xml2")
library(mockery)

endpoint <- "https://sparql.uniprot.org/sparql"
query <- "PREFIX up: <http://purl.uniprot.org/core/>
SELECT ?taxon
FROM <http://sparql.uniprot.org/taxonomy>
WHERE {
	?taxon a up:Taxon .
} LIMIT 500"

test_that("Calls sparql2list and assings a list to output.var when output.type = 'list'", {
	opts <- list(
		code = query,
		endpoint = endpoint,
		output.type = "list",
		output.var = "result_list",
		engine = "sparql",
		echo = F,
		label = "test",
		results = "markup" # required to avoid 'missing value' error
	)
	eng_sparql(opts)
	expect_type(result_list,"list")
})

test_that("Calls sparql2df and assings a data.frame to output.var when output.type = 'dataframe'", {
	opts <- list(
		code = query,
		endpoint = endpoint,
		output.type = "dataframe",
		output.var = "result_df",
		engine = "sparql",
		echo = F,
		label = "test",
		results = "markup"     # required to avoid 'missing value' error
	)
	eng_sparql(opts)
	expect_s3_class(result_df,"data.frame")
})

test_that("Automatically assigns output.type and output.var when not defined, but triggers sparql2df", {
	opts <- list(
		code = query,
		endpoint = endpoint,
		output.type = NULL,
		output.var = NULL,
		engine = "sparql",
		echo = F,
		label = "test",
		results = "markup"     # required to avoid 'missing value' error
	)
	eng_sparql(opts)
	expect_s3_class(result_df,"data.frame")
})


test_that("sparql2list throws error with sprintf when content access fails", {
	# Force get_outcontent to return a string instead of list
	broken_outcontent <- "not_a_list"

	# Create a mock for get_outcontent that returns a broken object
	mock_get_outcontent <- mockery::mock(broken_outcontent)

	# Stub get_outcontent inside sparql2list
	mockery::stub(sparql2list, "get_outcontent", mock_get_outcontent)

	expect_error(
		sparql2list("https://lindas.admin.ch/query", "SELECT * WHERE {?s ?p ?o}"),
		regexp = "There is something wrong with the retrieved data: not_a_list"
	)
})

test_that("return is of correct type", {
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
		endpoint = "https://lindas.admin.ch/query",
		query = "SELECT * WHERE {?s ?p ?o} LIMIT 10",
		acceptype = "application/sparql-results+json",
		proxy_config = NULL
	)
	expect_equal(result$content, "mock response")
})


test_that("fallback block is triggered when content is NULL", {
	# Mock httr::GET to return a response that leads to NULL content
	mock_get <- mock(list(status = 200), cycle = TRUE)
	mock_content <- mock(NULL, cycle = TRUE)  # Simulate NULL content

	stub(get_outcontent, "httr::GET", mock_get)
	stub(get_outcontent, "httr::content", mock_content)

	result <- get_outcontent(
		endpoint = "https://lindas.admin.ch/query",
		query = "SELECT * WHERE {?s ?p ?o} LIMIT 10",
		acceptype = "application/sparql-results+json",
		proxy_config = NULL
	)

	# Check that fallback content is returned (e.g., from download.file or NULL)
	expect_true("content" %in% names(result))
})




