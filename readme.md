# Readme

## Main query of tax, deed, and listings tables (project for Adam & Charlie)
### How to run
- klc_instructions.txt provides a guide to logging into KLC in the terminal
- The do-file you will run is main.do, and you will need to change the definition of the global macro *project*, near the top of that file, to the path of this corelogic directory on your KLC.
- In main.do, the global macro *chosen_fips* determines which fips code is queried. The global macro *new_listing_cutoff* affects how many days can pass between repeat home listings before a listing is classified as a new listing (note: intervening sales *always* result in a new listing). New listings are defined in code/clean.do.
- *mls_proptype_selections* and *deed_proptype_selections* in main.do determine which types of properties are included in the query (code/sql_query.doh).
- To run, cd into the directory of this repository and enter *'stata-mp -b do main.do'*
- If code is successful, output will be found in *'output/data_final_<chosen_fips>.dta'*. If there is a bug in the query itself, debugging can be a pain. If possible, doing a smaller query using the web console can help, otherwise trial and error. Log for the code will be saved as *'main.log'* and you can get a vague SQL explanation at the bottom of the log file.

### *main.do*
- main.do loops over quarters and *includes* code/sql_query.doh so all locals are available in code/sql_query.doh
- This file then calls *code/clean.do* and then saves the final output.

### *code/sql_query.doh*
- Variable to show up in final dataset are selected in final SELECT command toward the bottom, which merges variables from the deed and listings tables with the tax table.
- To add/delete variables:
-- For variables in the deed, tax, or listings tables, add variable to the SELECT statement in the raw_<table> common table expresson. If the variable comes from the listings table, you must also add to where the local *UNION_MLS_SUBQUERIES* is constructed because it must be queried in each of the quicksearch_******** tables. In this case, add the variable in the same place (relative to the other variables) as you choose to add it to raw_mls directly.
-- Note if you alias a variable or computed value in SELECT and use it in a WHERE or other statement below, you must still refer to the original variable/computation in statements below SELECT and not refer to the alias.
-- If the new variable is in listings or deed tables, you must then go to where the queries from these tables are appended together (section starting with the *data AS*). The new variable must be added to both SELECT statements, with the same placement relative to the other variables. If the variable is only taken from one of the two tables, then in place of the *<variable name>* you must add *NULL as <variable name>* to the table that you are *not* getting the variable from.
-- Finally, add the variable to the final SELECT statement, with a *d.* prefix if it is from the listings or deed table and a *t.* prefix if it is from the tax table.

### *code/clean.do*
- Cleans the final dataset and defines a variable to identify new listings, is called by *main.do*

## Counts by location and month
### *code/sales_listings_counts.do*
- This code produces counts of sales and listings by zip-month, run by itself.
- Can run this script from whatever directory--the log file will be created where you run in.

### *code/listing_service_counts.do*
- This code produces counts of listings by zip-month-listing service, run by itself
- Can run this script from whatever directory--the log file will be created where you run in.
- Requires the HUD-USPS zip-msa crosswalk *'data/ZIP_CBSA_032020.xlsx'*, which adds a variable for the msa. Can be downloaded from HUD website. Should be straightforward to remove this merge from the code if this is unwanted and crosswalk is not available.

## Produce time series of many zips to evaluate algorithm for sales and listings startup times
### *code/find_startup_dates_by_zip.do*
- To by run by itself, but uses the file produced by *'code/sales_listings_counts.do'* so this must be run first
- Uses Adam's algorithm.
- Produces a pdf of plots for 112 zips across 14 pages, number of zips and pages is hardcoded so will need to look at the code carefully to change.

## Get listings in year t divided by total sales in t-k
My understanding is that this was number of listings of distinct properties in year t divided by number of sales of distinct properties in t-k, so I count a property only once if it was listed (sold) twice in t (t-k).
### *code/listings_and_past_sales.do*
- This code is run by itself but requires the final data from *'main.do'*. Because *'main.do'* produces a file *'output/data_final_<some fips>.dta', the local variable chosen_fips in this code needs to be set to whatever fips shows up in that file name.
- The project directory needs to be set to wherever the main directory of this repository is for you.
- Note: this code will save an intermediate file of sales counts by year in *'temp/nsales_by_year.dta'*. If that's all you want, you can just use that file, where the variable *prev_sale_year* is the year associated with the given row, so you should rename it as *year* (it's given the weird name in the code to facilitate a later merge).
- The final data is saved as *'output/listings_and_past_sales.dta'*. I think this should give you the numerators and denominators for the statistics you want.

## Checking quality of the sales numbers in assessor tables
### *code/total_sales_from_assessor.do*
- This file runs a query to get a time series of the total number of distinct sales (not distinct properties sold) in each year, using *only* the tax tables.
- Global macro *project* needs to be changed, and must be run on KLC
