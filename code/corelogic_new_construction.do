

/*

clear

* Load packages
set odbcmgr unixodbc


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
			(d."pri cat code" IN ('A'))
			AND (d."mortgage sequence number" is NULL)
			AND (d."property indicator code" in ('10'))
			AND (d."sale amount" > 0)
		ORDER BY
			d."recording date",
			d."fips code",
			d."apn unformatted",
			d."apn sequence number"
	"')
*/
	
#delimit ;

rename fips_code fips;
rename (apn_unformatted apn_sequence_number) (apn seq);

gen ddate = date(${datevar}_date, "YMD");
format %td date;

/* Indicator for when first sale is new construction */
bysort fips apn seq (ddate):
	gen first_sale_new_con = (_n == 1) & (resale_new_construction_code == "N");

/* Drop properties where first sale is not new construction */
bysort fips apn seq:
	egen first_sale_is_new_con = max(first_sale_new_con);
keep if first_sale_is_new_con;
drop first_sale_is_new_con;

/* Drop properties with subsequent sales listed as new construction */
bysort fips apn seq (ddate):
	gen later_new_construction_sale
		= (_n > 1) & (resale_new_construction_code == "N");
bysort fips apn seq:
	egen has_later_new_con_sale = max(later_new_construction_sale);
drop if has_later_new_con_sale;
drop later_new_construction_sale has_later_new_con_sale;

/* Get date of first new construction sale */
bysort fips apn seq (ddate):
	gen temp_date_new_con = ddate if (_n == 1);
bysort fips apn seq:
	egen date_new_con = first(temp_date_new_con);
format %td date_new_con;
drop temp_date_new_con;

/* Days since sold as new construction */
gen dsince_new_con = ddate - date_new_con;
drop if missing(dsince_new_con);
drop if dsince_new_con < 0;

gen year_new_con = year(date_new_con);
gen month_new_con = month(date_new_con);
gen quarter_new_con = quarter(date_new_con);
 
keep fips apn seq *_new_con;

compress;
save "${tempdir}/deed.dta", replace;
