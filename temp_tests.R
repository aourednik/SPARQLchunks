authenticate <- httr::authenticate(user = Sys.getenv("SSZ_VIEWS_USER"),
																	 password = Sys.getenv("SSZ_VIEWS_PW"))


# This query runs without authentication
endpoint_a <- "https://lindas.admin.ch/query"
query_a <- "PREFIX schema: <http://schema.org/>
SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}"

result_a <- sparql2df(endpoint_a, query_a)
# result_a has 2 variables with 78 observations
result_a_auth <- sparql2df(endpoint_a, query_a, auth = authenticate)
# result_a_auth has 2 variables with 78 observations



# This query needs authentication
endpoint_b <- "https://stardog.cluster.ldbar.ch/ssz-views"
query_b <- "PREFIX cube: <https://cube.link/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?cube (COUNT(?observation) AS ?count)
FROM <https://lindas.admin.ch/stadtzuerich/stat>
WHERE {
  ?cube a cube:Cube ;
    cube:observationSet/cube:observation ?observation .
} GROUP BY ?cube ORDER BY ?count"

result_b <- sparql2df(endpoint_b, query_b)
# result_b does not exist (error 401)
result_b_auth <- sparql2df(endpoint_b, query_b, auth = authenticate)
# result_b_auth has 1 variable with 1363 obs.



# This query needs authentication as well
endpoint_c <- "https://stardog.cluster.ldbar.ch/ssz-views"
query_c <- "PREFIX schema: <http://schema.org/>
PREFIX view: <https://cube.link/view/>
SELECT * WHERE {
      ?resource a view:View ;
                schema:name ?name ;
                schema:alternateName ?alt .
}"

result_c <- sparql2df(endpoint_c, query_c)
# result_c does not exist (error 401)
result_c_auth <- sparql2df(endpoint_c, query_c, auth = authenticate)
# result_c_auth has 1 variable with 1489 obs.
