
/* Same as previous code but taking into account duplicates from quicksearch
updates, to address spike around 2020 */

// global project "~/charlie-project/corelogic"
global project "~/Dropbox/NU/Spring 2024/RA/corelogic"
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
	
/* Deeds query */
odbc load,
			dsn("SimbaAthena")
			exec(`"
			SELECT substring(trim(d."property zipcode"),1,5) as zip,
				floor(d."recording date" / 100) as date,
				count(*) as sales
			FROM (
				SELECT DISTINCT q."property zipcode",
					q."fips code",
					q."apn unformatted",
					q."apn sequence number",
					q."recording date"
				FROM corelogic.deed as q
				WHERE
					(q."property indicator code" in ('10', '11', '20', '22', '21'))
					AND (q."pri cat code" IN ('A'))
					AND (q."recording date" is not NULL)
					AND (q."mortgage sequence number" is NULL)
					AND (q."sale amount" > 0)
				) as d
			GROUP BY substring(trim(d."property zipcode"),1,5), floor(d."recording date" / 100)
			ORDER BY
				substring(trim(d."property zipcode"),1,5),
				floor(d."recording date" / 100)
		"');

destring sales, force replace;

collapse (sum) sales, by(zip date);
gen year = substr(date, 1, 4);
gen month = substr(date, 5, 2);
destring year month, force replace;
drop if month == 0;
gen mdate = ym(year, month);
format %tm mdate;

keep if strlen(strtrim(zip)) == 5;
drop if strpos(zip, "#") > 0;
drop if strpos(zip, "@") > 0;
drop if strpos(zip, "A") > 0;
drop if strpos(zip, "C") > 0;
drop if strpos(zip, "T") > 0;

save "${outdir}/deed_counts.dta", replace;


/* Listings query */
local suffixes 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;
	
local union_subqueries;
foreach suffix of local suffixes {;
	local union_subqueries `union_subqueries'
	UNION
	(SELECT DISTINCT
		CASE substring(q."fa_listdate",1,3)
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
		q."cmas_zip5",
		q."cmas_fips_code",
		q."cmas_parcel_id",
		q."cmas_parcel_seq_nbr",
		substring(q."fa_listdate",8,4) as year
	FROM "corelogic-mls".quicksearch_`suffix' as q
	WHERE
		(q."fa_propertytype" in ('SF', 'CN', 'TH', 'RI', 'MF', 'AP'))
		AND (q."fa_rent_sale_ind"='S')
		AND (q."fa_listdate" != '')
		);
};




	/* Query */
	#delimit ;
clear;
odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT qq."cmas_zip5" as zip,
			year,
			month,
			count(*) as listings
		FROM (
			(SELECT DISTINCT
				cast(substring(q."fa_listdate",6,2) as varchar) as month,
				q."cmas_zip5",
				q."cmas_fips_code",
				q."cmas_parcel_id",
				q."cmas_parcel_seq_nbr",
				substring(q."fa_listdate",1,4) as year
			FROM "corelogic-mls".quicksearch as q
			WHERE
				(q."fa_propertytype" in ('SF', 'CN', 'TH', 'RI', 'MF', 'AP'))
				AND (q."fa_rent_sale_ind"='S')
				AND (q."fa_listdate" != '')
				)
			`union_subqueries'
			) as qq
		GROUP BY qq."cmas_zip5", year, month
	"');

sort zip year month;

/* save "${outdir}/listing_counts.dta", replace */;

destring listings, force replace;

collapse (sum) listings, by(zip year month);

keep if strlen(strtrim(zip)) == 5;
drop if strpos(zip, "#") > 0;
drop if strpos(zip, "@") > 0;
drop if strpos(zip, "A") > 0;
drop if strpos(zip, "C") > 0;
drop if strpos(zip, "T") > 0;

drop if substr(zip, 4, 2) == "00";
gen date = year + month;

destring year month, force replace;
drop if month == 0;
gen mdate = ym(year, month);
format %tm mdate;

drop if year <= 1950;
drop if year > 2025;

save "${outdir}/listing_counts.dta", replace;

#delimit ;
merge 1:1 zip year month using "${outdir}/deed_counts.dta", nogen keep(1 2 3);
sort zip year month;
save "${outdir}/monthly_counts_zip.dta", replace;

/* Merge with USPS crosswalk for zip-CBSA */
#delimit ;
import excel "${datadir}/ZIP_CBSA_032020.xlsx", clear firstrow;
keep if TOT_RATIO > 0.9;
keep ZIP CBSA;
rename ZIP zip;
rename CBSA cbsa;

tempfile zip_cbsa_cwalk;
save "`zip_cbsa_cwalk'", replace;

use "${outdir}/merged_deed_listing_counts_11_17.dta", clear;
merge m:1 zip using "`zip_cbsa_cwalk'", nogen keep(1 2 3);
rename cbsa msa;
collapse (sum) listings sales, by(msa mdate);
save "${outdir}/monthly_counts_msa.dta", replace;