
#delimit ;

use "${tempdir}/data_mls.dta", clear;

rename cmas_parcel_id	apn_unf;
rename cmas_parcel_seq_nbr	apn_seq;
rename cmas_fips_code fips;
rename cmas_zip5 zip5;
rename fa_listdate date;
rename addressstateorprovince state;
rename addresscountyorparish county;
rename addressstreetaddress address;
rename addressunitnumber unit_number;

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
