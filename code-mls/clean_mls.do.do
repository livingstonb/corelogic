
#delimit ;

use "${tempdir}/data_mls.dta", clear;

rename cmas_parcel_id	apn_unf;
rename cmas_parcel_seq_nbr	apn_seq;
rename cmas_fips_code fips;
rename cmas_zip5 zip5;
rename fa_listdate date;
rename addressstateorprovince state;
rename addresscountyorparish county;
rename addressstreetaddress address;
rename addressunitnumber unit_number;

save "${tempdir}/data_mls_cleaned.dta", replace;
