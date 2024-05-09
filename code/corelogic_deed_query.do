
* Load packages
set odbcmgr unixodbc

// 
* Construct unique keys, accounting for changes in APN across quarters
#delimit ;

/* Tempfile to help link records across quarters */
/* tempfile previous_record; */
/* dsn("SimbaAthena") */

local first 1;
forvalues yy = 2021/2021 {;
	clear;
	forvalues qq = 4/4 {;
		if (`qq' == 1) {; local mmdd1 0101; local mmdd2 0331; };
		else if (`qq' == 2) 	{; local mmdd1 0401; local mmdd2 0630;};
		else if (`qq' == 3) 	{; local mmdd1 0701; local mmdd2 930;};
		else 					{; local mmdd1 1001; local mmdd2 1231;};
		
		odbc load,
				dsn("SimbaAthena")
				exec(`"
				SELECT
					d."fips code",
					d."apn unformatted",
					d."apn sequence number",
					d."recording date",
					d."sale date",
					d."sale amount",
					t."year built",
					t."land square footage",
					t."universal building square feet",
					t."property zipcode"
				FROM
					corelogic.deed as d
				INNER JOIN corelogic.tax_2020_q1 as t
				ON (t."FIPS CODE"=d."FIPS CODE")
					AND (t."APN UNFORMATTED"=d."APN UNFORMATTED")
					AND (cast(t."APN SEQUENCE NUMBER" as bigint)=d."APN SEQUENCE NUMBER")
				WHERE
					(d."fips code" in ('17031'))
					AND (t."sale date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd1')
				AND
					t."property indicator code" in (
						'10')
				ORDER BY
					d."recording date"
					d."fips code",
					d."apn unformatted",
					d."apn sequence number"
			"');
		rename fips_code fips;
		rename (apn_unformatted apn_sequence_number) (apn seq);
		gen dateyq = quarterly(`yy',`qq');


		/* save `previous_record', replace; */
		save "${tempdir}/transactions`yy'Q`qq'", replace;
	};
};
