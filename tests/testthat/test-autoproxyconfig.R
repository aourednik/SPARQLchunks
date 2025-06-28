library(testthat)
library(mockery)

endpoint <- "https://lindas.admin.ch/query"

test_that("Proxy is infered from endpoint URL", {
	expect_s3_class(autoproxyconfig(endpoint), "request")
})

