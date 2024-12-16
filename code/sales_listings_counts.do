/*
	Constructs table of listing and sales counts at the zip-month level.
*/

/* Directories */
global project "~/charlie-project/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"
global datadir "${project}/data"

cd "$project"
cap mkdir "$tempdir"
cap mkdir "$outdir"

/* For query */
set odbcmgr unixodbc

#delimit ;
clear;

/* mls/deed property type codes */
local mls_proptype_selections ('SF', 'CN', 'TH', 'RI', 'MF', 'AP');
local deed_proptype_selections ('10', '11', '20', '22', '21');

/*
	Local to construct string that will union over different quicksearch
	tables in query. Date format is different than corelogic-mls.quicksearch
*/
local suffixes 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;	
local UNION_MLS_SUBQUERIES;
foreach suffix of local suffixes {;
	local UNION_MLS_SUBQUERIES `UNION_MLS_SUBQUERIES'
	UNION
	(SELECT
		cmas_fips_code as fips,
		cmas_parcel_id as apn,
		cmas_parcel_seq_nbr as apn_seq,
		substring(fa_listdate, 8, 4) as year,
		CASE substring(fa_listdate, 1, 3)
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
		cmas_zip5 as orig_zip
	FROM "corelogic-mls".quicksearch_`suffix'
	WHERE 
		(fa_propertytype in `mls_proptype_selections')
		AND (fa_rent_sale_ind='S')
		AND (fa_listdate != '')
		);
};

/* Actual query */
odbc load,
		dsn("SimbaAthena")
		exec(`"
		
		/* Setup common table expressions using WITH clause */
		WITH
			/* Listings */
			raw_mls AS (
				SELECT
					orig_zip,
					year,
					month,
					ROW_NUMBER() OVER
						(	PARTITION BY
								/* will drop duplicates along these vars */
								fips,
								apn,
								apn_seq,
								list_date
						) as rownum
				FROM /* Union of quicksearch* tables */
						(
						(SELECT
							cmas_fips_code as fips, 
							cmas_parcel_id as apn,
							cmas_parcel_seq_nbr as apn_seq,
							substring(trim(fa_listdate), 1, 4) as year,
							cast(substring(fa_listdate, 6, 2) as varchar) as month,
							fa_listdate as list_date,
							cmas_zip5 as orig_zip
						FROM "corelogic-mls".quicksearch
						WHERE
							(fa_propertytype in `mls_proptype_selections')
							AND (fa_rent_sale_ind='S')
							AND (fa_listdate != '')
						)
						`UNION_MLS_SUBQUERIES'
					) 
			),
			
			/* Count listings in zip-year-month */
			mls AS (
				SELECT substring(orig_zip,1,5) as zip, year, month, count(*) as listings
				FROM raw_mls
				WHERE (rownum = 1) /* drops duplicates */
				GROUP BY substring(orig_zip,1,5), year, month
			),
			
			/* Sales */
			raw_deed AS (
				SELECT
					substring("sale derived recording date", 1, 4) as year,
					substring("sale derived recording date", 5, 2) as month,
					substring("deed situs zip code - static", 1, 5) as zip,
				ROW_NUMBER() OVER
					(	PARTITION BY
							/* will drop duplicates along these vars */
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
					AND "deed situs zip code - static" != ''
			),
			
			/* Count sales in zip-year-month */
			deed AS (
				SELECT zip, year, month, count(*) as sales
				FROM raw_deed
				WHERE (rownum = 1) /* drops duplicates */
				GROUP BY zip, year, month
			)
			
			/* Merge sales and listings */
			SELECT *
			FROM mls
			FULL JOIN deed
				USING (zip, year, month)
			ORDER BY zip, year, month

	"');

/* Clean and save */
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

save "${tempdir}/location_time_counts_new.dta", replace;
	
	