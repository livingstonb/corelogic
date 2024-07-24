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

* append quarters
do "${codedir}/append_quarters.do"

* query older transactions data
do "${codedir}/corelogic_new_construction.do"

* merge richer, recent dataset with old transactions
use "${tempdir}/corelogic_combined.dta", clear

#delim ;
merge m:1 fips apn seq using "${tempdir}/deed.dta",
	nogen keep(1 3) force;
#delim cr
// merge m:1 fips apn seq using "${tempdir}/newconstruction.dta", keep(1 3) nogen


#delimit ;
destring fips apn sale_amount batch* year_built
	land_square_footage universal_building_square_feet
	property_zipcode, force replace;
	
foreach var of varlist sale_amount year_built land_square_footage
	universal_building_square_feet property_zipcode {;
	replace `var' = . if (`var' == 0);
};
#delimit cr

* number of days between sale as new construction and given row
gen ddate = date(recording_date, "YMD")
format %td ddate
gen dsince_new_con = ddate - date_new_con

compress
save "${outdir}/merged.dta", replace
