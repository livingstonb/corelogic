
#delimit ;

use "${tempdir}/data_deed.dta", clear;

rename apn_unformatted	apn_unf;
rename apn_sequence_number	apn_seq;
rename fips_code fips;
rename recording_date date;

save "${tempdir}/data_deed_cleaned.dta", replace;
