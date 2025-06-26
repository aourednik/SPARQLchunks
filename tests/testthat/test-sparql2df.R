test_that("sparql2df returns a data.frame", {
	endpoint <- "https://lindas.admin.ch/query"
	query <- "PREFIX schema: <http://schema.org/>
	   SELECT * WHERE {
	   ?sub a schema:DataCatalog .
	   ?subtype a schema:DataType .
	}"
	result_df <- sparql2df(endpoint, query)
	expect_equal(class(result_df), "data.frame")
})


test_that("sparql2df returns a data.frame with setting autoproxy=TRUE", {
	endpoint <- "https://lindas.admin.ch/query"
	query <- "PREFIX schema: <http://schema.org/>
	   SELECT * WHERE {
	   ?sub a schema:DataCatalog .
	   ?subtype a schema:DataType .
	}"
	result_df <- sparql2df(endpoint, query,autoproxy = T)
	expect_equal(class(result_df), "data.frame")
})
