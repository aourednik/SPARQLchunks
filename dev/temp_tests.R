authenticate <- httr::authenticate(user = Sys.getenv("SSZ_VIEWS_USER"),
																	 password = Sys.getenv("SSZ_VIEWS_PW"))



# 1) endpoints and queries -------------------

# A) This query runs without authentication
endpoint_a <- "https://lindas.admin.ch/query"
query_a <- "PREFIX schema: <http://schema.org/>
SELECT * WHERE {
  ?sub a schema:DataCatalog .
  ?subtype a schema:DataType .
}"

# B) This query needs authentication
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


# C) This query needs authentication as well
endpoint_c <- "https://stardog.cluster.ldbar.ch/ssz-views"
query_c <- "PREFIX schema: <http://schema.org/>
PREFIX view: <https://cube.link/view/>
SELECT * WHERE {
      ?resource a view:View ;
                schema:name ?name ;
                schema:alternateName ?alt .
}"



# 2) test sparql2df --------------------------

result_a_df <- sparql2df(endpoint_a, query_a)
# result_a_df has 2 variables with 78 observations
result_a_df_auth <- sparql2df(endpoint_a, query_a, auth = authenticate)
# result_a_df_auth has 2 variables with 78 observations


result_b_df <- sparql2df(endpoint_b, query_b)
# result_b_df does not exist (error 401)
result_b_df_auth <- sparql2df(endpoint_b, query_b, auth = authenticate)
# result_b_auth has 1 variable with 2249 obs.


result_c_df <- sparql2df(endpoint_c, query_c)
# result_c does not exist (error 401)
result_c_df_auth <- sparql2df(endpoint_c, query_c, auth = authenticate)
# result_c_auth has 1 variable with 2249 obs.






# 3) test sparql2list -------------------------

result_a_list <- sparql2list(endpoint_a, query_a)
# result_a_list is a list of 1, sparql>results is a list of 78
result_a_df_auth <- sparql2df(endpoint_a, query_a, auth = authenticate)
# result_a_list_auth is a list of 1, sparql>results is a list of 78


result_b_list <- sparql2list(endpoint_b, query_b)
# result_b_list does not exist (error 401)
result_b_list_auth <- sparql2list(endpoint_b, query_b, auth = authenticate)
# this results in the following error:

# Fehler in read_xml.raw(charToRaw(enc2utf8(x)), "UTF-8", ..., as_html = as_html,  :
# Start tag expected, '<' not found [4]'


result_c_list <- sparql2list(endpoint_c, query_c)
# result_c does not exist (error 401)
result_c_list_auth <- sparql2list(endpoint_c, query_c, auth = authenticate)
# this results in the following error:

# Fehler in read_xml.raw(charToRaw(enc2utf8(x)), "UTF-8", ..., as_html = as_html,  :
# Start tag expected, '<' not found [4]'




# 4) test eng_sparql -----------------------------------

opt_a <- list(code = query_a, endpoint = endpoint_a)
neu <- eng_sparql(opt_a)

# throws an error, but this function seems to de designed for rmd files


