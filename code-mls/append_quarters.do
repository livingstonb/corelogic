args tfirst tlast

if "`tfirst'" == "" {
	local tfirst 20150401
}

/* Infer year and date */
local year1  = substr("`tfirst'", 1, 4)
local mmdd1 = substr("`tfirst'", 5, 4)

/* Infer first quarter */
#delimit ;
if ("`mmdd1'" == "0101") {; local q1 1;};
	else if ("`mmdd1'" == "0401") {; local q1 2;};
	else if ("`mmdd1'" == "0701") {; local q1 3;};
	else if ("`mmdd1'" == "1001") {; local q1 4;};
clear;

forvalues yy = 1993/2022 {;
	forvalues qq = 1/4 {;
		
		if (`yy'`qq' < `year1'`q1') {;
			/* Pre-sample period, ignore */
			continue;
		};
		else if (`yy'`qq' > 20222)  {;
			/* Post-sample period, break out of loop */
			continue, break;
		};

		cap append using "${tempdir}/data`yy'Q`qq'.dta";
	};
};

#delimit ;

/* Below file will not be used unless possibly a bug terminates code later */
save "${tempdir}/corelogic_combined.dta", replace;
