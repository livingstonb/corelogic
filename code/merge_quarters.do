
clear
#delimit ;

local year1 2015;
local year2 2022;
local quarter1 2;
local quarter2 3;

forvalues yy = `year1'/`year2' {;
	forvalues qq = 1/4 {;
		if (`yy' == `year1') & (`qq' < `quarter1') {;
			continue;
		};
		if (`yy' == `year2') & (`qq' > `quarter2') {;
			continue, break;
		};
		
		append using "${tempdir}/transactions`yy'Q`qq'.dta";
		cap gen year =  `yy';
		cap gen quarter = `qq';
		replace year = `yy' if missing(year);
		replace quarter = `qq' if missing(quarter);
	};
};

save "${tempdir}/corelogic_legacy_merged.dta", replace
