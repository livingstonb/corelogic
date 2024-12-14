

global project "~/charlie-project/corelogic"
// global project "~/Dropbox/NU/Spring 2024/RA/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"
global datadir "${project}/data"

cd "$project"
cap mkdir "$tempdir"
cap mkdir "$outdir"

set odbcmgr unixodbc

#delimit ;
clear;

global new_listing_cutoff 180;

/* macro for mls/deed property type codes */
local mls_proptype_selections ('SF', 'CN', 'TH', 'RI', 'MF', 'AP');
local deed_proptype_selections ('10', '11', '20', '22', '21');

/* macro for extra quicksearch tables */
local suffixes 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;			
			

/* Date variable is formatted differently in quicksearch_* tables
than in quicksearch, so have to take query these differently.
*/
local UNION_MLS_SUBQUERIES;
foreach suffix of local suffixes {;
	local UNION_MLS_SUBQUERIES `UNION_MLS_SUBQUERIES'
	UNION
	(SELECT
		cmas_fips_code as fips,
		cmas_parcel_id as apn,
		cmas_parcel_seq_nbr as apn_seq,
		substring(fa_listdate,8,4) as year,
		CASE substring(fa_listdate,1,3)
			WHEN 'Jan' THEN '01'
			WHEN 'Feb' THEN '02'
			WHEN 'Mar' THEN '03'
			WHEN 'Apr' THEN '04'
			WHEN 'May' THEN '05'
			WHEN 'Jun' THEN '06'
			WHEN 'Jul' THEN '07'
			WHEN 'Aug' THEN '08'
			WHEN 'Sep' THEN '09'
			WHEN 'Oct' THEN '10'
			WHEN 'Nov' THEN '11'
			WHEN 'Dec' THEN '12'
		END as month,
		fa_listdate as list_date,
		cmas_zip5 as zip
	FROM "corelogic-mls".quicksearch_`suffix'
	WHERE 
		(fa_propertytype in `mls_proptype_selections')
		AND (fa_rent_sale_ind='S')
		AND (fa_listdate != '')
		);
};
/*
- First set up subquery 'tax'
*/

/* Query */
odbc load,
		dsn("SimbaAthena")
		exec(`"
		
		WITH
			/* LISTINGS TABLES */
			raw_mls AS (
				SELECT
					zip,
					year,
					month,
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								fips,
								apn,
								apn_seq,
								list_date
						) as rownum
				FROM (
					(SELECT
						cmas_fips_code as fips, 
						cmas_parcel_id as apn,
						cmas_parcel_seq_nbr as apn_seq,
						substring(trim(fa_listdate), 1, 4) as year,
						cast(substring(fa_listdate, 6, 2) as varchar) as month,
						fa_listdate as list_date,
						cmas_zip5 as zip
					FROM "corelogic-mls".quicksearch
					WHERE
						(fa_propertytype in `mls_proptype_selections')
						AND (fa_rent_sale_ind='S')
						AND (fa_listdate != '')
					)
				`UNION_MLS_SUBQUERIES' ) 
			),
			
			mls AS (
				SELECT zip, year, month, count(*) as listings
				FROM raw_mls
				WHERE (rownum = 1) /* drops duplicates */
			),
			
			/* DEED TABLES */
			raw_deed AS (
				SELECT
					substring("sale derived recording date", 1, 4) as year,
					substring("sale derived recording date", 5, 2) as month,
					"deed situs zip code - static" as zip,
				ROW_NUMBER() OVER
					(	PARTITION BY /* variables selected for drop duplicates */
							"fips code",
							"apn (parcel number unformatted)",
							"apn sequence number",
							"sale derived recording date"
					) as rownum
				FROM
					corelogic2.ownertransfer
				WHERE 
					("primary category code" in ('A'))
					AND ("property indicator code - static" in `deed_proptype_selections')
					AND ("sale amount" > 0)
			),
			
			deed AS (
				SELECT zip, year, month, count(*) as sales
				FROM raw_deed
				WHERE (rownum = 1)
			)
			
			SELECT *
			FROM mls
			FULL JOIN deed
				USING (zip, year, month)
			GROUP BY zip, year, month
			ORDER BY zip, year, month

	"');
	
save "${tempdir}/location_time_counts_new.dta", replace;

keep if strlen(strtrim(zip)) == 5;
drop if strpos(zip, "#") > 0;
drop if strpos(zip, "@") > 0;
drop if strpos(zip, "A") > 0;
drop if strpos(zip, "C") > 0;
drop if strpos(zip, "T") > 0;

destring year month, force replace;
drop if month == 0;
gen mdate = ym(year, month);
format %tm mdate;

drop if year <= 1950;
drop if year > 2025;
	
	