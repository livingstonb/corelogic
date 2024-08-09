clear

// global project "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic"

global project "~/charlie-project/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"
global datadir "${project}/data"

cd "$project"
cap mkdir "$tempdir"
cap mkdir "$outdir"

* load packages
set odbcmgr unixodbc

* config
local tfirst 19930101
local tlast 20220630
local selected_query query_within_house.doh
global datevar recording
set trace on
set tracedepth 3

* main query, deed table merged with tax tables by quarter
do "${codedir}/corelogic_legacy_query.do" `selected_query' `tfirst' `tlast'

* append quarters
do "${codedir}/append_quarters.do" `tfirst' `tlast'

do "${codedir}/corelogic_new_construction.do"

#delimit ;
local vars fips apn sale_amount batch* year_built
	land_square_footage universal_building_square_feet
	property_zipcode;
foreach var of local vars  {;
	cap destring `var', force replace;
};
cap destring , force replace;
	
local vars sale_amount year_built land_square_footage
	universal_building_square_feet property_zipcode;
foreach var of local vars {;
	cap replace `var' = . if (`var' == 0);
};
#delimit cr

compress
local datestr "`=subinstr("_$S_DATE"," ","_",.)'"
save "${outdir}/merged`datestr'.dta", replace
