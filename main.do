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
global restrict_fips `"AND (d."fips_code" in ('32003'))"'
set trace on
set tracedepth 3

* main query, deed table merged with tax tables by quarter
do "${codedir}/corelogic_legacy_query.do" `selected_query' `tfirst' `tlast'

* append quarters
do "${codedir}/append_quarters.do" `tfirst' `tlast'

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
gen ddate = date(${datevar}_date, "YMD")
format %td ddate
gen dsince_new_con = ddate - date_new_con

* to conserve space
drop if missing(dsince_new_con)

* sample selection
drop if dsince_new_con < 0
drop if sale_amount < 0

compress
local datestr "`=subinstr("_$S_DATE"," ","_",.)'"
save "${outdir}/merged`datestr'.dta", replace
