
#delimit ;

use "${tempdir}/data_mls.dta", clear;

cap rename cmas_zip5 zip5;
cap rename fa_listdate date;
cap rename addressstateorprovince state;
cap rename addresscountyorparish county;
cap rename addressstreetaddress address;
cap rename addressunitnumber unit_number;

/* Date */
gen strdate = substr(date, 1, 10) if table == "quicksearch";
replace strdate = subinstr(strdate, "-", "", .) if table == "quicksearch";
gen ddate = date(strdate, "YMD") if table == "quicksearch";
format %td ddate;

drop strdate;
gen strdate = substr(date, 1, 11) if table != "quicksearch";
replace ddate = date(strdate, "MDY") if table != "quicksearch";
drop date strdate;
rename ddate date;

drop if missing(date);

save "${tempdir}/data_mls_cleaned.dta", replace;
