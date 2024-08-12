

/* FHFA developmental 3-digit zip home price index */
#delimit ;
import excel using "${datadir}/fhfa_hpi_at_3zip.xlsx",
	clear cellrange(A5) firstrow;
#delimit cr

gen dateyq = quarterly(string(year)+"-"+string(quarter),"YQ")
format %tq dateyq
drop F G

tempfile hprice
save "`hprice'"

/* Corelogic */
use "${project}/corelogic_queries/merged_8_12_24.dta", clear
tostring property_zipcode, replace
gen zip3 = substr(property_zipcode, 1, 3) if strlen(property_zipcode) == 5
drop if missing(zip3)
destring zip3, force replace


merge m:1 zip3 dateyq using  "`hprice'", nogen keep(1 3) keepusing(pindex)

/* Clean further */
drop if missing(pindex)

* Drop properties that were never resold
bysort fips apn seq: egen ntrans = count(sale_amount)
