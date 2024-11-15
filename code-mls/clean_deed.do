
#delimit ;

use "${tempdir}/data_deed_${singlecounty}.dta", clear;

rename recording_date date;

gen strdate = substr(date, 1, 10);
drop date;
gen ddate = date(strdate, "YMD");
rename ddate date;
format %td date;
drop strdate;

save "${tempdir}/data_deed_${singlecounty}.dta", replace;
