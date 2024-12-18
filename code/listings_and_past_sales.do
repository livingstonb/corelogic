/*
	Attempt at computing listings in year t divided by total sales in year
	t - k.
	Output "${tempdir}/nsales_for_listing_share_of_sales.dta" is current progress
	of this code
*/

/* Directories */
// global project "~/charlie-project/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"
global datadir "${project}/data"

cap mkdir ${tempdir}
cap mkdir ${outdir}

#delimit ;
local chosen_fips 06067;

/* Count sales of distinct properties in each year using sales rows
(these rows come from deed tables) */
use "${outdir}/data_final_`chosen_fips'.dta", clear;
keep if entry == "sale";

/* Select distinct properties */
duplicates drop fips apn apn_seq year, force;

gen total_sales = 1;
collapse (count) total_sales, by(fips year);
label variable total_sales "Year total sales";

/* Rename for future merge */
rename year prev_sale_year;

save "${tempdir}/nsales_by_year.dta", replace;

/*
	Now for each listing, identify year in which listed property was previously
	sold (assuming < curr year). This variable is populated for every 'listing' observation
	for the given property in the selected year. Duplicates will be dropped in collapse.
*/
#delimit ;
use "${outdir}/data_final_`chosen_fips'.dta", clear;

gen prev_sale_year = .;
forvalues yselected = 2010/2022 {;
	/*
	Want the previous sale year for listings of given year, and treat all sales
	as listings. E.g. want to include pocket listings.
	*/
	
	bysort fips apn apn_seq: egen temp1_prev_sale_year = max(year)
		if (entry == "sale") & (year < `yselected');
	by fips apn apn_seq: egen temp2_prev_sale_year = max(temp1_prev_sale_year);
	replace prev_sale_year = temp2_prev_sale_year if (year == `yselected');
	drop temp*_*;
};

duplicates drop fips apn apn_seq prev_sale_year, force;

/* Now count total listings  */
collapse (count) total_listings=apn_seq, by(fips year prev_sale_year);
drop if missing(prev_sale_year);
label variable total_listings "Given yr listings last sold x yrs ago";

/* Current year - year last sold */
gen years_since_prev_sale = year - prev_sale_year;

/* Merge in number of sales from transactions file created above */
merge m:1 fips prev_sale_year using "${tempdir}/nsales_by_year.dta",
	nogen keep(1 3);

rename total_sales totsales_in_prev_sale_yr;
sort fips year totsales_in_prev_sale_yr;

save "${outdir}/listings_and_past_sales.dta", replace;
	
	