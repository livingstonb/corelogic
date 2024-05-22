
* Load packages
set odbcmgr unixodbc

set trace on
set tracedepth 1

#delimit ;

local first 1;
forvalues yy = 2023/2023 {;
	clear;
	forvalues qq = 1/1 {;
		if (`qq' == 1) {; local mmdd1 0101; local mmdd2 0331; };
		else if (`qq' == 2) 	{; local mmdd1 0401; local mmdd2 0630;};
		else if (`qq' == 3) 	{; local mmdd1 0701; local mmdd2 0930;};
		else 					{; local mmdd1 1001; local mmdd2 1231;};
		
		odbc load,
				dsn("SimbaAthena")
				exec(`"
				SELECT
					d."fips code",
					d."clip",
					d."apn (parcel number unformatted)",
					d."apn sequence number",
					d."archive_date",
					d."sale amount",
					d."new construction indicator",
					d."owner transfer composite transaction id",
					t."sale recording date",
					t."sale date",
					t."situs zip code",
					t."effective year built",
					t."year built",
					t."universal building square feet",
					t."building square feet"
				FROM corelogic2.ownertransfer as d
				LEFT JOIN corelogic2.property_basic as t
					ON (t."clip"=d."clip") AND (t."transaction batch date"=d."transaction batch date")
						AND (t."transaction batch sequence number"=d."transaction batch sequence number")
				WHERE (d."fips code" in ('17031'))
					AND (d."primary category code" IN ('A'))
					AND (cast(d."sale derived date" as bigint) between `yy'`mmdd1' and `yy'`mmdd2')
					AND t."property indicator code" in ('10')
			"');
		rename fips_code fips;
		rename (apn_unformatted apn_sequence_number) (apn seq);
		gen dateyq = quarterly("`yy'Q`qq'","YQ");
		format %tq dateyq

		save "${tempdir}/transactions`yy'Q`qq'", replace;
	};
};
