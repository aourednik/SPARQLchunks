
# SPARQLchunks

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

Coding in R is useless without interesting research questions; and even the best questions remain unanswered without data. RStudio provides a number of convenient ways to access data, among which the possibility to write SQL code chunks in Rmarkdown, to run these chunks and to assign the value of the query result directly to a variable of your choice. No such thing is available yet for SPARQL queries: the ones that allow you to navigate gigantic knowledge graphs that incarnate the conscience of the semantic web. This is where the SPARQLchunks package steps in. 

This package allows you to query SPARQL endpoints in two different ways: 

1. It allows you to run SPARQL chunks in Rmarkdown files. 
2. It provides inline functions to send SPARQL queries to a user-defined endpoint and retrieve data in _dataframe_ form (`sparql2df`) or _list_ form (`sparql2list`). 

Endpoints can be reached from behind corporate firewalls on Windows machines thanks to automatic proxy detection. See [Execute SPARQL chunks in R Markdown](https://ourednik.info/maps/2021/12/14/execute-sparql-chunks-in-r-markdown/).

## Installation

Most users can install by running this command 

```r
remotes::install_github("aourednik/SPARQLchunks", build_vignettes = TRUE)
```

If you are behind a corporate firewall on a Windows machine, direct access to GitHub might be blocked. If that is your case, run this installation code instead:

```r
proxy_url <- curl::ie_get_proxy_for_url("https://github.com")
httr::set_config(httr::use_proxy(proxy_url))
remotes::install_url("https://github.com/aourednik/SPARQLchunks/archive/refs/heads/master.zip", build_vignettes = TRUE)
```

## Use

To use the full potential of the package you need to load the library and _tell knitr that a SPARQL engine exists_: 

```{r setup, include=FALSE}
library(SPARQLchunks)
knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)
```

Once you have done so, you can run SPARQL chunks:

### Chunks

#### Retrieve a data frame

_output.var_: the name of the data frame you want to store the results in

_endpoint_: the URL of the SPARQL endpoint

_autoproxy_: whether or not try to use the automatic proxy detection

_auth_: authentication information for the sparql endpoint (as an httr authentication object, optional)

Example 1 (Swiss administration endpoint)

````markdown
```{sparql output.var="queryres_df", endpoint="https://lindas.admin.ch/query"}
PREFIX schema: <http://schema.org/>
SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}
```
````

Example 2 (Uniprot endpoint)

Note the use of attempt at automatic proxy detection. 

````markdown
```{sparql output.var="tes5", endpoint="https://sparql.uniprot.org/sparql", autoproxy=TRUE}
PREFIX up: <http://purl.uniprot.org/core/>
SELECT ?taxon
FROM <http://sparql.uniprot.org/taxonomy>
WHERE {
	?taxon a up:Taxon .
} LIMIT 500
```
````

Example 3 (WikiData endpoint):

````markdown
```{sparql output.var="res.df", endpoint="https://query.wikidata.org/sparql"}
SELECT DISTINCT ?item ?itemLabel ?country ?countryLabel ?linkTo ?linkToLabel
WHERE {
    ?item wdt:P1142 ?linkTo .
    ?linkTo wdt:P31 wd:Q12909644 .
    VALUES ?type { wd:Q7278  wd:Q24649 }
    ?item wdt:P31 ?type .
    ?item wdt:P17 ?country .
    MINUS { ?item wdt:P576 ?abolitionDate }
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en" . }
}
```
````


####  Retrieve a list

_output.var_: the name of the list you want to store the results in

_endpoint_: the URL of the SPARQL endpoint

_output.type_ : when set to "list", retrieves a list (tree structure) instead of a data-frame 

_autoproxy_: whether or not try to use the automatic proxy detection

````markdown
```{sparql output.var="queryres_list", endpoint="https://lindas.admin.ch/query", output.type="list"}
PREFIX schema: <http://schema.org/>
SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}
```
````

### Inline code

The inline functions `sparql2df` and `sparql2list` both have the same pair of arguments: a _SPARQL endpoint_ and a _SPARQL query_. Queries can be multi-line:

```r
endpoint <- "https://lindas.admin.ch/query"
query <- "PREFIX schema: <http://schema.org/>
  SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}"
```

#### Retrieve a data frame

```r
result_df <- sparql2df(endpoint,query)
```

The same but with attempt at automatic proxy detection:

```r
result_df <- sparql2df(endpoint,query,autoproxy=TRUE)
```

#### Retrieve a list

```r
result_list <- sparql2list(endpoint,query)
```

The same but with attempt at automatic proxy detection:

```r
result_list <- sparql2list(endpoint,query,autoproxy=TRUE)
```
