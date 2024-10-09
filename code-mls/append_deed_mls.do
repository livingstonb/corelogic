
#delimit ;

use "${tempdir}/data_deed_cleaned.dta", clear;
gen source = "deed";

append using  "${tempdir}/data_mls_cleaned.dta";
replace source = "mls" if missing(source);

/* Date */
gen strdate = substr(date, 1, 10);
drop date;
gen ddate = date(strdate, "YMD");
rename ddate date;
format %td date;

gen year = year(date);
gen month = month(date);
gen qdate = qofd(date);
format %tq qdate;

drop strdate;

sort date;

/* Save */
save "${tempdir}/deed_mls_combined.dta", replace;


#delimit ;
/* Standardize */
use "${tempdir}/deed_mls_combined.dta", clear;

egen propid = group(fips apn_unf apn_seq);
drop if missing(propid);
sort propid date;

destring sale_amount, force replace;

