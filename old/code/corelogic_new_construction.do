/*
	Called from main, after query. This code identifies sales associated with
	new constructions.
*/

#delimit ;

gen ddate = date(${datevar}_date, "YMD");
format %td date;

drop if missing(ddate);

* Get date of first new construction sale */
bysort fips apn seq (ddate):
	gen temp_date_new_con = ddate if (_n == 1) & (resale_new_construction_code == "N");
bysort fips apn seq:
	egen date_new_con = max(temp_date_new_con);
format %td date_new_con;
drop temp_date_new_con;

/* Indicator for when first sale is new construction. Coded this way to allow
duplicates for now. */
bysort fips apn seq (ddate):
	gen first_sale_new_con = (ddate == date_new_con)
		& (resale_new_construction_code == "N");

/* Drop properties where first sale is not new construction */
bysort fips apn seq:
	egen first_sale_is_new_con = max(first_sale_new_con);
keep if first_sale_is_new_con;
drop first_sale_is_new_con;

/* Drop properties with subsequent sales again listed as new construction */
gen later_new_construction_sale
		= (ddate > date_new_con) & (resale_new_construction_code == "N");
bysort fips apn seq:
	egen has_later_new_con_sale = max(later_new_construction_sale);
drop if has_later_new_con_sale;
drop later_new_construction_sale has_later_new_con_sale;

/* Days since sold as new construction */
gen dsince_new_con = ddate - date_new_con;
drop if missing(dsince_new_con);
drop if dsince_new_con < 0

/* Drop properties that have no repeat sales, or an unreasonable number */
by fips apn seq: gen ct = _N;
drop if (ct == 1) | (ct > 20);
drop ct;


drop resale_new_construction_code;

/* Below file will not be used unless possibly a bug terminates code later */
save "${tempdir}/deed.dta", replace;
