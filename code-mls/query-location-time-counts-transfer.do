
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
	
/* Query */
odbc load,
			dsn("SimbaAthena")
			exec(`"
			SELECT d."property zipcode",
				substring(d."recording date",1,4) as year,
				count(*) as sales_counts
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
					AND (q."recording date" != '')
					AND (q."mortgage sequence number" is NULL)
					AND (q."sale amount" > 0)
				) as d
			GROUP BY d."cmas_zip5", substring(d."recording date",1,4)
			ORDER BY
				d."property zipcode",
				substring(d."recording date",1,4)
		"');
		
rename property_zipcode zip;
save "${outdir}/deed_counts.dta", replace;