
* load packages
set odbcmgr unixodbc

cap mkdir ${tempdir}/apn_links

* Construct unique keys, accounting for changes in APN across quarters
delimit ;

local first 1;
forvalues yy = 2020/2021 {
	clear;
	forvalues qq = 1/4 {
		odbc load,
			dsn("SimbaAthena")
			exec(`"
				SELECT
					t."fips code",
					t."apn unformatted",
					t."apn sequence number",
					t."previous parcel number",
					t."previous parcel sequence number",
					t."original apn"
				FROM
					corelogic.tax_`yy'q`qq' as t
				WHERE
					t."fips code" in ('17031') AND
					t."previous parcel number" IS NOT NULL
				AND
					t."property indicator code" in (
						'10')
			);
		rename fips_code fips;
		rename (apn_unformatted apn_sequence_number) (apn_curr seq_curr);
		rename (previous_parcel_number previous_parcel_sequence_number) (apn seq);
		rename original_apn apn0;
		
		replace apn = apn_curr if ismissing(apn);
		replace seq = seq_curr if ismissing(seq);
		
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
			gen cid_temp = `yy'`apn'`apn_seq';
			merge 1:1 fips apn seq using ${tempdir}/`prevQ', keepusing(cid);
			replace cid = cid_temp if missing(cid);
			drop apn seq;
			rename (apn_curr seq_curr) (apn seq);
		};
		
		sort fips apn seq;
		order fips apn seq cid;
		save ${tempdir}/apn_links/links/`yy'Q`qq', replace;
		di "APN Links file `yy'Q`qq' saved."
	};
};
