
#delimit ;
import excel using
	"/Users/akbri/Dropbox/NU/Spring 2024/RA/corelogic/output-mls/zillow_vs_corelogic_06067.xlsx",
		firstrow clear;

#delimit ;
import excel using
	"output-mls/zillow_vs_corelogic_06067.xlsx",
		firstrow clear;
	
twoway (line newlistings_zillow date) (line newlistings_corelogic date)
	if !missing(newlistings_corelogic),
	graphregion(color(white)) bgcolor(white)
	legend(label(1 "Zillow") label(2 "Corelogic"));
	
graph export "output-mls/zillow_v_corelogic_sacramento.png", replace