args include_sales_before_2015

if "`include_sales_before_2015'" == "" {
	local include_sales_before_2015 0
}

* Load packages
set odbcmgr unixodbc

#delimit ;

if `include_sales_before_2015' {;
	local year1 1993;
	local tfirst 19930101
else{;
	local year1 2015;
	local tfirst 20150401
};

local year2 2022;
local tlast 20220930

forvalues yy = `year1'/`year2' {;
	forvalues qq = 1/4 {;
		clear;
		
		if (`qq' == 1) {; local mmdd1 0101; local mmdd2 0331; };
		else if (`qq' == 2) 	{; local mmdd1 0401; local mmdd2 0630;};
		else if (`qq' == 3) 	{; local mmdd1 0701; local mmdd2 0930;};
		else 					{; local mmdd1 1001; local mmdd2 1231;};
		
		if (`yy'`mmdd1' < tfirst) {;
			continue;
		};
		
		if (`yy'`mmd2' > tlast) {;
			continue, break;
		
		if ("`yy'q`qq'" == "2018q4") {;
			local _s_ "_";
		};
		else {;
			local _s_ " ";
		};
		
		if (`yy'`mmdd1' < 20150401) {;
			local tax_table tax_2015_q2;
		};
		else {;
			local tax_table tax_`yy'_q`qq';
		;};
		
		cap odbc load,
				dsn("SimbaAthena")
				exec(`"
				SELECT
					d."fips code",
					d."apn unformatted",
					d."apn sequence number",
					d."recording date",
					d."sale date",
					d."sale amount",
					d."resale new construction code",
					d."batch id",
					d."batch seq",
					t."year`_s_'built",
					t."land`_s_'square`_s_'footage",
					t."universal`_s_'building`_s_'square`_s_'feet",
					t."property`_s_'zipcode",
					t."bedrooms",
					t."total`_s_'baths",
					t."total`_s_'baths`_s_'calculated",
					t."construction`_s_'type`_s_'code",
					t."exterior`_s_'walls`_s_'code",
					t."fireplace`_s_'number",
					t."parking`_s_'spaces",
					t."pool`_s_'flag",
					t."quality`_s_'code",
					t."stories`_s_'number",
					t."units`_s_'number",
					t."view"
				FROM
					corelogic.deed as d
				INNER JOIN corelogic.`tax_table' as t
				ON (t."FIPS`_s_'CODE"=d."FIPS CODE")
					AND (t."APN`_s_'UNFORMATTED"=d."APN UNFORMATTED")
					AND (cast(t."APN`_s_'SEQUENCE`_s_'NUMBER" as bigint)=d."APN SEQUENCE NUMBER")
				WHERE
					 (d."pri cat code" IN ('A'))
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
		format %tq dateyq;

		save "${tempdir}/transactions`yy'Q`qq'", replace;
	};
};
