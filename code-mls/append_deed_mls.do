
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

drop if strlen(apn_unf) < 11;
drop if apn_unf == "00000000000";
egen propid = group(fips apn_unf apn_seq);
drop if missing(propid);
sort propid date;

destring sale_amount, force replace;

duplicates tag propid date if source == "deed", gen(dup);
bysort propid: egen num_dups = max(dup);
drop if (num_dups > 0) & !missing(num_dups);

/* Get new listings */
sort propid date;

/* Time since last listing, without a new sale */
bysort propid (date): gen prev_deed = source[_n-1] === "deed";
bysort propid (date): gen prev_mls = source[_n-1] === "mls";

gen newlisting = 1 if (source == "mls") & prev_deed;
/* Need to do 6 months since new listing, not previous listing ... 
*/


order propid date sale_amount source fa_closedate fa_offmarketdate
	prev_deed;
