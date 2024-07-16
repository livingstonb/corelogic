clear

* Load packages
set odbcmgr unixodbc

#delimit ;
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
			d."batch seq"
		FROM
			corelogic.deed as d
		WHERE
			(d."fips code" in ('32003'))
			AND (d."pri cat code" IN ('A'))
			AND (d."mortgage sequence number" is NULL)
			AND (d."property indicator code" in ('10'))
			AND (d."recording date" <= 20150401)
		ORDER BY
			d."sale date",
			d."fips code",
			d."apn unformatted",
			d."apn sequence number"
	"');
	
rename fips_code fips;
rename (apn_unformatted apn_sequence_number) (apn seq);
gen ddate0 = date(recording_date, "YMD");
format %td ddate0;

gen qdate0 = qofd(ddate0);
format %tq qdate0;
gen dateyq = qdate0;
format %tq dateyq;

gen year = year(ddate0);
gen month = month(ddate0);
gen quarter = quarter(ddate0);

 
keep fips apn seq recording_date sale_date resale_new_construction_code batch*
	year quarter dateyq sale_amount;

save "${tempdir}/newconstruction.dta", replace;
