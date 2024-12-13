

#delimit ;

/* Count sales of distinct properties in each year (e.g. back to 2010 for Sacramento
	county looks good) */
use "${tempdir}/data_final_06067_12_13.dta", clear;
keep if entry == "sale";
duplicates drop fips apn apn_seq year, force;

/* Already no duplicates so counting by anything within fips-year is fine */
collapse (count) total_sales=apn_seq, by(fips year);
label variable total_sales "Year total sales";

/* Rename for future merge */
rename year prev_sale_year;

save "${tempdir}/nsales_for_listing_share_of_sales.dta", replace;

/*
	Identify year in which listed property was previously sold (if < curr year).
	This variable is populated for every 'listing' observation for the given property
	in the selected year. Duplicates will be dropped in collapse.
*/
#delimit ;
use "${tempdir}/data_final_06067_12_13.dta", clear;

gen prev_sale_year = .;
forvalues yselected = 2010/2022 {;
	/*
	Want the previous sale year for listings of given year, but assume all
	sales were also listed. E.g. want to include pocket listings.
	*/
	
	bysort fips apn apn_seq: egen temp1_prev_sale_year = max(year)
		if (entry == "sale") & (year < `yselected');
	by fips apn apn_seq: egen temp2_prev_sale_year = max(temp1_prev_sale_year);
	replace prev_sale_year = temp2_prev_sale_year if (year == `yselected');
	drop temp*_*;
};

duplicates drop fips apn apn_seq prev_sale_year, force;

/* Already no duplicates so counting by anything within fips-year is fine */
collapse (count) total_listings=apn_seq, by(fips year prev_sale_year);
drop if missing(prev_sale_year);
label variable total_listings "Given yr listings last sold x yrs ago";

/* Current year - year last sold */
gen years_since_prev_sale = year - prev_sale_year;

/* Merge in number of sales from transactions file created above */
merge m:1 fips prev_sale_year using "${tempdir}/nsales_for_listing_share_of_sales.dta",
	nogen keep(1 3);
	
	
/* ONLY USING TAX DATA */
#delimit ;
use "${tempdir}/data_final_06067_12_13.dta", clear;
gen prev_sale_year_assessor = year(prev_sale_assessor);

/* Don't think this is right */
duplicates drop fips apn apn_seq prev_sale_year_assessor, force;
collapse (count) total_sales=apn_seq, by(fips prev_sale_year_assessor);
label variable total_sales "Year total sales";

/* Rename for future merge */
rename prev_sale_year_assessor prev_sale_year;
