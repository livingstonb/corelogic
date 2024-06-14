
* Load packages
set odbcmgr unixodbc

#delimit ;

local year1 2015 
local year2 2022
local quarter1 2
local quarter2 3
forvalues yy = `year1'/`year2' {;
	clear;
	forvalues qq = 1/4 {;
		if (`qq' == 1) {; local mmdd1 0101; local mmdd2 0331; };
		else if (`qq' == 2) 	{; local mmdd1 0401; local mmdd2 0630;};
		else if (`qq' == 3) 	{; local mmdd1 0701; local mmdd2 930;};
		else 					{; local mmdd1 1001; local mmdd2 1231;};
		
		if (`yy' == `year1') & (`qq' < `quarter1') {;
			continue;
		};
		
		if (`yy' == `year2') & (`qq' > `quarter1') {;
			continue, break;
		};
		
		odbc load,
				dsn("SimbaAthena")
				exec(`"
				SELECT
					d."fips code",
					d."apn unformatted",
					d."apn sequence number",
					d."recording date",
					d."sale amount",
					d."resale new construction code",
					d."batch id",
					d."batch seq",
					t."year built",
					t."land square footage",
					t."universal building square feet",
					t."property zipcode"
				FROM
					corelogic.deed as d
				INNER JOIN corelogic.tax_`yy'_q`qq' as t
				ON (t."FIPS CODE"=d."FIPS CODE")
					AND (t."APN UNFORMATTED"=d."APN UNFORMATTED")
					AND (cast(t."APN SEQUENCE NUMBER" as bigint)=d."APN SEQUENCE NUMBER")
				WHERE
					(d."fips code" in ('32003'))
					AND (d."pri cat code" IN ('A'))
					AND (d."sale date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd2')
					AND (d."mortgage sequence number" is NULL)
					AND (d."property indicator code" in ('10'))
				ORDER BY
					d."sale date",
					d."fips code",
					d."apn unformatted",
					d."apn sequence number"
			"');
		rename fips_code fips;
		rename (apn_unformatted apn_sequence_number) (apn seq);
		gen dateyq = quarterly("`yy'Q`qq'","YQ");
		format %tq dateyq

		save "${tempdir}/transactions`yy'Q`qq'", replace;
	};
};
