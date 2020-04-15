# SQLite and R ------------------------
# -------------------------------------


# SET UP -----------

# load packages
library(RSQLite)
library(data.table)

# initiate the database
con_air <- dbConnect(SQLite(), "materials/data/air.sqlite")


# IMPORT DATA ---------------

# import data into current R sesssion
flights <- fread("materials/data/flights.csv")
airports <- fread("materials/data/airports.csv")
carriers <- fread("materials/data/carriers.csv")

# add tables to database
dbWriteTable(con_air, "flights", flights)
dbWriteTable(con_air, "airports", airports)
dbWriteTable(con_air, "carriers", carriers)


# QUERIES -------------

# define query
delay_query <-
"
SELECT 
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


# be a good citizen and close the connection
dbDisconnect(con_air)

# clean up (remove the example database)
unlink("../data/air.sqlite")
