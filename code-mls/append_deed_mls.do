
#delimit ;

use "${tempdir}/data_deed_cleaned.dta", clear;
gen source = "deed";

append using  "${tempdir}/data_mls_cleaned.dta";
gen source = "mls" if missing(source);

/* Date */
gen strdate = substr(date, 1, 10);
gen ddate = date(strdate, "YMD");
rename ddate date;
format %td date;

gen year = year(date);
gen month = month(date);
gen qdate = qofd(date);
format %tq date;

drop strdate ddate;

/* Save */
save "${tempdir}/deed_mls_combined.dta", replace;
