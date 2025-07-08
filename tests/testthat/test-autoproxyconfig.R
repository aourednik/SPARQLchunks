library(testthat)
skip_on_cran()  # network access is needed for this package to work
skip_if_not_installed("httr")
skip_if_not_installed("curl")
skip_if_not_installed("knitr")
skip_if_not_installed("xml2")
library(mockery)

endpoint <- "https://lindas.admin.ch/query"

test_that("Proxy is infered from endpoint URL", {
	expect_s3_class(autoproxyconfig(endpoint), "request")
})

