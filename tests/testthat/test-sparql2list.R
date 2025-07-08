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

test_that("sparq2list returns a list", {
	result_list <- sparql2list(endpoint, query)
	expect_type(result_list, "list") # a basic list in R is not an S3 object — it's a base type.
})
