args selected_query yy qq

* Load packages
set odbcmgr unixodbc

#delimit ;

/* Loop over all quarters */

local quicksearch_table quicksearch;
local filename "${tempdir}/data_mls_${singlecounty}.dta";
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
		
/* Query itself */
include "${codedir}/queries/`selected_query'";

if (_N == 0) {;
	di "NO OBSERVATIONS FOR `yy'Q`qq'";
};
