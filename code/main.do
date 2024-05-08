clear

global project "~/charlie-project"
global tempdir "${project}/temp"
global outdir "${project}/output"

cd $project
cap mkdir $tempdir
cap mkdir $outdir

* load packages
set odbcmgr unixodbc

do construct_apn_links.do
