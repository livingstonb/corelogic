
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

order fips apn apn_seq date mdate entry newlisting;
gsort -date fips apn apn_seq;

/* Clean date of last sale from assessor table */
#delimit ;
replace sale_date_assessor = "" if sale_date_assessor == "0";
replace sale_amount_assessor = "" if sale_amount_assessor == "0";
destring sale_amount_assessor, force;

gen prev_sale_assessor = date(sale_date_assessor, "YMD");
format %td prev_sale_assessor;
drop sale_date_assessor;
