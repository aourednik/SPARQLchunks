
# SPARQLchunks

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->


Knowing how to code R is useless if you don't have interesting research questions; and even the best questions remain unanswered without data. RStudio provides a number of convenient ways to access data, among which the possibility to write SQL code chunks in Rmarkdown, to run these chunks and to assign the value of the query result directly to a variable of your choice. No such thing is available yet for SPARQL queries. A shame, if we consider that SPARQL alows you to navigate gigantic knowledge graphs that incarnate the conscience of the semantic web. This is where my SPARQLchunks package comes in. 

This package allows you to query SPARQL endpoints in two different ways: 

1. It allows you to run SPARQL chunks in Rmarkdown files. 
2. It provides inline functions to send a SPARQL queries to a user-defined endpoint and retrieve data in _dataframe_ form (`sparql2df`) or _list_ form (`sparql2list`). 

Endpoints can be reached from behind corporate firewalls thanks to automatic proxy detection. See [Execute SPARQL chunks in R Markdown](https://ourednik.info/maps/2021/12/14/execute-sparql-chunks-in-r-markdown/).

## Installation

```{r, eval = FALSE}
remotes::install_github("aourednik/SPARQLchunks")
```

## Use

To use the full potential of the package you need to load the library and _tell knitr that a SPARQL engine exists_: 

```{r setup, eval=FALSE}
library(SPARQLchunks)
knitr::knit_engines$set(sparql = SPARQLchunks::eng_sparql)
```

Once you have done so, you can run SPARQL chunks:

### Chunks

#### Retrieve a dataframe

_output.var_: the name of the data.frame you want to store the results in

_endpoint_: the URL of the SPARQL endpoint


````markdown
```{sparql output.var="queryres_csv", endpoint="https://lindas.admin.ch/query"}
PREFIX schema: <http://schema.org/>
SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}
```
````

####  Retrieve a list

_output.var_: the name of the data.frame you want to store the results in

_endpoint_: the URL of the SPARQL endpoint

_output.type_ : if set to "list", retrieves a list (tree structure) instead of a data-frame 

````markdown
```{sparql output.var="queryres_csv", endpoint="https://lindas.admin.ch/query"}
PREFIX schema: <http://schema.org/>
SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}
```
````

### Inline code

In all cases, you need to define an endpoint and prepare a SPQRQL query. Queries can be multi-line:

```r
endpoint <- "https://lindas.admin.ch/query"
query <- "PREFIX schema: <http://schema.org/>
  SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}"
```


#### Retrieve a list

```r
result_df <- sparql2df(endpoint,query)
```


#### Retrieve a data.frame

```r
result_list <- sparql2list(endpoint,query)
```
