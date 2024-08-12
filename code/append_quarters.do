args tfirst tlast

if "`tfirst'" == "" {
	local tfirst 20150401
}

local year1  = substr("`tfirst'", 1, 4)
local mmdd1 = substr("`tfirst'", 5, 4)


#delimit ;
if ("`mmdd1'" == "0101") {; local q1 1;};
	else if ("`mmdd1'" == "0401") {; local q1 2;};
	else if ("`mmdd1'" == "0701") {; local q1 3;};
	else if ("`mmdd1'" == "1001") {; local q1 4;};

clear;

forvalues yy = 1993/2022 {;
	forvalues qq = 1/4 {;
		if (`yy'`qq' < `year1'`q1') {;
			continue;
		};
		else if (`yy'`qq' > 20222)  {;
			continue, break;
		};
		
		append using "${tempdir}/transactions`yy'Q`qq'.dta";
	};
};

#delimit ;
cap replace property_zipcode = substr(property_zipcode, 1, 5);

save "${tempdir}/corelogic_combined.dta", replace;
