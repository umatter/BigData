fs::file_size("data/flights.csv")

if (dir.exists("ff_files")){
     unlink("ff_files", recursive = TRUE, force = TRUE)
}



# SET UP --------------
# install.packages(c("ff", "ffbase"))
# you might have to install the ffbase package directly from GitHub:
# devtools::install_github("edwindj/ffbase", subdir="pkg")
# load packages
library(ff)
library(ffbase)
library(data.table) # for comparison


# create directory for ff chunks, and assign directory to ff 
system("mkdir ff_files")
options(fftempdir = "ff_files")


# usual in-memory csv import
flights_dt <- fread("data/flights.csv")

# out-of-memory approach
flights <- 
     read.table.ffdf(file="data/flights.csv",
                     sep=",",
                     VERBOSE=TRUE,
                     header=TRUE,
                     next.rows=100000,
                     colClasses=NA)

# compare object sizes
object.size(flights) # out-of-memory approach
object.size(flights_dt) # common data.table

# show the files in the directory keeping the chunks
head(list.files("ff_files"))



# SET UP ----------------

# load packages
library(bigmemory)
library(biganalytics)

# import the data
flights <- read.big.matrix("data/flights.csv",
                     type="integer",
                     header=TRUE,
                     backingfile="flights.bin",
                     descriptorfile="flights.desc")

object.size(flights)
str(flights)


# SET UP ----------------

# load packages
library(arrow)

# import the data
flights <- read_csv_arrow("data/flights.csv",
                     as_data_frame = FALSE)

summary(flights)
object.size(flights)


SET UP ------------------------

# create and set directory for ff files
system("mkdir ff_files")
options(fftempdir = "ff_files")

# load packages
library(ff)
library(ffbase)
library(pryr)

# fix vars
FLIGHTS_DATA <- "data/flights_sep_oct15.txt"
AIRLINES_DATA <- "data/airline_id.csv"



# DATA IMPORT ------------------

# check memory used
mem_used()

# 1. Upload flights_sep_oct15.txt and airline_id.csv files from flat files. 

system.time(flights.ff <- read.table.ffdf(file=FLIGHTS_DATA,
                                          sep=",",
                                          VERBOSE=TRUE,
                                          header=TRUE,
                                          next.rows=100000,
                                          colClasses=NA))

system.time(airlines.ff <- read.csv.ffdf(file= AIRLINES_DATA,
                             VERBOSE=TRUE,
                             header=TRUE,
                             next.rows=100000,
                             colClasses=NA))

# check memory used
mem_used()


# Using read.table()
system.time(flights.table <- read.table(FLIGHTS_DATA, 
                                        sep=",",
                                        header=TRUE))
system.time(airlines.table <- read.csv(AIRLINES_DATA,
                                       header = TRUE))
# check the memory used
mem_used()


# 2. Inspect the ff_files objects.
For flights.ff object:
class(flights.ff)
dim(flights.ff)
For airlines.ff object:
class(airlines.ff)
dim(airlines.ff)


# step 1: 
# Rename "Code" variable from airlines.ff 
# to "AIRLINE_ID" and "Description" into "AIRLINE_NM".
names(airlines.ff) <- c("AIRLINE_ID", "AIRLINE_NM")
names(airlines.ff)
str(airlines.ff[1:20,])

# merge of ff_files objects
mem_change(flights.data.ff <- merge.ffdf(flights.ff,
                                         airlines.ff,
                                         by="AIRLINE_ID"))
#The new object is only 551.2 KB in size
class(flights.data.ff)
dim(flights.data.ff)
names(flights.data.ff)

##For flights.table:
names(airlines.table) <- c("AIRLINE_ID", "AIRLINE_NM")
names(airlines.table)
str(airlines.table[1:20,])

# check memory usage of merge in RAM 
mem_change(flights.data.table <- merge(flights.table,
                                       airlines.table,
                                       by="AIRLINE_ID"))
#The new object is already 105.7 MB in size
#A rapid spike in RAM use when processing

mem_used()

# Subset the ff_files object flights.data.ff:
subs1.ff <- 
     subset.ffdf(flights.data.ff, 
                 CANCELLED == 1, 
                 select = c(FL_DATE,
                            AIRLINE_ID,
                            ORIGIN_CITY_NAME,
                            ORIGIN_STATE_NM,
                            DEST_CITY_NAME,
                            DEST_STATE_NM,
                            CANCELLATION_CODE))

dim(subs1.ff)
mem_used()


# Save a newly created ff_files object to a data file:
# (7 files (one for each column) created in the ffdb directory)
save.ffdf(subs1.ff, overwrite = TRUE) 


# Loading previously saved ff_files files:
rm(subs1.ff)
#gc()
load.ffdf("ffdb")
# check the class and structure of the loaded data
class(subs1.ff) 
dim(subs1.ff)
dimnames(subs1.ff)

#  Export subs1.ff into CSV and TXT files:
write.csv.ffdf(subs1.ff, "subset1.csv")



# SET UP ----------------

# load packages
library(arrow)
library(dplyr)
library(pryr) # for profiling

# fix vars
FLIGHTS_DATA <- "data/flights_sep_oct15.txt"
AIRLINES_DATA <- "data/airline_id.csv"

# import the data
flights <- read_csv_arrow(FLIGHTS_DATA,
                     as_data_frame = FALSE)
airlines <- read_csv_arrow(AIRLINES_DATA,
                     as_data_frame = FALSE)

class(flights)
class(airlines)
object_size(flights)
object_size(airlines)

# step 1: 
# Rename "Code" variable from airlines.ff to "AIRLINE_ID"
# and "Description" into "AIRLINE_NM".
names(airlines) <- c("AIRLINE_ID", "AIRLINE_NM")
names(airlines)

# merge the two datasets via Arrow
flights.data.ar <- inner_join(airlines, flights, by="AIRLINE_ID")
object_size(flights.data.ar)


# Subset the ff_files object flights.data.ff:
subs1.ar <- 
        flights.data.ar %>%
        filter(CANCELLED == 1) %>%
        select(FL_DATE,
               AIRLINE_ID,
               ORIGIN_CITY_NAME,
               ORIGIN_STATE_NM,
               DEST_CITY_NAME,
               DEST_STATE_NM,
               CANCELLATION_CODE)
        
object_size(subs1.ar)

mem_change(subs1.ar.df <- collect(subs1.ar))
class(subs1.ar.df)
object_size(subs1.ar.df)

subs1.ar %>% 
        compute() %>% 
        write_csv_arrow(file="data/subs1.ar.csv")
