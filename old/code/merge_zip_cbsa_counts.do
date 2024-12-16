
/* Directories */
global project "~/Dropbox/NU/Spring 2024/RA/corelogic"
global codedir "${project}/code"
global tempdir "${project}/temp"
global outdir "${project}/output"
global datadir "${project}/data"

/* Crosswalk */
#delimit ;
import excel "${datadir}/ZIP_CBSA_032020.xlsx", clear firstrow;
keep if TOT_RATIO > 0.9;
keep ZIP CBSA;
rename ZIP zip;
rename CBSA cbsa;

tempfile zip_cbsa_cwalk;
save "`zip_cbsa_cwalk'", replace;

/* MSA file from paper */
#delimit ;
import delimited "${datadir}/msa_list_mls.csv", clear;
tempfile msa_list_paper;

rename msa cbsa;
tostring cbsa, force replace;
save "`msa_list_paper'", replace;

clear;

local types sales listing;
foreach type of local types {;
	use "${outdir}/`type'_counts.dta", clear;
	merge m:1 zip using "`zip_cbsa_cwalk'", nogen keep(3);
	gen year = substr(date, 1, 4);
	destring year, force replace;

	collapse (sum) `type', by(cbsa year);
	save "${tempdir}/cbsa_`type'_counts.dta", replace;
};

use "${tempdir}/cbsa_deed_counts.dta", clear;
merge 1:1 cbsa year using "${tempdir}/cbsa_listing_counts.dta", nogen keep(1 3);

/* Merge with paper list */
merge m:1 cbsa using "`msa_list_paper'", nogen keep(1 3);
save "${outdir}/cbsa_listings_hstock_counts.dta", replace;
