## ----message=FALSE-------------------------------------------------------

# SET UP --------------

# install.packages(c("ff", "ffbase"))
# load packages
library(ff)
library(ffbase)
library(pryr)

# create directory for ff chunks, and assign directory to ff 
system("mkdir ffdf")
options(fftempdir = "ffdf")


## ------------------------------------------------------------------------
mem_change(
flights <- 
     read.table.ffdf(file="../data/flights.csv",
                     sep=",",
                     VERBOSE=TRUE,
                     header=TRUE,
                     next.rows=100000,
                     colClasses=NA)
)

## ------------------------------------------------------------------------
# show the files in the directory keeping the chunks
list.files("ffdf")

# investigate the structure of the object created in the R environment
str(flights)


## ------------------------------------------------------------------------

# SET UP ----------------

# load packages
library(bigmemory)
library(biganalytics)

# import the data
flights <- read.big.matrix("../data/flights.csv",
                     type="integer",
                     header=TRUE,
                     backingfile="flights.bin",
                     descriptorfile="flights.desc")

## ------------------------------------------------------------------------
summary(flights)

## ------------------------------------------------------------------------

## SET UP ------------------------

#Set working directory to the data and airline_id files.
# setwd("materials/code_book/B05396_Ch03_Code")
system("mkdir ffdf")
options(fftempdir = "ffdf")

# load packages
library(ff)
library(ffbase)
library(pryr)

# fix vars
FLIGHTS_DATA <- "../code_book/B05396_Ch03_Code/flights_sep_oct15.txt"
AIRLINES_DATA <- "../code_book/B05396_Ch03_Code/airline_id.csv"


## ------------------------------------------------------------------------

# DATA IMPORT ------------------

# 1. Upload flights_sep_oct15.txt and airline_id.csv files from flat files. 

system.time(flights.ff <- read.table.ffdf(file=FLIGHTS_DATA,
                                          sep=",",
                                          VERBOSE=TRUE,
                                          header=TRUE,
                                          next.rows=100000,
                                          colClasses=NA))

airlines.ff <- read.csv.ffdf(file= AIRLINES_DATA,
                             VERBOSE=TRUE,
                             header=TRUE,
                             next.rows=100000,
                             colClasses=NA)
# check memory used
mem_used()


## ------------------------------------------------------------------------

##Using read.table()
system.time(flights.table <- read.table(FLIGHTS_DATA, 
                                        sep=",",
                                        header=TRUE))

gc()

system.time(airlines.table <- read.csv(AIRLINES_DATA,
                                       header = TRUE))


# check memory used
mem_used()


## ------------------------------------------------------------------------
# 2. Inspect the ffdf objects.
## For flights.ff object:
class(flights.ff)
dim(flights.ff)
## For airlines.ff object:
class(airlines.ff)
dim(airlines.ff)


## ------------------------------------------------------------------------
# step 1: 
## Rename "Code" variable from airlines.ff to "AIRLINE_ID" and "Description" into "AIRLINE_NM".
names(airlines.ff) <- c("AIRLINE_ID", "AIRLINE_NM")
names(airlines.ff)
str(airlines.ff[1:20,])

## ------------------------------------------------------------------------
# merge of ffdf objects
mem_change(flights.data.ff <- merge.ffdf(flights.ff, airlines.ff, by="AIRLINE_ID"))
#The new object is only 551.2 Kb in size
class(flights.data.ff)
dim(flights.data.ff)
dimnames.ffdf(flights.data.ff)

## ------------------------------------------------------------------------
##For flights.table:
names(airlines.table) <- c("AIRLINE_ID", "AIRLINE_NM")
names(airlines.table)
str(airlines.table[1:20,])

# check memory usage of merge in RAM 
mem_change(flights.data.table <- merge(flights.table,
                                       airlines.table,
                                       by="AIRLINE_ID"))
#The new object is already 105.7 Mb in size
#A rapid spike in RAM use when processing

## ------------------------------------------------------------------------

# Inspect the current variable
table.ff(flights.data.ff$DAY_OF_WEEK)
head(flights.data.ff$DAY_OF_WEEK)

# Convert numeric ff DAY_OF_WEEK vector to a ff factor:
flights.data.ff$WEEKDAY <- cut.ff(flights.data.ff$DAY_OF_WEEK, 
                                   breaks = 7, 
                                   labels = c("Monday", "Tuesday", 
                                              "Wednesday", "Thursday", 
                                              "Friday", "Saturday",
                                              "Sunday"))
# inspect the result
head(flights.data.ff$WEEKDAY)
table.ff(flights.data.ff$WEEKDAY)


## ------------------------------------------------------------------------
mem_used()

# Subset the ffdf object flights.data.ff:
subs1.ff <- subset.ffdf(flights.data.ff, CANCELLED == 1, 
                        select = c(FL_DATE, AIRLINE_ID, 
                                   ORIGIN_CITY_NAME,
                                   ORIGIN_STATE_NM,
                                   DEST_CITY_NAME,
                                   DEST_STATE_NM,
                                   CANCELLATION_CODE))

dim(subs1.ff)
mem_used()


## ------------------------------------------------------------------------
# Save a newly created ffdf object to a data file:

save.ffdf(subs1.ff) #7 files (one for each column) created in the ffdb directory


## ------------------------------------------------------------------------
# Loading previously saved ffdf files:
rm(subs1.ff)
gc()
load.ffdf("ffdb")
str(subs1.ff)
dim(subs1.ff)
dimnames(subs1.ff)

## ----message=FALSE-------------------------------------------------------
#  Export subs1.ff into CSV and TXT files:
write.csv.ffdf(subs1.ff, "subset1.csv")


