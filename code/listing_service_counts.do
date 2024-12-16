/*
	Constructs table of listing counts at the zip-month-service level.
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

/* Prepare HUD-USPS crosswalk for zip-CBSA */
#delimit ;
import excel "${datadir}/ZIP_CBSA_032020.xlsx", clear firstrow;
keep if TOT_RATIO > 0.9;
keep ZIP CBSA;
rename ZIP zip;
rename CBSA msa;

tempfile zip_cbsa_cwalk;
save "`zip_cbsa_cwalk'", replace;

/*
	Local to construct string that will union over different quicksearch
	tables in query. Date format is different than corelogic-mls.quicksearch
*/
local suffixes 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;
local union_subqueries;
foreach suffix of local suffixes {;
	local union_subqueries `union_subqueries'
	UNION
	(SELECT DISTINCT
		CASE substring("fa_listdate",1,3)
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
		"cmas_zip5",
		"cmas_fips_code",
		"cmas_parcel_id",
		"cmas_parcel_seq_nbr",
		"listingservicename",
		substring("fa_listdate",8,4) as year
	FROM "corelogic-mls".quicksearch_`suffix'
	WHERE
		("fa_propertytype" in ('SF', 'CN', 'TH', 'RI', 'MF', 'AP'))
		AND ("fa_rent_sale_ind"='S')
		AND ("fa_listdate" != '')
		);
};

/* Actual query */
#delimit ;
clear;
odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT "cmas_zip5" as zip,
			year,
			month,
			listingservicename as service,
			count(*) as listings
		FROM /* Union of quicksearch* tables */
			(
				(SELECT DISTINCT /* Drop duplicates along all variables below */
					cast(substring("fa_listdate",6,2) as varchar) as month,
					"cmas_zip5",
					"cmas_fips_code",
					"cmas_parcel_id",
					"cmas_parcel_seq_nbr",
					"listingservicename",
					substring("fa_listdate",1,4) as year
				FROM "corelogic-mls".quicksearch
				WHERE
					("fa_propertytype" in ('SF', 'CN', 'TH', 'RI', 'MF', 'AP'))
					AND ("fa_rent_sale_ind"='S')
					AND ("fa_listdate" != '')
				) /* Now union with quicksearch_******** tables */
				`union_subqueries'
			)
		GROUP BY "cmas_zip5", listingservicename, year, month
	"');

/* Clean */
cap destring listings, force replace;
collapse (sum) listings, by(zip year month service);
keep if strlen(strtrim(zip)) == 5;
drop if strpos(zip, "#") > 0;
drop if strpos(zip, "@") > 0;
drop if strpos(zip, "A") > 0;
drop if strpos(zip, "C") > 0;
drop if strpos(zip, "T") > 0;
drop if substr(zip, 4, 2) == "00" | missing(zip);

gen date = year + month;

destring year month, force replace;
drop if month == 0;
gen mdate = ym(year, month);
format %tm mdate;

drop if year <= 1950;
drop if year > 2025;

/* Merge in MSA and save */
merge m:1 zip using "`zip_cbsa_cwalk'", nogen keep(1 2 3);

sort zip service mdate;
destring zip, force replace;

save "${outdir}/listing_service_counts.dta", replace;
