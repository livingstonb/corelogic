


global project "~/charlie-project/corelogic"
global codedir "${project}/code-mls"
global tempdir "${project}/temp-mls"
global outdir "${project}/output-mls"
global datadir "${project}/data"

cd "$project"
cap mkdir "$tempdir"
cap mkdir "$outdir"

set odbcmgr unixodbc

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
			SELECT d."cmas_zip5",
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
			GROUP BY d."cmas_zip5", substring(d."fa_listdate",`year_start_position',4)
			ORDER BY
				d."cmas_zip5",
				substring(d."fa_listdate",`year_start_position',4)
		"');
		
	append using "${outdir}/listing_counts.dta";
	save "${outdir}/listing_counts.dta", replace;
};

rename cmas_zip5 zip;
save "${outdir}/listing_counts.dta", replace;
