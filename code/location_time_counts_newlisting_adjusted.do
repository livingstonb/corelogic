

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
		substring(fa_listdate, 5, 2) as day,
		fa_listdate as list_date,
		fa_propertytype as mls_proptype,
		'listing' as entry
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
			
			/* TAX TABLES
			raw_tax AS (
				SELECT
					/* tsep is _ in 2018q4, otherwise is space */
					"fips`tsep'code" as fips,
					"apn`tsep'unformatted" as apn,
					"apn`tsep'sequence`tsep'number" as apn_seq,
					"property`tsep'zipcode" as zip,
					"land`tsep'square`tsep'footage" as land_footage,
					"total`tsep'baths`tsep'calculated" as nbaths,
					"bedrooms",
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								"fips`tsep'code",
								"apn`tsep'unformatted",
								"apn`tsep'sequence`tsep'number"
							ORDER BY /* cdetermines how to select among duplicates */
								"land`tsep'square`tsep'footage" DESC
						) as rownum
				FROM corelogic.`tax_table'
				WHERE
					("fips`tsep'code" = '${chosen_fips}')
			),
			
			tax AS (
				SELECT *
				FROM raw_tax
				WHERE (rownum = 1) /* drops duplicates */
			), */
			
			/* LISTINGS TABLES */
			raw_mls AS (
				SELECT *,
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								fips,
								apn,
								apn_seq,
								list_date
							ORDER BY /* determines how to select among duplicates */
								listing_id DESC
						) as rownum
				FROM (
					(SELECT
						cmas_fips_code as fips, 
						cmas_parcel_id as apn,
						cmas_parcel_seq_nbr as apn_seq,
						substring(trim(fa_listdate), 1, 4) as year,
						cast(substring(fa_listdate, 6, 2) as varchar) as month,
						cast(substring(fa_listdate, 9, 2) as varchar) as day,
						fa_listdate as list_date,
						fa_propertytype as mls_proptype,
						'listing' as entry
					FROM "corelogic-mls".quicksearch
					WHERE
						(fa_propertytype in `mls_proptype_selections')
						AND (fa_rent_sale_ind='S')
						AND (fa_listdate != '')
					)
				`UNION_MLS_SUBQUERIES' )
			),
			
			mls AS (
				SELECT *
				FROM raw_mls
				WHERE (rownum = 1) /* drops duplicates */
			),
			
			/* DEED TABLES */
			raw_deed AS (
				SELECT
					"fips code" as fips,
					"apn (parcel number unformatted)" as apn,
					"apn sequence number" as apn_seq,
					"sale derived recording date" as recording_date,
					substring("sale derived recording date", 1, 4) as year,
					substring("sale derived recording date", 5, 2) as month,
					substring("sale derived recording date", 8, 2) as day,
					"transaction batch date" as trans_batch_date,
					"transaction batch sequence number" as trans_batch_seq,
					"sale derived date" as sale_date,
					"sale amount" as sale_amount,
					"land use code - static" as land_use_code,
					'sale' as entry,
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								"fips code",
								"apn (parcel number unformatted)",
								"apn sequence number",
								"sale derived recording date"
							ORDER BY /* determines how to select among duplicates */
								"sale amount" DESC
						) as rownum
				FROM
					corelogic2.ownertransfer
				WHERE 
					("primary category code" in ('A'))
					AND ("property indicator code - static" in `deed_proptype_selections')
					AND ("sale amount" > 0)
			),
			
			deed AS (
				SELECT *
				FROM raw_deed
				WHERE (rownum = 1) /* drops duplicates */
			),
			
			/* append listings and deed queries
				- keep variables in same order for both tables
				- use NULL AS if variable does not show up in that table
			*/
			data AS (
				SELECT fips, apn, apn_seq, year, month, day, entry,
					list_date, mls_proptype,
					NULL AS recording_date,
					NULL AS land_use_code,
					NULL as sale_amount
				FROM mls 
				UNION
				SELECT fips, apn, apn_seq, year, month, day, entry,
				    NULL AS list_date,
				    NULL AS mls_proptype,
				    recording_date, land_use_code, sale_amount
				FROM deed
			),

		/* merge (listings + deed) with tax tables
		SELECT 	d.fips,
				d.apn,
				d.apn_seq,
				d.year,
				d.month,
				d.day,
				d.entry,
				d.sale_amount,
				d.mls_proptype,
				d.mls_service_name,
				d.mls_service_code,
				t.zip,
				t.nbaths,
				t.bedrooms,
				t.land_footage
		FROM data as d
		LEFT JOIN tax as t
			ON
				(d.fips = t.fips)
				AND (d.apn = t.apn)
				AND (cast(d.apn_seq as int) = cast(t.apn_seq as int))
		ORDER BY
			d.fips,
			d.apn,
			d.apn_seq,
			d.list_date
			*/
		
		/* adjust for new listing */
		
		new_listings AS (
			SELECT *,
				MAKE_DATE(year, month, day) as constructed_date,
				LAG(entry) OVER (
					PARTITION BY
						fips, apn, apn_seq
					ORDER BY
						year, month, day
					) AS prev_entry,
				ROW_NUMBER() OVER (
					PARTITION BY
						fips, apn, apn_seq
					ORDER BY
						year, month, day
					) AS row_num
			FROM data
		),
		
		final_data AS (
			SELECT *,
				LAG(constructed_date) OVER (
					PARTITION BY
						fips, apn, apn_seq
					ORDER BY
						constructed_date
					) AS prev_date,
				CASE 
					WHEN prev_entry = 'sale' THEN 1
					ELSE 0
				END AS prev_deed,
				CASE
					WHEN prev_entry = 'listing' THEN 1
					ELSE 0
				END AS prev_mls,
				-- Create 'newlisting' as 1 for the first row in the group
				CASE 
				WHEN row_num = 1 THEN 1
					ELSE 0
				END AS newlisting
			FROM new_listings
		),
		
		pre_newlistings AS (
			SELECT *,
				CASE
					WHEN (entry = 'listing' AND prev_deed = 1)
						OR (entry = 'sale' AND prev_deed = 1)
						THEN 1
					ELSE newlisting
				END AS newlisting
			FROM final_data
		),
		
		newlistings AS (
			SELECT *,
				CASE
					WHEN (constructed_date - prev_date > ${new_listing_cutoff})
						AND (entry = 'listing') AND (prev_mls = 1)
						THEN 1
					ELSE newlisting
				END as newlisting
			FROM pre_newlistings
		)
		
		
		SELECT substring(zip, 1, 5) as zip,
			year,
			month,
			count(*) as listings
		FROM 
		WHERE newlisting = 1
		GROUP BY zip, year, month
	"');
	
save "${tempdir}/location_time_counts_newlistings.dta", replace;

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
	
	