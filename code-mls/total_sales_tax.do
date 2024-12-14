

global project "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic"

// global project "~/charlie-project/corelogic"
global codedir "${project}/code-mls"
global tempdir "${project}/temp-mls"
global outdir "${project}/output-mls"
global datadir "${project}/data"

#delimit ;

set odbcmgr unixodbc;

local fips 06067;

/* Loop over all quarters */
local query;
forvalues yy = 2015/2022 {;
forvalues qq = 1/4 {;	

	/* Spaces in variables names are underscores in 2018q4 tax tables */
	if (`yy' == 2018) & (`qq' == 4) {;
		local tsep "_";
	};
	else {;
		local tsep " ";
	};

	
	if (`yy' == 2015) & (`qq' == 1) {;
		continue;
	};
	else if (`yy' == 2022) & (`qq' >= 3) {;
		continue, break;
	};
	
	local query `query'
	(
		SELECT DISTINCT
			"fips`tsep'code" as fips,
			"apn`tsep'unformatted" as apn,
			"apn`tsep'sequence`tsep'number" as apn_seq,
			"recording`tsep'date" as sale_date,
			"sale`tsep'amount" as sale_amount
		FROM corelogic.tax_`yy'_q`qq'
		WHERE
			"fips`tsep'code" in ('`fips'')
			AND ("sale`tsep'amount" > 0)
			AND ("property`tsep'indicator`tsep'code" in ('10', '11', '20', '22', '21'))
	);
	
	if (`yy' == 2022) & (`qq' >= 2) {;
		continue, break;
	};
	else {;
		local query `query' UNION;
	};
	
};
};

odbc load,
		dsn("SimbaAthena")
		exec(`"
			WITH raw as (
				SELECT *,
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								fips,
								apn,
								apn_seq
								sale_date
							ORDER BY /* determines how to select among duplicates */
								sale_amount DESC
						) as rownum
					FROM (`query')
				)
				
	SELECT
		COUNT(*) as sales,
		substring(cast(sale_date as varchar), 1, 4) as year
	FROM raw
	WHERE (rownum = 1)
	GROUP BY substring(cast(sale_date as varchar), 1, 4)
			"');
			
save "${tempdir}/total_sales_from_assessor_data.dta", replace;
