args selected_query tfirst tlast

* Load packages
set odbcmgr unixodbc

#delimit ;

/* Loop over all quarters */

if "`selected_query'" == "query-mls.doh" {;
	local quicksearch_table quicksearch;
	local filename "${tempdir}/data_mls.dta";
	save "`filename'", replace emptyok;
};
else if "`selected_query'" == "query-deed.doh" {;
	local filename "${tempdir}/data_deed.dta";
	save "`filename'", replace emptyok;
};

forvalues yy = 1993/2022 {;
	forvalues qq = 1/4 {;
		clear;
		
		/* Beginning and end dates for the quarter */
		if (`qq' == 1) {; local mmdd1 0101; local mmdd2 0331; };
		else if (`qq' == 2) 	{; local mmdd1 0401; local mmdd2 0630;};
		else if (`qq' == 3) 	{; local mmdd1 0701; local mmdd2 0930;};
		else 					{; local mmdd1 1001; local mmdd2 1231;};
		
		/* Pre-sample period, ignore */
		if (`yy'`mmdd1' < `tfirst') {;
			continue;
		};
		/* Post-sample period, break out of loop */
		if (`yy'`mmdd1' > `tlast') {;
			continue, break;
		};
		
		/* Correct for odd naming convention in 2018q4 tax tables */
		if ("`yy'q`qq'" == "2018q4") {;
			local _s_ "_";
		};
		else {;
			local _s_ " ";
		};
		
		/* Query itself */
		include "${codedir}/queries/`selected_query'";

		if (_N == 0) {;
			di "NO OBSERVATIONS FOR `yy'Q`qq'";
		};
		
		/* These quarterly files will be appended later */
		save "${tempdir}/data`yy'Q`qq'", emptyok replace;
		append using "`filename'";
		save "`filename'", replace emptyok;
		
		
	};
};

if "`selected_query'" == "query-mls.doh" {;
	clear;
	local mmdd 0101 0401 0701 1001;
	forvalues yy = 2019/2022 {;
		foreach val of local mmdd {;
			clear;
			if `yy'`mmdd' < 20190701 {;
				continue;
			};
			else if `yy'`mmdd' > 20220101 {;
				continue, break;
			};
			
			local quicksearch_table quicksearch_`yy'`mmdd';
			include "${codedir}/queries/`selected_query'";
			
			append using "`filename'";
			save "`filename'", replace emptyok;
		};
	};
};
