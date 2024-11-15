

#delimit ;

use "${tempdir}/data_deed_${singlecounty}.dta", clear;
gen source = "deed";

append using  "${tempdir}/data_mls_${singlecounty}.dta";
replace source = "mls" if missing(source);

/* Drop */ #delimit ;
drop trans_batch* new_const* resale* interfam* mls_proptype listing_id
	listing_post_date listing_offmarketdate listing_moddate listing_closedate
	listing_withdrawndate listing_date;

/* Date */
gen year = year(date);
/*
gen month = month(date);
gen qdate = qofd(date);
format %tq qdate;
*/
drop if year == 1800;

sort date;

/* Save */
save "${tempdir}/deed_mls_combined.dta", replace;

#delimit ;
/* Standardize */
use "${tempdir}/deed_mls_combined.dta", clear;

/* Try other housing definitions
drop if inlist(property_indicator_code, "21", "22");
drop if inlist(fa_propertytype, "MF", "RI", "TH");
*/

/* drop if strlen(apn_unf) < 11;
drop if apn_unf == "00000000000";
drop if apn_seq == 0 | missing(apn_seq);
sort fips apn_unf apn_seq date;
*/
drop if missing(apn);
drop if apn == "NOMATCHFORLISTING";


/* Get new listings */ #delimit ;
order fips apn apn_seq date source;
sort fips apn apn_seq date;

/* New listing if not listed for 6 months without intervening sale */
bysort fips apn apn_seq (date): gen prev_deed = (source[_n-1] == "deed");
bysort fips apn apn_seq (date): gen prev_mls = (source[_n-1] == "mls");

bysort fips apn apn_seq (date): gen newlisting = 1 if _n == 1;

replace newlisting = 1 if (source == "mls") & prev_deed;
replace newlisting = 1 if (source == "deed") & prev_deed;

#delimit ;
bysort fips apn apn_seq (date): replace newlisting = 1 if (source == "mls") & prev_mls &
	(date - date[_n-1] > ${new_listing_cutoff});
replace newlisting = 0 if missing(newlisting);

bysort fips apn apn_seq (date): gen listing_group = sum(newlisting);

gen mdate = mofd(date);
format %tm mdate;

/* 
collapse (sum) newlisting, by(mdate fips);
rename newlisting new_listings;
drop if missing(mdate);
*/

save "${outdir}/time_series_corelogic.dta", replace;
