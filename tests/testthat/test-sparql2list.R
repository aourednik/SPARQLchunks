test_that("sparq2list returns a list", {
	endpoint <- "https://lindas.admin.ch/query"
	query <- "PREFIX schema: <http://schema.org/>
	 SELECT * WHERE {
	 ?sub a schema:DataCatalog .
	 ?subtype a schema:DataType .
	}"
	result_list <- sparql2list(endpoint, query)
	expect_equal(class(result_list), "list")
})
