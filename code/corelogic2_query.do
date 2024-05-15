
* Load packages
set odbcmgr unixodbc

set trace on
set tracedepth 1

#delimit ;

local first 1;
forvalues yy = 2020/2020 {;
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
					d."sale derived recording date",
					d."sale derived date",
					d."property indicator code - static",
					d."actual year built - static",
					d."effective year built - static",
					d."deed situs zip code - static",
					d."transaction fips code",
					d."owner transfer composite transaction id",
					d."source_file",
				FROM corelogic2.ownertransfer as d
				WHERE
					(d."fips code" in ('17031'))
					AND (d."pri cat code" IN ('A'))
					AND (d."sale derived date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd2')
					AND
					d."property indicator code - static" in (
						'10')
				ORDER BY
					d."recording date",
					d."fips code",
					d."clip"
			"');
		rename fips_code fips;
		rename (apn_unformatted apn_sequence_number) (apn seq);
		gen dateyq = quarterly("`yy'Q`qq'","YQ");
		format %tq dateyq

		save "${tempdir}/transactions`yy'Q`qq'", replace;
	};
};
