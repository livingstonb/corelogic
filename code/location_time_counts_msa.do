
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
				floor(d."recording date" / 10000) as year,
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
			INNER JOIN (
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
				) as p
			GROUP BY substring(trim(d."property zipcode"),1,5), floor(d."recording date" / 10000)
			ORDER BY
				substring(trim(d."property zipcode"),1,5),
				floor(d."recording date" / 10000)
		"');

destring year, force replace;
destring sales, force replace;

collapse (sum) sales, by(zip year);
sort zip year;
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
		local year_start_position 1;
	};
	else {;
		local table quicksearch_`suffix';
		local year_start_position 8;
	};

	/* Query */
	odbc load,
			dsn("SimbaAthena")
			exec(`"
			SELECT p."situs core based statistical area (cbsa)" as cbsa,
				substring(d."fa_listdate",`year_start_position',4) as year,
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
			INNER JOIN (
				SELECT DISTINCT ph."tax year",
					ph."apn (parcel number unformatted)",
					ph."apn sequence number",
					ph."situs core based statistical area (cbsa)",
					ph."fips code"
				FROM corelogic2.property_history as ph
				) as p
			ON
				(d."cmas_fips_code" = p."fips code")
				AND (d."cmas_parcel_id" = p."apn (parcel number unformatted)")
				AND (d."cmas_parcel_seq_nbr" = p."apn sequence number")
				AND (cast(substring(d."fa_listdate",`year_start_position',4) as double) = p."tax year")
			GROUP BY substring(d."fa_listdate",`year_start_position',4),
				p."situs core based statistical area (cbsa)"
			ORDER BY
				p."situs core based statistical area (cbsa)",
				substring(d."fa_listdate",`year_start_position',4)
		"');
		
	append using "${outdir}/listing_counts.dta";
	save "${outdir}/listing_counts.dta", replace;
};

rename cmas_zip5 zip;
destring year, force replace;
destring listings, force replace;

collapse (sum) listings, by(zip year);
sort zip year;
keep if strlen(strtrim(zip)) == 5;
drop if strpos(zip, "#") > 0;
drop if strpos(zip, "@") > 0;
drop if strpos(zip, "A") > 0;
drop if strpos(zip, "C") > 0;
drop if strpos(zip, "T") > 0;

save "${outdir}/listing_counts.dta", replace;
