library(DBI)

source('local_config.r')

con <- dbConnect(RPostgres::Postgres(),dbname = 'postgres',

                 host = myserver, # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'

                 port = 5432, # or any other port specified by your DBA

                 user = myuser,

                 password = mypassword)

dbListTables(con)
dbGetQuery(con,'SELECT * FROM patients limit 10')

