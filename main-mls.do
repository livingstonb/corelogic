clear

// global project "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic"

global project "~/charlie-project/corelogic"
global codedir "${project}/code-mls"
global tempdir "${project}/temp-mls"
global outdir "${project}/output-mls"
global datadir "${project}/data"

cd "$project"
cap mkdir "$tempdir"
cap mkdir "$outdir"

* load packages
set odbcmgr unixodbc

* config
local tfirst 20000101
local tlast 20220630
global datevar recording
global singlecounty "37045"
global new_listing_cutoff 180

set trace on
/* 
set tracedepth 1
*/

* main query, listings (mls)
do "${codedir}/corelogic_legacy_query.do" "query-mls.doh" `tfirst' `tlast'
do "${codedir}/corelogic_legacy_query.do" "query-deed.doh" `tfirst' `tlast'

* clean
do "${codedir}/clean_mls.do"
do "${codedir}/clean_deed.do"

* append and standardize
do "${codedir}/append_deed_mls.do"


/* append quarters
do "${codedir}/append_quarters.do" `tfirst' `tlast' */

/*


* clean according to new construction indicator
do "${codedir}/corelogic_new_construction.do"

#delimit ;
local vars sale_amount year_built
	land_square_footage universal_building_square_feet;
foreach var of local vars  {;
	/* Some of these variables may not exist/were not queried */
	cap destring `var', force replace;
};
	
local vars sale_amount year_built land_square_footage
	universal_building_square_feet;
foreach var of local vars {;
	/* Some of these variables may not exist/were not queried */
	cap replace `var' = . if (`var' == 0);
};
#delimit cr

local datestr "`=subinstr("_$S_DATE"," ","_",.)'"
save "${outdir}/merged`datestr'.dta", replace
*/
