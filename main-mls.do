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
global chosen_fips "06067"
global new_listing_cutoff 180

set trace on
/* 
set tracedepth 1
*/

/* Main queries */
#delimit ;
clear;
local filename "${tempdir}/data_final_${chosen_fips}.dta";
save "`filename'", replace emptyok;

/* Loop over all quarters */
forvalues yy = 2006/2024 {;
forvalues qq = 1/4 {;
	clear;
	
	if (`yy' == 2024) & (`qq' >= 3) {;
		continue, break;
	};
	
	do "${codedir}/query_one_quarter.do" `yy' `qq';
	append using "`filename'";
	save "`filename'", replace;
};
};
#delimit cr

* clean
do "${codedir}/clean.do"

save "`filename'", replace
