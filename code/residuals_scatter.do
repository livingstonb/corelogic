#d;

/*read merged file*/
use "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic/output/merged_7_24_24.dta" if !missing(dsince), clear;

/*bathrooms*/
gen nbaths = substr(total_baths, 1, 1);
destring nbaths, force replace;

/*log sale amount*/
gen lamount = log(sale_amount);

/*log size*/
gen lbsqft = log(universal_building_square_feet);
gen llsqft = log(land_square_footage);

/*drop if (land_square_footage < 300) & !missing(land_square_footage)*/
/*drop if (nbaths >= 7) & !missing(nbaths)*/

/*indicator for new sale*/
gen d0 = (dsince_new_con==0);

/*pool*/
gen has_pool = (pool_flag=="Y");

/*regression*/
reghdfe lamount has_pool nbaths lbsqft llsqft if ~missing(dsince), 
	residuals(resid_hedonic) absorb(i.dateyq##i.property_zip);
	
/*regression for repeat sales*/
/*
egen prop_id = group(fips apn seq);
reghdfe lamount if ~missing(dsince), residuals(resid_rs)
	absorb(i.dateyq##i.property_zip i.prop_id);
*/
	
/*indicator for days by 100s and 30s*/
gen days_round_100 = ceil(dsince/100)*100/365;
gen days_round_30 = ceil(dsince/30)*30/365;
gen counter = 1;

/*collapse and plot*/
foreach x in 30 100 {;
	preserve;
		collapse resid_hedonic (sum) counter if ~missing(dsince), 
			by(days_round_`x');
		label variable days_round "Years since sold as new construction";
		label variable resid "Mean residual in `x'-day bin";
		scatter resid days_round_`x' [weight=counter], 
			msymbol(Oh) graphregion(color(white)) ylabel(, angle(0));
		graph export "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic/output/resid_bin_`x'.pdf", replace;
		keep resid days_round_`x' counter;
		export delimited using
			"/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic/output/data_`x'.csv", replace;
	restore;
};
		
	/*
	twoway
		(scatter resid days_round if days_round<=9) ||
		(lowess resid days_round if days_round<=9 & days_round>1);
	*/

XXX;
/*
preserve;
	gcollapse resid_rs (sum) counter if ~missing(dsince), by(days_round);
	label variable days_round "Years since sold as new construction";
	label variable resid "Mean residual in 100-day bin";
	scatter resid days_round [weight=counter] if days_round<=20, msymbol(Oh);
restore;
*/	
XXX;
