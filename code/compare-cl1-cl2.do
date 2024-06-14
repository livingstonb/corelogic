
clear

#delimit ;
import delimited "${project}/downloads/corelogic2-query-5-22-24.csv",
	clear varnames(1);
duplicates drop *, force;


#delimit ;
import delimited "${project}/downloads/corelogic-query-5-22-24.csv",
	clear varnames(1);
duplicates drop *, force;
