# This query runs without authentication
endpoint_a <- "https://lindas.admin.ch/query"
query_a <- "PREFIX schema: <http://schema.org/>
SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}"

result_a <- sparql2df(endpoint_a, query_a)
# result_a has 2 variables with 78 observations

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
