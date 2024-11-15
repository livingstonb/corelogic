

/* Match on correct year */ #delimit ;
merge m:1 fips apn apn_seq year using "${tempdir}/data_assessor_${singlecounty}.dta",
	nogen keep(1 3);
	
/* If no match, match on closest year */
