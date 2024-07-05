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

// use "${tempdir}/corelogic_legacy_merged.dta", clear
