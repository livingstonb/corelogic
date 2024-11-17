

/* Try to match on same year first. If no match, match on closest year. */
#delimit ;
gen orig_year = year;
gen assessor_year_used = .;
forvalues yy = 0/15 {;
	replace year = orig_year + yy if missing(assessor_year_used);
	merge m:1 fips apn apn_seq year using "${tempdir}/data_assessor_${singlecounty}.dta",
		update keep(1 3 4);
	replace assessor_year_used = orig_year + yy if inlist(_merge, 3, 4);
	drop _merge;
};
drop year;
rename orig_year year;
