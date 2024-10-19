
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
drop apn_unf apn_seq;
drop if missing(propid);
sort propid date;

destring sale_amount, force replace;

duplicates tag propid date if source == "deed", gen(dup);
bysort propid: egen num_dups = max(dup);
drop if (num_dups > 0) & !missing(num_dups);
duplicates drop propid date, force;

/* Get new listings */
order propid date source;
sort propid date;

/* New listing if not listed for 6 months without intervening sale */
bysort propid (date): gen prev_deed = (source[_n-1] == "deed");
bysort propid (date): gen prev_mls = (source[_n-1] == "mls");

bysort propid (date): gen newlisting = 1 if _n == 1;

replace newlisting = 1 if (source == "mls") & prev_deed;
replace newlisting = 1 if (source == "deed") & prev_deed;

bysort propid (date): replace newlisting = 1 if (source == "mls") & prev_mls &
	(date - date[_n-1] > ${new_listing_cutoff});
replace newlisting = 0 if missing(newlisting);

bysort propid (date): gen listing_group = sum(newlisting);

gen mdate = mofd(date);
format %tm mdate;

order propid date sale_amount source fa_closedate fa_offmarketdate
	prev_deed;
	
tab mdate if newlisting;
