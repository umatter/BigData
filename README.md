# Big Data Analytics


This repository contains the source of the [Big Data Analytics book](https://umatter.github.io/BigData/), as well as  supplementary online resources. The book is built using [bookdown](https://github.com/rstudio/bookdown).

## Supplementary online resources

### R code examples

The [R_code_examples](/R_code_examples) folder contains R-scripts with all code examples and tutorials shown in the book. 

### Data

The corresponding sections in the book contain typically contain detailed instructions of where and how the datasets used in the code examples can be downloaded from the original sources.

To ensure data availability for the code examples and tutorials in the long run, you find (smaller scale) versions for all key datasets discussed in the book in this S3-bucket: 

https://bda-examples.s3.eu-central-1.amazonaws.com/air_final.sqlite

https://bda-examples.s3.eu-central-1.amazonaws.com/airline_id.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/airports.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/carriers.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/data_for_tables.dta

https://bda-examples.s3.eu-central-1.amazonaws.com/economics.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/flights_sep_oct15.txt

https://bda-examples.s3.eu-central-1.amazonaws.com/flights.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/ga.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/inflation.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/marketing_data.csv

https://bda-examples.s3.eu-central-1.amazonaws.com/mydb.sqlite

https://bda-examples.s3.eu-central-1.amazonaws.com/tlc_trips.csv

Note that the AWS bucket is configured such that the [requester pays](https://docs.aws.amazon.com/AmazonS3/latest/userguide/RequesterPaysBuckets.html?icmpid=docs_amazons3_console) for requests and transfer costs.


### Installation of dependencies and packages

Here you find additional resources and hints regarding the installation of some of the tools used in the book.

 - `gpuR`: The package is not anymore available via `install.packages()`. However, you can install it with `devtools::install_github("cdeterman/gpuR")`. For additional installation instructions (in particular regarding dependencies), see the wiki here: https://github.com/cdeterman/gpuR/wiki.
 - Install Apache Spark via `sparklyr`: https://spark.rstudio.com/get-started/
 - Install Tensorflow and Keras via the `tensorflow` and `keras` packages (from within R): https://tensorflow.rstudio.com/install/
 
 
