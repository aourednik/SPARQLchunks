library(testthat)
skip_on_cran()  # network access is needed for this package to work
skip_if_not_installed("httr")
skip_if_not_installed("curl")
skip_if_not_installed("knitr")
skip_if_not_installed("xml2")
library(mockery)

query <- "PREFIX up: <http://purl.uniprot.org/core/>
SELECT ?taxon
FROM <http://sparql.uniprot.org/taxonomy>
WHERE {
	?taxon a up:Taxon .
} LIMIT 500"
endpoint1 <- "https://sparql.uniprot.org/sparql"

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



