clear

// global project "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic"

global project "~/charlie-project/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"

cd "$project"
cap mkdir "$tempdir"
cap mkdir "$outdir"

* load packages
set odbcmgr unixodbc

do "${codedir}/corelogic_legacy_query.do"
do "${codedir}/merge_quarters.do"
do "${codedir}/corelogic_legacy_new_construction.do"

use "${tempdir}/corelogic_legacy_merged.dta", clear
// merge m:1 fips apn seq using "${tempdir}/newconstruction.dta", keep(1 3) nogen

append using "${tempdir}/newconstruction.dta", gen(historical) force

#delimit ;
destring fips apn sale_amount batch* year_built
	land_square_footage universal_building_square_feet
	property_zipcode, force replace;
	
foreach var of varlist sale_amount year_built land_square_footage
	universal_building_square_feet property_zipcode {;
	replace `var' = . if (`var' == 0);
};

save "${outdir}/final_output.dta", replace;
