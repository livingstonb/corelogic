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
		ORDER BY
			d."recording date",
			d."fips code",
			d."apn unformatted",
			d."apn sequence number"
	"');
	
rename fips_code fips;
rename (apn_unformatted apn_sequence_number) (apn seq);
gen date_new_con = date(recording_date, "YMD");
format %td date_new_con;

bysort fips apn seq (date_new_con):
	keep if (_n == 1) & (resale_new_construction_code == "N");

gen year_new_con = year(date_new_con);
gen month_new_con = month(date_new_con);
gen quarter_new_con = quarter(date_new_con);
 
keep fips apn seq *_new_con;

save "${tempdir}/deed.dta", replace;
