## ----eval=FALSE----------------------------------------------------------
## #################################
## # Fetch all TLC trip recrods
## # Data source:
## # https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page
## # Input: Monthly csv files from urls
## # Output: one large csv file
## # UM, St. Gallen, January 2019
## #################################
## 
## # SET UP -----------------
## 
## # load packages
## library(data.table)
## library(rvest)
## library(httr)
## 
## # fix vars
## BASE_URL <- "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2018-01.csv"
## OUTPUT_PATH <- "../data/tlc_trips.csv"
## START_DATE <- as.Date("2009-01-01")
## END_DATE <- as.Date("2018-06-01")
## 
## 
## # BUILD URLS -----------
## 
## # parse base url
## base_url <- gsub("2018-01.csv", "", BASE_URL)
## # build urls
## dates <- seq(from= START_DATE,
##                    to = END_DATE,
##                    by = "month")
## year_months <- gsub("-01$", "", as.character(dates))
## data_urls <- paste0(base_url, year_months, ".csv")
## 
## # FETCH AND STACK CSVS ----------------
## 
## # download, parse all files, write them to one csv
## for (url in data_urls) {
## 
##      # download to temporary file
##      tmpfile <- tempfile()
##      download.file(url, destfile = tmpfile)
## 
##      # parse downloaded file, write to output csv, remove tempfile
##      csv_parsed <- fread(tmpfile)
##      fwrite(csv_parsed,
##             file =  OUTPUT_PATH,
##             append = TRUE)
##      unlink(tmpfile)
## 
## }
## 
## 

## ----message=FALSE-------------------------------------------------------
# load packages
library(ff)
library(ffbase)

# set up the ff directory (for data file chunks)
if (!dir.exists("fftaxi")){
     system("mkdir fftaxi")
}
options(fftempdir = "fftaxi")

# import a few lines of the data, setting the column classes explicitly
col_classes <- c(V1 = "factor",
                 V2 = "POSIXct",
                 V3 = "POSIXct",
                 V4 = "integer",
                 V5 = "numeric",
                 V6 = "numeric",
                 V7 = "numeric",
                 V8 = "numeric",
                 V9 = "numeric",
                 V10 = "numeric",
                 V11 = "numeric",
                 V12 = "factor",
                 V13 = "numeric",
                 V14 = "numeric",
                 V15 = "factor",
                 V16 = "numeric",
                 V17 = "numeric",
                 V18 = "numeric")

# import the first one million observations
taxi <- read.table.ffdf(file = "../data/tlc_trips.csv",
                        sep = ",",
                        header = TRUE,
                        next.rows = 100000,
                        colClasses= col_classes,
                        nrows = 1000000
                        )


## ------------------------------------------------------------------------
# first, we remove the empty vars V8 and V9
taxi$V8 <- NULL
taxi$V9 <- NULL


# set covariate names according to the data dictionary
# see https://www1.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf
# note instead of taxizonne ids, long/lat are provided

varnames <- c("vendor_id",
              "pickup_time",
              "dropoff_time",
              "passenger_count",
              "trip_distance",
              "start_lat",
              "start_long",
              "dest_lat",
              "dest_long",
              "payment_type",
              "fare_amount",
              "extra",
              "mta_tax",
              "tip_amount",
              "tolls_amount",
              "total_amount")
names(taxi) <- varnames


     

## ------------------------------------------------------------------------
# inspect the factor levels
levels(taxi$payment_type)
# recode them
levels(taxi$payment_type) <- tolower(levels(taxi$payment_type))
taxi$payment_type <- ff(taxi$payment_type,
                        levels = unique(levels(taxi$payment_type)),
                        ramclass = "factor")
# check result
levels(taxi$payment_type)


## ------------------------------------------------------------------------

# load packages
library(doBy)

# split-apply-combine procedure on data file chunks
tip_pcategory <- ffdfdply(taxi,
                          split = taxi$payment_type,
                          BATCHBYTES = 100000000,
                          FUN = function(x) {
                               summaryBy(tip_amount~payment_type,
                                         data = x,
                                         FUN = mean,
                                         na.rm = TRUE)})

## ------------------------------------------------------------------------
as.data.frame(tip_pcategory)

## ------------------------------------------------------------------------
# add additional column with the share of tip
taxi$percent_tip <- (taxi$tip_amount/taxi$total_amount)*100

# recompute the aggregate stats
tip_pcategory <- ffdfdply(taxi,
                          split = taxi$payment_type,
                          BATCHBYTES = 100000000,
                          FUN = function(x) {
                               summaryBy(percent_tip~payment_type, # note the difference here
                                         data = x,
                                         FUN = mean,
                                         na.rm = TRUE)})
# show result as data frame
as.data.frame(tip_pcategory)

## ------------------------------------------------------------------------
table.ff(taxi$payment_type)

## ------------------------------------------------------------------------
# select the subset of observations only containing trips paid by credit card or cash
taxi_sub <- subset.ffdf(taxi, payment_type=="credit" | payment_type == "cash")
taxi_sub$payment_type <- ff(taxi_sub$payment_type,
                        levels = c("credit", "cash"),
                        ramclass = "factor")

# compute the cross tabulation
crosstab <- table.ff(taxi_sub$passenger_count,
                     taxi_sub$payment_type
                     )
# add names to the margins
names(dimnames(crosstab)) <- c("Passenger count", "Payment type")
# show result
crosstab

## ------------------------------------------------------------------------
# install.packages(vcd)
# load package for mosaic plot
library(vcd)

# generate a mosaic plot
mosaic(crosstab, shade = TRUE)

## ----warning=FALSE, message=FALSE----------------------------------------
# load packages
library(data.table)

# import data into RAM (needs around 200MB)
taxi <- fread("../data/tlc_trips.csv",
              nrows = 1000000)


## ------------------------------------------------------------------------
# first, we remove the empty vars V8 and V9
taxi$V8 <- NULL
taxi$V9 <- NULL


# set covariate names according to the data dictionary
# see https://www1.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf
# note instead of taxizonne ids, long/lat are provided

varnames <- c("vendor_id",
              "pickup_time",
              "dropoff_time",
              "passenger_count",
              "trip_distance",
              "start_lat",
              "start_long",
              "dest_lat",
              "dest_long",
              "payment_type",
              "fare_amount",
              "extra",
              "mta_tax",
              "tip_amount",
              "tolls_amount",
              "total_amount")
names(taxi) <- varnames

# clean the factor levels
taxi$payment_type <- tolower(taxi$payment_type)
taxi$payment_type <- factor(taxi$payment_type, levels = unique(taxi$payment_type))     


## ------------------------------------------------------------------------
taxi[, mean(tip_amount/total_amount)]

## ------------------------------------------------------------------------
taxi[, .(percent_tip = mean((tip_amount/total_amount)*100)), by = payment_type]

## ------------------------------------------------------------------------
dcast(taxi[payment_type %in% c("credit", "cash")],
      passenger_count~payment_type, 
      fun.aggregate = length,
      value.var = "vendor_id")

## ------------------------------------------------------------------------
# load packages
library(ggplot2)

# set up the canvas
taxiplot <- ggplot(taxi, aes(y=tip_amount, x= fare_amount)) 
taxiplot

## ------------------------------------------------------------------------

# simple x/y plot
taxiplot +
     geom_point()
     

## ------------------------------------------------------------------------

# simple x/y plot
taxiplot +
     geom_point(alpha=0.2)
     

## ------------------------------------------------------------------------
# 2-dimensional bins
taxiplot +
     geom_bin2d()

## ------------------------------------------------------------------------

# 2-dimensional bins
taxiplot +
     stat_bin_2d(geom="point",
                 mapping= aes(size = log(..count..))) +
     guides(fill = FALSE)
     

## ------------------------------------------------------------------------

# compute frequency of per tip amount and payment method
taxi[, n_same_tip:= .N, by= c("tip_amount", "payment_type")]
frequencies <- unique(taxi[payment_type %in% c("credit", "cash"),
                           c("n_same_tip", "tip_amount", "payment_type")][order(n_same_tip, decreasing = TRUE)])


# plot top 20 frequent tip amounts
fare <- ggplot(data = frequencies[1:20], aes(x = factor(tip_amount), y = n_same_tip)) 
fare + geom_bar(stat = "identity") 



## ------------------------------------------------------------------------
fare + geom_bar(stat = "identity") + 
     facet_wrap("payment_type") 
     
     

## ------------------------------------------------------------------------
# indicate natural numbers
taxi[, dollar_paid := ifelse(tip_amount == round(tip_amount,0), "Full", "Fraction"),]


# extended x/y plot
taxiplot +
     geom_point(alpha=0.2, aes(color=payment_type)) +
     facet_wrap("dollar_paid")
     

## ------------------------------------------------------------------------
taxi[, rounded_up := ifelse(fare_amount + tip_amount == round(fare_amount + tip_amount, 0),
                            "Rounded up",
                            "Not rounded")]
# extended x/y plot
taxiplot +
     geom_point(data= taxi[payment_type == "credit"],
                alpha=0.2, aes(color=rounded_up)) +
     facet_wrap("dollar_paid")


## ------------------------------------------------------------------------
modelplot <- ggplot(data= taxi[payment_type == "credit" & dollar_paid == "Fraction" & 0 < tip_amount],
                    aes(x = fare_amount, y = tip_amount))
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black")

## ------------------------------------------------------------------------
modelplot <- ggplot(data= taxi[payment_type == "credit" & dollar_paid == "Fraction" & 0 < tip_amount],
                    aes(x = fare_amount, y = tip_amount))
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black") +
     ylab("Amount of tip paid (in USD)") +
     xlab("Amount of fare paid (in USD)") +
     theme_bw(base_size = 18, base_family = "serif")

## ----echo = FALSE, message=FALSE, warning=FALSE--------------------------
# housekeeping
#gc()
system("rm -r fftaxi")

