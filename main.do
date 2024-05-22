clear

global project "~/charlie-project/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"

cd $project
cap mkdir $tempdir
cap mkdir $outdir

* load packages
set odbcmgr unixodbc

do ${codedir}/corelogic2_5-22-24.do
