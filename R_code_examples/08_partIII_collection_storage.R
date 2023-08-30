


# Fetch all TLC trip records
# Data source:
# https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page
# Input: Monthly Parquet files from urls

# SET UP -----------------

# packages
library(R.utils) # to create directories from within R

# fix vars
BASE_URL <- "https://d37ci6vzurychx.cloudfront.net/trip-data/"
FILE <- "yellow_tripdata_2018-01.parquet"
URL <- paste0(BASE_URL, FILE)
OUTPUT_PATH <- "data/tlc_trips/"
START_DATE <- as.Date("2009-01-01")
END_DATE <- as.Date("2018-06-01")


# BUILD URLS -----------

# parse base url
base_url <- gsub("2018-01.parquet", "", URL)
# build urls
dates <- seq(from= START_DATE,
                   to = END_DATE,
                   by = "month")
year_months <- gsub("-01$", "", as.character(dates))
data_urls <- paste0(base_url, year_months, ".parquet")
data_paths <- paste0(OUTPUT_PATH, year_months, ".parquet")

# FETCH AND STACK CSVS ----------------

mkdirs(OUTPUT_PATH)
# download all csvs in the data range
for (i in 1:length(data_urls)) {

     # download to disk
     download.file(data_urls[i], data_paths[i])
}



# install arrow
Sys.setenv(LIBARROW_MINIMAL = "false") # to enable working with compressed files
install.packages("arrow") # might take a while



# SET UP ---------------------------

# load packages
library(arrow)
library(data.table)
library(purrr)

# fix vars
INPUT_PATH <- "data/tlc_trips/"
OUTPUT_FILE <- "data/tlc_trips.parquet"
OUTPUT_FILE_CSV <- "data/tlc_trips.csv"

# list of paths to downloaded Parquet files
all_files <- list.files(INPUT_PATH, full.names = TRUE)

# LOAD, COMBINE, STORE ----------------------

# read Parquet files
all_data <- lapply(all_files, read_parquet, as_data_frame = FALSE)

# combine all arrow tables into one
combined_data <- lift_dl(concat_tables)(all_data)

# write combined dataset to csv file
write_csv_arrow(combined_data,
                file = OUTPUT_FILE_CSV, 
                include_header = TRUE)



# SET UP -----------------

# fix variables
DATA_PATH <- "data/flights.csv"
# load packages
library(pryr) 
# check how much memory is used by R (overall)
mem_used()

# DATA IMPORT ----------------
# check the change in memory due to each step
# and stop the time needed for the import
system.time(flights <- read.csv(DATA_PATH))
mem_used()

# DATA PREPARATION --------
flights <- flights[,-1:-3]
# check how much memory is used by R now
mem_used()

gc()

# load packages
library(data.table)

# DATA IMPORT ----------------
system.time(flights <- fread(DATA_PATH, verbose = TRUE))


# load packages
library(data.table)

# DATA IMPORT ----------------
system.time(flights <- fread(DATA_PATH, verbose = FALSE))


















flights_join





doublejoin_example

# load packages
library(RSQLite)

# initialize the database
con_air <- dbConnect(SQLite(), "data/air.sqlite")


# import data into current R session
flights <- fread("data/flights.csv")
airports <- fread("data/airports.csv")
carriers <- fread("data/carriers.csv")

# add tables to database
dbWriteTable(con_air, "flights", flights)
dbWriteTable(con_air, "airports", airports)
dbWriteTable(con_air, "carriers", carriers)


# define query
delay_query <-
"SELECT
year,
month,
day,
dep_delay,
flight
FROM (flights INNER JOIN airports ON flights.origin=airports.iata)
INNER JOIN carriers ON flights.carrier = carriers.Code
WHERE carriers.Description = 'United Air Lines Inc.'
AND airports.airport = 'Newark Intl'
ORDER BY flight
LIMIT 10;
"

# issue query
delays_df <- dbGetQuery(con_air, delay_query)
delays_df

# clean up
dbDisconnect(con_air)


# clean up
unlink("data/air.sqlite")







# load packages
library(RMySQL)

# fix vars
RDS_ENDPOINT <- readLines("_keys/aws_rds.txt")[1]
PW <- readLines("_keys/aws_rds.txt")[2]

# connect to DB
con_rds <- dbConnect(RMySQL::MySQL(),
                 host=RDS_ENDPOINT,
                 port=3306,
                 username="admin",
                 password=PW)

# create a new database on the MySQL RDS instance
dbSendQuery(con_rds, "CREATE DATABASE IF NOT EXISTS air")

# disconnect and re-connect directly to the new DB
dbDisconnect(con_rds)
con_rds <- dbConnect(RMySQL::MySQL(),
                 host=RDS_ENDPOINT,
                 port=3306,
                 username="admin",
                 dbname="air",
                 password=PW)


# load packages
library(RMySQL)
library(data.table)

# fix vars
# replace this with the Endpoint shown in the AWS RDS console
RDS_ENDPOINT <- "MY-ENDPOINT"
# replace this with the password you have set when initiating the RDS DB on AWS
PW <- "MY-PW"

# connect to DB
con_rds <- dbConnect(RMySQL::MySQL(),
                 host=RDS_ENDPOINT,
                 port=3306,
                 username="admin",
                 password=PW)

# create a new database on the MySQL RDS instance
dbSendQuery(con_rds, "CREATE DATABASE air")

# disconnect and re-connect directly to the new DB
dbDisconnect(con_rds)
con_rds <- dbConnect(RMySQL::MySQL(),
                 host=RDS_ENDPOINT,
                 port=3306,
                 username="admin",
                 dbname="air",
                 password=PW)

# import data into current R session
flights <- fread("data/flights.csv")
airports <- fread("data/airports.csv")
carriers <- fread("data/carriers.csv")

# add tables to database
dbWriteTable(con_rds, "flights", flights)
dbWriteTable(con_rds, "airports", airports)
dbWriteTable(con_rds, "carriers", carriers)

# define query
delay_query <-
"SELECT
year,
month,
day,
dep_delay,
flight
FROM (flights INNER JOIN airports ON flights.origin=airports.iata)
INNER JOIN carriers ON flights.carrier = carriers.Code
WHERE carriers.Description = 'United Air Lines Inc.'
AND airports.airport = 'Newark Intl'
ORDER BY flight
LIMIT 10;
"

# issue query
delays_df <- dbGetQuery(con_rds, delay_query)
delays_df

# clean up
dbDisconnect(con_rds)


# download druid binary

# (replace 25.0.0 with another version number to download another version)

wget https://dlcdn.apache.org/druid/25.0.0/apache-druid-25.0.0-bin.tar.gz

# unpack

tar -xzf apache-druid-25.0.0-bin.tar.gz

# clean up

rm apache-druid-25.0.0-bin.tar.gz




# navigate to local copy of druid

cd apache-druid-25.0.0

# start up druid (basic/minimal settings)

./bin/start-micro-quickstart












# install devtools if necessary
if (!require("devtools")) {
     install.packages("devtools")}

# install RDruid
devtools::install_github("druid-io/RDruid")

# create R function to query Druid (locally)
druid <- 
     function(query){
          # dependencies
          require(jsonlite)
          require(httr)
          require(data.table)
          
          # basic POST body
          base_query <-  
          '{
          "context": {
          "sqlOuterLimit": 1001,
          "sqlQueryId": "1"},
          "header": true,
          "query": "",
          "resultFormat": "csv",
          "sqlTypesHeader": false,
          "typesHeader": false
          }'
          param_list <- fromJSON(base_query)
          # add SQL query
          param_list$query <- query
          
          # send query; parse result
          resp <- POST("http://localhost:8888/druid/v2/sql", 
                       body = param_list, 
                       encode = "json")
          parsed <- fread(content(resp, as = "text", encoding = "UTF-8"))
          return(parsed)
     }


# start Druid
system("apache-druid-25.0.0/bin/start-micro-quickstart",
       intern = FALSE, 
       wait = FALSE)
Sys.sleep(30) # wait for Druid to start up

# query tlc data
query <-
'
SELECT
vendor_name,
Payment_Type,
COUNT(*) AS Count_trips
FROM tlc_trips
GROUP BY vendor_name, Payment_Type
' 
result <- druid(query)

# inspect result
result


# documents raw data processing

# load packages, credentials
library(bigrquery)
library(data.table)
library(DBI)

# fix vars
# the project ID on BigQuery (billing must be enabled):
BILLING <- "bda-examples"
# the project name on BigQuery:
PROJECT <- "bigquery-public-data"
DATASET <- "google_analytics_sample"

# connect to DB on BigQuery
con <- dbConnect(
     bigrquery::bigquery(),
     project = PROJECT,
     dataset = DATASET,
     billing = BILLING
)


# load packages, credentials
library(bigrquery)
library(data.table)
library(DBI)

# fix vars
# the project ID on BigQuery (billing must be enabled)
BILLING <- "bda-examples"
# the project name on BigQuery
PROJECT <- "bigquery-public-data"
DATASET <- "google_analytics_sample"

# connect to DB on BigQuery
con <- dbConnect(
     bigrquery::bigquery(),
     project = PROJECT,
     dataset = DATASET,
     billing = BILLING
)


# run query
query <-
"
SELECT DISTINCT trafficSource.source AS origin,
COUNT(trafficSource.source) AS no_occ
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`
GROUP BY trafficSource.source
ORDER BY no_occ DESC;
"
ga <- as.data.table(dbGetQuery(con, query, page_size=15000))
head(ga)

# name of the dataset to be created
DATASET <- "tlc"

# connect and initialize a new dataset
con <- dbConnect(
     bigrquery::bigquery(),
     project = BILLING,
     billing = BILLING,
     dataset = DATASET
)

tlc_ds <- bq_dataset(BILLING, DATASET)

if (bq_dataset_exists(tlc_ds)){
     bq_dataset_delete(tlc_ds)
}

tlc_ds <- bq_dataset(BILLING, DATASET)
bq_dataset_create(tlc_ds)

# read data from csv
tlc <- fread("data/tlc_trips.csv.gz", nrows = 10000)
# write data to a new table
dbWriteTable(con, name = "tlc_trips", value = tlc)


test_query <-
"
SELECT *
FROM tlc.tlc_trips
LIMIT 10
"
test <- dbGetQuery(con, test_query)

# fix vars
# the project ID on BigQuery (billing must be enabled)
BILLING <- "YOUR-BILLING-PROJECT-ID"
# the project name on BigQuery
PROJECT <- "bigquery-public-data"
DATASET <- "google_analytics_sample"

# connect to DB on BigQuery
con <- dbConnect(
     bigrquery::bigquery(),
     project = PROJECT,
     dataset = DATASET,
     billing = BILLING
)



# run query
query <-
"
SELECT
totals.visits,
totals.transactions,
trafficSource.source,
device.browser,
device.isMobile,
geoNetwork.city,
geoNetwork.country,
channelGrouping
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160101' AND '20171231';
"
ga <- as.data.table(dbGetQuery(con, query, page_size=15000))



# further cleaning and coding via data.table and basic R
ga$transactions[is.na(ga$transactions)] <- 0
ga <- ga[ga$city!="not available in demo dataset",]
ga$purchase <- as.integer(0<ga$transactions)
ga$transactions <- NULL
ga_p <- ga[purchase==1]
ga_rest <- ga[purchase==0][sample(1:nrow(ga[purchase==0]), 45000)]
ga <- rbindlist(list(ga_p, ga_rest))
potential_sources <- table(ga$source)
potential_sources <- names(potential_sources[1<potential_sources])
ga <- ga[ga$source %in% potential_sources,]

# store dataset on local hard disk
fwrite(ga, file="data/ga.csv")

# clean up
dbDisconnect(con)



# load packages
library(aws.s3)

# set environment variables with your AWS S3 credentials
Sys.setenv("AWS_ACCESS_KEY_ID" = AWS_ACCESS_KEY_ID,
           "AWS_SECRET_ACCESS_KEY" = AWS_SECRET_KEY,
           "AWS_DEFAULT_REGION" = REGION)


# fix variable for bucket name
BUCKET <- "tlc-trips"
# create project bucket
put_bucket(BUCKET)
# create folders
put_folder("raw_data", BUCKET)
put_folder("analytic_data", BUCKET)


# upload to bucket
# final analytic dataset
put_object(
  file = "data/tlc_trips.csv", # the file you want to upload
  object = "analytic_data/tlc_trips.csv", # name of the file in the bucket
  bucket = BUCKET,
  multipart = TRUE
)

# upload raw data
file_paths <- list.files("data/tlc_trips/raw_data", full.names = TRUE)
lapply(file_paths,
       put_object,
       bucket=BUCKET,
       multipart=TRUE)



# load packages
library(DBI)
library(aws.s3)

# credentials and region
AWS_ACCESS_KEY_ID <- read.csv("_keys/bda_book_accessKeys.csv")[,1]
AWS_ACCESS_KEY <- read.csv("_keys/bda_book_accessKeys.csv")[,2]
REGION <- "eu-central-1"


# SET UP -------------------------

# load packages
library(DBI)
library(aws.s3)
# aws credentials with Athena and S3 rights and region
AWS_ACCESS_KEY_ID <- "YOUR_KEY_ID"
AWS_ACCESS_KEY <- "YOUR_KEY"
REGION <- "eu-central-1"


# establish AWS connection
Sys.setenv("AWS_ACCESS_KEY_ID" = AWS_ACCESS_KEY_ID,
           "AWS_SECRET_ACCESS_KEY" = AWS_ACCESS_KEY,
           "AWS_DEFAULT_REGION" = REGION)

OUTPUT_BUCKET <- "bda-athena"
put_bucket(OUTPUT_BUCKET, region="us-east-1")


# load packages
library(RJDBC)
library(DBI)

# download Athena JDBC driver
URL <- "https://s3.amazonaws.com/athena-downloads/drivers/JDBC/"
VERSION <- "AthenaJDBC_1.1.0/AthenaJDBC41-1.1.0.jar"
DRV_FILE <- "AthenaJDBC41-1.1.0.jar"
download.file(paste0(URL,VERSION), destfile = DRV_FILE)

# connect to JDBC
athena <- JDBC(driverClass="com.amazonaws.athena.jdbc.AthenaDriver", 
            DRV_FILE, 
            identifier.quote="'")
# connect to Athena
con <- dbConnect(athena, 
                 'jdbc:awsathena://athena.us-east-1.amazonaws.com:443/',
                 s3_staging_dir="s3://bda-athena",
                 user=AWS_ACCESS_KEY_ID,
                 password=AWS_ACCESS_KEY)


query_create_table <-
"
CREATE EXTERNAL TABLE default.trips (
  `vendor_name` string,
  `Trip_Pickup_DateTime` string,
  `Trip_Dropoff_DateTime` string,
  `Passenger_Count` int,
  `Trip_Distance` double,
  `Start_Lon` double,
  `Start_Lat` double,
  `Rate_Code` string,
  `store_and_forward` string,
  `End_Lon` double,
  `End_Lat` double,
  `Payment_Type` string,
  `Fare_Amt` double,
  `surcharge` double,
  `mta_tax` string,
  `Tip_Amt` double,
  `Tolls_Amt` double,
  `Total_Amt` double
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://tlc-trips/analytic_data/'
"
dbSendQuery(con, query_create_table)

test_query <-
"
SELECT * 
FROM default.trips
LIMIT 10
"
test <- dbGetQuery(con, test_query)
dim(test)

dbDisconnect(con)

# note: the order of detaching matters 
# due to dependencies between the packages
try(detach("package:aws.s3", unload=TRUE, force = TRUE))
# try(detach("package:RJDBC", unload=TRUE, force = TRUE))
# try(detach("package:RSQLite", unload=TRUE, force = TRUE))
# try(detach("package:DBI", unload=TRUE, force = TRUE))
# try(detach("package:pryr", unload=TRUE, force = TRUE))
# try(detach("package:data.table", unload=TRUE, force = TRUE))
# try(detach("package:purrr", unload=TRUE, force = TRUE))
# try(detach("package:bit", unload=TRUE, force = TRUE))
# 




# remove all packages
# packages <- names(sessionInfo()$otherPkgs)
# packages <- packages[!packages %in% c("bookdown", "knitr", "rmarkdown")]
# lapply(packages, function(pkgs)
#   detach(
#     paste0('package:', pkgs),
#     character.only = T,
#     unload = T,
#     force = T
#   ))

# close all connections
# DIZtools::close_all_connections()

# remove objects
#rm(list = ls())
#gc()
