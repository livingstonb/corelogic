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
			d."resale new construction code"
		FROM
			corelogic.deed as d
		WHERE
			(d."fips code" in ('32003'))
			AND (d."pri cat code" IN ('A'))
			AND (d."mortgage sequence number" is NULL)
			AND (d."property indicator code" in ('10'))
			AND (d."resale new construction code" in ('N'))
		ORDER BY
			d."sale date",
			d."fips code",
			d."apn unformatted",
			d."apn sequence number"
	"');
	
rename fips_code fips;
rename (apn_unformatted apn_sequence_number) (apn seq);
gen ddate = date(recording_date, "YMD");
format %td ddate;

gen qdate = qofd(ddate);
format %tq qdate;

gen year = year(ddate);
gen month = month(ddate);

save "${tempdir}/newconstruction.dta", replace;
