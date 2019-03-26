## ----warning=FALSE, echo=FALSE, message=FALSE----------------------------

# SET UP----
# see 05_aggregtion_visualization.Rmd for details
# load packages
library(data.table)
library(ggplot2)

# import data into RAM (needs around 200MB)
taxi <- fread("../data/tlc_trips.csv",
              nrows = 1000000)



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
              "start_long",
              "start_lat",
              "dest_long",
              "dest_lat",
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





## ----message=FALSE, warning=FALSE----------------------------------------
# load GIS packages
library(rgdal)
library(rgeos)

## ----message=FALSE, warning=FALSE----------------------------------------
# download the zipped shapefile to a temporary file, unzip
URL <- "https://www1.nyc.gov/assets/planning/download/zip/data-maps/open-data/nycd_19a.zip"
tmp_file <- tempfile()
download.file(URL, tmp_file)
file_path <- unzip(tmp_file, exdir= "../data")
# delete the temporary file
unlink(tmp_file)


## ----message=FALSE, warning=FALSE----------------------------------------
# read GIS data
nyc_map <- readOGR(file_path[1], verbose = FALSE)

# have a look at the GIS data
summary(nyc_map)

## ------------------------------------------------------------------------
# transform the projection
nyc_map <- spTransform(nyc_map, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
# check result
summary(nyc_map)

## ----warning=FALSE, message=FALSE----------------------------------------
nyc_map <- fortify(nyc_map)

## ------------------------------------------------------------------------
# taxi trips plot data
taxi_trips <- taxi[start_long <= max(nyc_map$long) & 
                        start_long >= min(nyc_map$long) &
                        dest_long <= max(nyc_map$long) &
                        dest_long >= min(nyc_map$long) &
                        start_lat <= max(nyc_map$lat) & 
                        start_lat >= min(nyc_map$lat) &
                        dest_lat <= max(nyc_map$lat) &
                        dest_lat >= min(nyc_map$lat) 
                        ]
taxi_trips <- taxi_trips[sample(nrow(taxi_trips), 50000)]


## ------------------------------------------------------------------------
taxi_trips$start_time <- hour(taxi_trips$pickup_time)

## ------------------------------------------------------------------------
# define new variable for facets
taxi_trips$time_of_day <- "Morning"
taxi_trips[start_time > 12 & start_time < 17]$time_of_day <- "Afternoon"
taxi_trips[start_time %in% c(17:24, 0:5)]$time_of_day <- "Evening/Night"
taxi_trips$time_of_day  <- factor(taxi_trips$time_of_day, levels = c("Morning", "Afternoon", "Evening/Night"))


## ------------------------------------------------------------------------
# set up the canvas
locations <- ggplot(taxi_trips, aes(x=long, y=lat))
# add the map geometry
locations <- locations + geom_map(data = nyc_map,
                                  map = nyc_map,
                                  aes(map_id = id))
locations

## ------------------------------------------------------------------------
# add pick-up locations to plot
locations + 
     geom_point(aes(x=start_long, y=start_lat),
                color="orange",
                size = 0.1,
                alpha = 0.2)


## ------------------------------------------------------------------------
# add pick-up locations to plot
locations +
     geom_point(aes(x=dest_long, y=dest_lat),
                color="steelblue",
                size = 0.1,
                alpha = 0.2) +
     geom_point(aes(x=start_long, y=start_lat),
                color="orange",
                size = 0.1,
                alpha = 0.2)
 


## ----fig.height=3, fig.width=9-------------------------------------------

# pick-up locations 
locations +
     geom_point(aes(x=start_long, y=start_lat),
                color="orange",
                size = 0.1,
                alpha = 0.2) +
     facet_wrap(vars(time_of_day))
 

## ----fig.height=3, fig.width=9-------------------------------------------

# drop-off locations 
locations +
     geom_point(aes(x=dest_long, y=dest_lat),
                color="steelblue",
                size = 0.1,
                alpha = 0.2) +
     facet_wrap(vars(time_of_day))
 

## ------------------------------------------------------------------------
# drop-off locations 
locations +
     geom_point(aes(x=dest_long, y=dest_lat, color = start_time ),
                size = 0.1,
                alpha = 0.2) +
     scale_colour_gradient2( low = "red", mid = "yellow", high = "red",
                             midpoint = 12)
 

## ------------------------------------------------------------------------
# load packages
library(RSQLite)

# initiate the database
con_air <- dbConnect(SQLite(), "../data/air.sqlite")

## ------------------------------------------------------------------------

# import data into current R sesssion
flights <- fread("../data/flights.csv")
airports <- fread("../data/airports.csv")
carriers <- fread("../data/carriers.csv")

# add tables to database
dbWriteTable(con_air, "flights", flights)
dbWriteTable(con_air, "airports", airports)
dbWriteTable(con_air, "carriers", carriers)


## ------------------------------------------------------------------------
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


## ----echo=FALSE----------------------------------------------------------
# clean up
unlink("../data/air.sqlite")

