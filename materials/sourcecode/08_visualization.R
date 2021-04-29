## ----warning=FALSE, echo=FALSE, message=FALSE-----------------------------------------------------

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






## -------------------------------------------------------------------------------------------------
# load packages
library(ggplot2)

# set up the canvas
taxiplot <- ggplot(taxi, aes(y=tip_amount, x= fare_amount)) 
taxiplot


## -------------------------------------------------------------------------------------------------

# simple x/y plot
taxiplot +
     geom_point()
     


## -------------------------------------------------------------------------------------------------

# simple x/y plot
taxiplot +
     geom_point(alpha=0.2)
     


## -------------------------------------------------------------------------------------------------
# 2-dimensional bins
taxiplot +
     geom_bin2d()


## -------------------------------------------------------------------------------------------------

# 2-dimensional bins
taxiplot +
     stat_bin_2d(geom="point",
                 mapping= aes(size = log(..count..))) +
     guides(fill = FALSE)
     


## -------------------------------------------------------------------------------------------------

# compute frequency of per tip amount and payment method
taxi[, n_same_tip:= .N, by= c("tip_amount", "payment_type")]
frequencies <- unique(taxi[payment_type %in% c("credit", "cash"),
                           c("n_same_tip", "tip_amount", "payment_type")][order(n_same_tip, decreasing = TRUE)])


# plot top 20 frequent tip amounts
fare <- ggplot(data = frequencies[1:20], aes(x = factor(tip_amount), y = n_same_tip)) 
fare + geom_bar(stat = "identity") 




## -------------------------------------------------------------------------------------------------
fare + geom_bar(stat = "identity") + 
     facet_wrap("payment_type") 
     
     


## -------------------------------------------------------------------------------------------------
# indicate natural numbers
taxi[, dollar_paid := ifelse(tip_amount == round(tip_amount,0), "Full", "Fraction"),]


# extended x/y plot
taxiplot +
     geom_point(alpha=0.2, aes(color=payment_type)) +
     facet_wrap("dollar_paid")
     


## -------------------------------------------------------------------------------------------------
taxi[, rounded_up := ifelse(fare_amount + tip_amount == round(fare_amount + tip_amount, 0),
                            "Rounded up",
                            "Not rounded")]
# extended x/y plot
taxiplot +
     geom_point(data= taxi[payment_type == "credit"],
                alpha=0.2, aes(color=rounded_up)) +
     facet_wrap("dollar_paid")



## -------------------------------------------------------------------------------------------------
modelplot <- ggplot(data= taxi[payment_type == "credit" & dollar_paid == "Fraction" & 0 < tip_amount],
                    aes(x = fare_amount, y = tip_amount))
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black")


## -------------------------------------------------------------------------------------------------
modelplot <- ggplot(data= taxi[payment_type == "credit" & dollar_paid == "Fraction" & 0 < tip_amount],
                    aes(x = fare_amount, y = tip_amount))
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black") +
     ylab("Amount of tip paid (in USD)") +
     xlab("Amount of fare paid (in USD)") +
     theme_bw(base_size = 18, base_family = "serif")


## -------------------------------------------------------------------------------------------------
modelplot <- ggplot(data= taxi[payment_type == "credit" & dollar_paid == "Fraction" & 0 < tip_amount],
                    aes(x = fare_amount, y = tip_amount))
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black") +
     ylab("Amount of tip paid (in USD)") +
     xlab("Amount of fare paid (in USD)") +
     theme_bw(base_size = 18, base_family = "serif") +
     theme(axis.title = element_text(face="bold"))
  


## -------------------------------------------------------------------------------------------------
# 'define' a new theme
theme_my_serif <-      
  theme_bw(base_size = 18, base_family = "serif") +
  theme(axis.title = element_text(face="bold"))

# apply it 
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black") +
     ylab("Amount of tip paid (in USD)") +
     xlab("Amount of fare paid (in USD)") +
  theme_my_serif


## -------------------------------------------------------------------------------------------------
# 'define' a new theme
my_serif_theme <-      
  theme_bw(base_size = 18, base_family = "serif") +
  theme(axis.title = element_text(face="bold"), complete = TRUE)

# apply it 
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black") +
     ylab("Amount of tip paid (in USD)") +
     xlab("Amount of fare paid (in USD)") +
  theme_my_serif


## -------------------------------------------------------------------------------------------------
# define own theme
theme_my_serif <- 
  function(base_size = 15,
           base_family = "",
           base_line_size = base_size/170,
           base_rect_size = base_size/170){ 
    
    theme_bw(base_size = base_size,
             base_family = base_family,
             base_line_size = base_size/170,
             base_rect_size = base_size/170) %+replace%    # use theme_bw() as a basis but replace some design elements
    theme(
      axis.title = element_text(face="bold")
    )
  }

# apply the theme
# apply it 
modelplot +
     geom_point(alpha=0.2, colour="darkgreen") +
     geom_smooth(method = "lm", colour = "black") +
     ylab("Amount of tip paid (in USD)") +
     xlab("Amount of fare paid (in USD)") +
  theme_my_serif(base_size = 18, base_family="serif")


## ----message=FALSE, warning=FALSE-----------------------------------------------------------------
# load GIS packages
library(rgdal)
library(rgeos)


## ----message=FALSE, warning=FALSE-----------------------------------------------------------------
# download the zipped shapefile to a temporary file, unzip
URL <- "https://www1.nyc.gov/assets/planning/download/zip/data-maps/open-data/nycd_19a.zip"
tmp_file <- tempfile()
download.file(URL, tmp_file)
file_path <- unzip(tmp_file, exdir= "../data")
# delete the temporary file
unlink(tmp_file)



## ----message=FALSE, warning=FALSE-----------------------------------------------------------------
# read GIS data
nyc_map <- readOGR(file_path[1], verbose = FALSE)

# have a look at the GIS data
summary(nyc_map)


## -------------------------------------------------------------------------------------------------
# transform the projection
nyc_map <- spTransform(nyc_map, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
# check result
summary(nyc_map)


## ----warning=FALSE, message=FALSE-----------------------------------------------------------------
nyc_map <- fortify(nyc_map)


## -------------------------------------------------------------------------------------------------
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



## -------------------------------------------------------------------------------------------------
taxi_trips$start_time <- hour(taxi_trips$pickup_time)


## -------------------------------------------------------------------------------------------------
# define new variable for facets
taxi_trips$time_of_day <- "Morning"
taxi_trips[start_time > 12 & start_time < 17]$time_of_day <- "Afternoon"
taxi_trips[start_time %in% c(17:24, 0:5)]$time_of_day <- "Evening/Night"
taxi_trips$time_of_day  <- factor(taxi_trips$time_of_day, levels = c("Morning", "Afternoon", "Evening/Night"))



## -------------------------------------------------------------------------------------------------
# set up the canvas
locations <- ggplot(taxi_trips, aes(x=long, y=lat))
# add the map geometry
locations <- locations + geom_map(data = nyc_map,
                                  map = nyc_map,
                                  aes(map_id = id))
locations


## -------------------------------------------------------------------------------------------------
# add pick-up locations to plot
locations + 
     geom_point(aes(x=start_long, y=start_lat),
                color="orange",
                size = 0.1,
                alpha = 0.2)



## -------------------------------------------------------------------------------------------------
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
 



## ----fig.height=3, fig.width=9--------------------------------------------------------------------

# pick-up locations 
locations +
     geom_point(aes(x=start_long, y=start_lat),
                color="orange",
                size = 0.1,
                alpha = 0.2) +
     facet_wrap(vars(time_of_day))
 


## ----fig.height=3, fig.width=9--------------------------------------------------------------------

# drop-off locations 
locations +
     geom_point(aes(x=dest_long, y=dest_lat),
                color="steelblue",
                size = 0.1,
                alpha = 0.2) +
     facet_wrap(vars(time_of_day))
 


## -------------------------------------------------------------------------------------------------
# drop-off locations 
locations +
     geom_point(aes(x=dest_long, y=dest_lat, color = start_time ),
                size = 0.1,
                alpha = 0.2) +
     scale_colour_gradient2( low = "red", mid = "yellow", high = "red",
                             midpoint = 12)
 


## -------------------------------------------------------------------------------------------------
# drop-off locations 
locations +
     geom_point(aes(x=dest_long, y=dest_lat, color = start_time ),
                size = 0.1,
                alpha = 0.2) 
 


## -------------------------------------------------------------------------------------------------
# indicate natural numbers
taxi[, dollar_paid := ifelse(tip_amount == round(tip_amount,0), "Full", "Fraction"),]


# extended x/y plot
taxiplot +
     geom_point(alpha=0.2, aes(color=payment_type)) +
     facet_wrap("dollar_paid")
     


## -------------------------------------------------------------------------------------------------
# indicate natural numbers
taxi[, dollar_paid := ifelse(tip_amount == round(tip_amount,0), "Full", "Fraction"),]


# extended x/y plot
taxiplot +
     geom_point(alpha=0.2, aes(color=payment_type)) +
     facet_wrap("dollar_paid") +
     scale_color_discrete(type = c("red", "steelblue", "orange", "purple"))
     

