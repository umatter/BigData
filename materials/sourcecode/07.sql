-- Set Up (bash, in terminal) -------------------------------
cd materials/data 
sqlite3 mydb.sqlite


-- inspect tables
.tables


-- create table
CREATE TABLE econ(
"date" DATE,
"pce" REAL,
"pop" INTEGER,
"psavert" REAL,
"uempmed" REAL,
"unemploy" INTEGER
);


-- import data
.mode csv
.import economics.csv econ


-- inspect table

.tables
.schema econ


-- set output options for interactive session
.header on
.mode columns



-- Example 1: query data ---------------------------------

-- simple query (search one entry)
select * from econ where date = '1968-01-01'

-- filter, order
select date from econ 
where unemploy > 15000
order by date;


-- exit SQLite
.quit

