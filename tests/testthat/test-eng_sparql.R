library(testthat)
library(mockery)

query <- "PREFIX schema: <http://schema.org/>
		SELECT * WHERE {
			?sub a schema:DataCatalog .
			?subtype a schema:DataType .
}"
endpoint1 <- "http://example.org/sparql"

options1 <- list(
	code = query,
	endpoint = endpoint1,
	autoproxy = TRUE,
	output.var = NULL,
	engine = "sparql",     # Required for knitr::engine_output
	label = "test_chunk",  # Required
	results = "markup"     # Optional but typical
)

test_that("Throws error when no endpoint is defined", {
	opt <- list(
		code = query,
		endpoint = NULL
	)
	mock_engine_output <- mock("engine output placeholder")
	stub(eng_sparql, "knitr::engine_output", mock_engine_output)
	expect_error(eng_sparql(opt), "No endpoint defined")
})



