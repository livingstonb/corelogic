args yy qq

* Load packages
set odbcmgr unixodbc

#delimit ;

/* Loop over all quarters */

local quicksearch_table quicksearch;
local filename "${tempdir}/data_mls_${chosen_fips}.dta";
local month_expr;
		
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

/* -- tax table variable names have underscores in 2018q4 -- */

if (`yy' == 2018) & (`qq' == 4) {;
	local tsep "_";
};
else {;
	local tsep " ";
};

/* macro for mls/deed property type codes */
local mls_proptype_selections ('SF', 'CN', 'TH', 'RI', 'MF', 'AP');
local deed_proptype_selections ('10', '11', '20', '22', '21');

/* macro for extra quicksearch tables */
local suffixes 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;
		
/* Query itself */
include "${codedir}/sql_query.doh";

if (_N == 0) {;
	di "NO OBSERVATIONS FOR `yy'Q`qq'";
};
