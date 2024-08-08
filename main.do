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

* set option for whether to include sales prior to 2015
local include_sales_before_2015 1

* main query, deed table merged with tax tables by quarter
do "${codedir}/corelogic_legacy_query.do" `include_sales_before_2015'

* append quarters
do "${codedir}/append_quarters.do" `include_sales_before_2015'

* query older transactions data
do "${codedir}/corelogic_new_construction.do"

* merge richer, recent dataset with old transactions
use "${tempdir}/corelogic_combined.dta", clear

#delim ;
merge m:1 fips apn seq using "${tempdir}/deed.dta",
	nogen keep(1 3) force;
#delim cr

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

* conserve space
drop if missing(dsince_new_con)

* drop if above is negative (should only matter if include_sales_before_2015 = 1)
drop if dsince_new_con < 0

compress
local datestr "`=subinstr("_$S_DATE"," ","_",.)'"
save "${outdir}/merged`datestr'.dta", replace
