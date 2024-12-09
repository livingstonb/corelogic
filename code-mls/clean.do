
#delimit ;

use "${tempdir}/data_final_${singlecounty}.dta", clear;
destring month day year, force replace;
drop if missing(day, month, year);

gen date = mdy(month, day, year);
format %td date;

gen mdate = ym(year, month);
format %tm mdate;

drop if missing(apn);
drop if apn == "NOMATCHFORLISTING";

/* Try other housing definitions
drop if inlist(property_indicator_code, "21", "22");
drop if inlist(fa_propertytype, "MF", "RI", "TH");
*/

/********** Get new listings *******************/ #delimit ;
order fips apn apn_seq date;
sort fips apn apn_seq date;

/* New listing if not listed within cutoff period without intervening sale */
bysort fips apn apn_seq (date): gen prev_deed = (entry[_n-1] == "sale");
bysort fips apn apn_seq (date): gen prev_mls = (entry[_n-1] == "listing");

bysort fips apn apn_seq (date): gen newlisting = 1 if _n == 1;

replace newlisting = 1 if (entry == "listing") & prev_deed;
replace newlisting = 1 if (entry == "sale") & prev_deed;

#delimit ;
bysort fips apn apn_seq (date): replace newlisting = 1 if (entry == "listing") & prev_mls &
	(date - date[_n-1] > ${new_listing_cutoff});
replace newlisting = 0 if missing(newlisting);
drop prev_mls prev_deed;

/*
bysort fips apn apn_seq (date): gen listing_group = sum(newlisting);
*/
