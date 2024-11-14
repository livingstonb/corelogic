
global project "~/charlie-project/corelogic"
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
				floor(d."sale date" / 100) as date,
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
			GROUP BY substring(trim(d."property zipcode"),1,5), floor(d."sale date" / 100)
			ORDER BY
				substring(trim(d."property zipcode"),1,5),
				floor(d."sale date" / 100)
		"');

destring sales, force replace;

collapse (sum) sales, by(zip date);
sort zip date;
keep if strlen(strtrim(zip)) == 5;
drop if strpos(zip, "#") > 0;
drop if strpos(zip, "@") > 0;
drop if strpos(zip, "A") > 0;
drop if strpos(zip, "C") > 0;
drop if strpos(zip, "T") > 0;

save "${outdir}/deed_counts.dta", replace;


/* Listings query */
#delimit ;
clear;

local table_suffixes NONE 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;

save "${outdir}/listing_counts.dta", emptyok replace;
foreach suffix of local table_suffixes {;
	clear;

	if "`suffix'" == "NONE" {;
		local table quicksearch;
		local yearexpr substring(d."fa_listdate",1,4);
		local monthexpr substring(d."fa_listdate",6,2);
	};
	else {;
		local table quicksearch_`suffix';
		local yearexpr substring(d."fa_listdate",8,4);
		local monthexpr substring(d."fa_listdate",1,3);
	};

	/* Query */
	odbc load,
			dsn("SimbaAthena")
			exec(`"
			SELECT d."cmas_zip5" as zip,
				`yearexpr' as year,
				`monthexpr' as month,
				count(*) as listings
			FROM (
				SELECT DISTINCT q."cmas_zip5",
					q."cmas_fips_code",
					q."cmas_parcel_id",
					q."cmas_parcel_seq_nbr",
					q."fa_listdate"
				FROM "corelogic-mls".`table' as q
				WHERE
					(q."fa_propertytype" in ('SF', 'CN', 'TH', 'RI', 'MF', 'AP'))
					AND (q."fa_rent_sale_ind"='S')
					AND (q."fa_listdate" != '')
				) as d
			GROUP BY d."cmas_zip5", `yearexpr', `monthexpr'
		"');
	
	sort zip year month;
	
	gen table = "`table'";
	append using "${outdir}/listing_counts.dta";
	save "${outdir}/listing_counts.dta", replace;
};

gen date = year + "01" if month == "Jan";
replace date = year + "02" if month == "Feb";
replace date = year + "03" if month == "Mar";
replace date = year + "04" if month == "Apr";
replace date = year + "05" if month == "May";
replace date = year + "06" if month == "Jun";
replace date = year + "07" if month == "Jul";
replace date = year + "08" if month == "Aug";
replace date = year + "09" if month == "Sep";
replace date = year + "10" if month == "Oct";
replace date = year + "11" if month == "Nov";
replace date = year + "12" if month == "Dec";
replace date = year + month if table == "quicksearch";
drop table;

destring listings, force replace;

collapse (sum) listings, by(zip date);

sort zip date;
keep if strlen(strtrim(zip)) == 5;
drop if strpos(zip, "#") > 0;
drop if strpos(zip, "@") > 0;
drop if strpos(zip, "A") > 0;
drop if strpos(zip, "C") > 0;
drop if strpos(zip, "T") > 0;

drop if substr(zip, 4, 2) == "00";
drop if substr(date, 5, 2) == "00";
drop if substr(date, 1, 2) == "18";
drop if substr(date, 1, 3) == "190";

gen year = substr(date, 1, 4);
gen month = substr(date, 5, 2);
replace date = year + "/" + month;

save "${outdir}/listing_counts.dta", replace;
#delimit ;
merge 1:1 zip date using "${outdir}/deed_counts.dta", nogen keep(1 2 3);
save "${outdir}/merged_deed_listing_counts.dta", replace;
