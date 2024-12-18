
/* Read file for given fips */
#delimit ;
use "${tempdir}/data_final_${chosen_fips}.dta", clear;

/* Dates */
destring month day year, force replace;
drop if missing(day, month, year);

gen date = mdy(month, day, year);
format %td date;

gen mdate = ym(year, month);
format %tm mdate;

/* Drop special cases and sort */
drop if missing(apn);
drop if apn == "NOMATCHFORLISTING";

/* Clean date of last sale from assessor table */
#delimit ;
replace sale_date_assessor = "" if sale_date_assessor == "0";
replace sale_amount_assessor = "" if sale_amount_assessor == "0";
destring sale_amount_assessor, force;

gen prev_sale_assessor = date(sale_date_assessor, "YMD");
format %td prev_sale_assessor;
drop sale_date_assessor;

/***** Identify new listings *****/
bysort fips apn apn_seq (date): gen prev_deed = (entry[_n-1] == "sale");
bysort fips apn apn_seq (date): gen prev_mls = (entry[_n-1] == "listing");

/* First time a property shows up */
bysort fips apn apn_seq (date): gen newlisting = 1 if _n == 1;

/* If previous appearance of this property was sale, classify as new listing */
replace newlisting = 1 if (entry == "listing") & prev_deed;
replace newlisting = 1 if (entry == "sale") & prev_deed;

/* If previous appearance was listing but more than <cutoff days> prior,
classify as new listing */
#delimit ;
bysort fips apn apn_seq (date): replace newlisting = 1 if (entry == "listing") & prev_mls &
	(date - date[_n-1] > ${new_listing_cutoff});
replace newlisting = 0 if missing(newlisting);
drop prev_mls prev_deed;

/* Sort */
order fips apn apn_seq date mdate entry newlisting;
gsort -date fips apn apn_seq;
