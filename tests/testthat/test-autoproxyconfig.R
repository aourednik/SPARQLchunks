test_that("multiplication works", {
	endpoint <- "https://lindas.admin.ch/query"
	expect_equal(class(autoproxyconfig(endpoint)), "request")
})
