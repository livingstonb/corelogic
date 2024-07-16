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

* main query, deed table merged with tax tables from 2015 on, by quarter
do "${codedir}/corelogic_legacy_query.do"

* merge quarters
do "${codedir}/merge_quarters.do"

* query older transactions data
do "${codedir}/corelogic_legacy_new_construction.do"

* merge richer, recent dataset with old transactions
use "${tempdir}/corelogic_legacy_merged.dta", clear
append using "${tempdir}/newconstruction.dta", gen(historical) force
// merge m:1 fips apn seq using "${tempdir}/newconstruction.dta", keep(1 3) nogen


#delimit ;
destring fips apn sale_amount batch* year_built
	land_square_footage universal_building_square_feet
	property_zipcode, force replace;
	
foreach var of varlist sale_amount year_built land_square_footage
	universal_building_square_feet property_zipcode {;
	replace `var' = . if (`var' == 0);
};

save "${outdir}/final_output.dta", replace;
