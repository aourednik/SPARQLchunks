test_that("return is of correct type", {
	endpoint <- "https://lindas.admin.ch/query"
	query <- "PREFIX schema: <http://schema.org/>
	   SELECT * WHERE {
	   ?sub a schema:DataCatalog .
     ?subtype a schema:DataType .
	}"
	acceptype <- "text/xml"
	proxy_config <- httr::use_proxy(url = NULL)
	expect_equal(class(get_outcontent(endpoint, query, acceptype, proxy_config)), "list")
})
