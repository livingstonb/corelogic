clear

/* Directories */
// global project "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic"
global project "~/charlie-project/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"
global datadir "${project}/data"

cd "$project"
cap mkdir "$tempdir"
cap mkdir "$outdir"

/* Load packages */
set odbcmgr unixodbc

/* Fips to query */
global chosen_fips "06067"

/* Threshold number of days such that repeat listings are not considered new */
global new_listing_cutoff 180

/* Macro for mls/deed property type codes to include */
local mls_proptype_selections ('SF', 'CN', 'TH', 'RI', 'MF', 'AP');
local deed_proptype_selections ('10', '11', '20', '22', '21');

/* Macro for extra quicksearch tables */
local suffixes 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;

/* Save empty file, append quarter-by-quarter */
clear
local filename "${outdir}/data_final_${chosen_fips}.dta"
save "`filename'", replace emptyok

/* Main queries, loop over quarters */
#delimit ;
forvalues yy = 2006/2024 {;
forvalues qq = 1/4 {;
	clear;

	/* Months in quarter*/		
	if `qq' == 1 {;
		local mm "('01', '02', '03')";
	};
	else if `qq' == 2 {;
		local mm "('04', '05', '06')";
	};
	else if `qq' == 3 {;
		local mm "('07', '08', '09')";
	};
	else if `qq' == 4 {;
		local mm "('10', '11', '12')";
	};
	
	if (`yy' == 2024) & (`qq' >= 3) {;
		continue, break;
	};
	
	/* Create local for tax table name */
	if (`yy' < 2015) | ((`yy' == 2015) & (`qq' < 2)) {;
		/* Fix property characteristics for all pre-2015q2 obs */
		local tax_table tax_2015_q2;
	};
	else if ((`yy' == 2022) & (`qq' > 2)) | (`yy' > 2022) {;
		/* Fix property characteristics for all post-2022q2 obs */
		local tax_table tax_2022_q2;
	};
	else {;
		local tax_table tax_`yy'_q`qq';
	};

	/* Spaces in variables names are underscores in 2018q4 tax tables */
	if (`yy' == 2018) & (`qq' == 4) {;
		local tsep "_";
	};
	else {;
		local tsep " ";
	};
	
	/* ACTUAL QUERY */
	include "${codedir}/sql_query.doh";

	if (_N == 0) {;	
		/* Some sort of bug */
		di "NO OBSERVATIONS FOR `yy'Q`qq'";
	};

	append using "`filename'";
	save "`filename'", replace;
};
};
#delimit cr

* Clean
do "${codedir}/clean.do"
save "`filename'", replace
