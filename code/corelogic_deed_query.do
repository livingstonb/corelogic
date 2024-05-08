
* Load packages
set odbcmgr unixodbc

* Construct unique keys, accounting for changes in APN across quarters
delimit ;

/* Tempfile to help link records across quarters */
/* tempfile previous_record; */

local first 1;
forvalues yy = 2020/2021 {
	clear;
	forvalues qq = 1/4 {
		if (qq == 1) { local mmdd1 0101; local mmdd2 0331; };
		else if (qq == 2) 	{ local mmdd1 0401; local mmdd2 0630;};
		else if (qq == 3) 	{ local mmdd1 0701; local mmdd2 930;};
		else 				{ local mmdd1 1001; local mmdd2 1231;};
		
		odbc load,
			dsn("SimbaAthena")
			exec(`"
				SELECT
					t."fips code",
					t."apn unformatted",
					t."apn sequence number",
					t."sale date"
				FROM
					corelogic.deed as t
				WHERE
					(t."fips code" in ('17031'))
					AND (t."sale date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd1')
				AND
					t."property indicator code" in (
						'10')
				ORDER BY
					t."fips code",
					t."apn unformatted",
					t."apn sequence number"
			);
		rename fips_code fips;
		rename (apn_unformatted apn_sequence_number) (apn seq);
		gen date = quarterly(`yy',`qq');

		if (`qq' == 1) {
			local prevQ "`=`yy'-1'"Q`qq';
		};
		else {
			local prevQ `yy'Q"`=`qq'-1'";
		};
		
		if `first' {
			gen cid = `yy'`apn'`apn_seq';
			local first 0;
		};
		else {
			/* Merge to get unique property id */
			merge 1:1 fips apn seq using ${tempdir}/apn_links/links/`prevQ',
				keepusing(cid);
		};

		/* save `previous_record', replace; */
		save "${tempdir}/transactions`yy'Q`qq'", replace;
	};
};
