

/* FHFA developmental 3-digit zip home price index */
#delimit ;
import excel using "${datadir}/fhfa_hpi_at_3zip.xlsx",
	clear cellrange(A5) firstrow;
#delimit cr

gen dateyq = quarterly(string(year)+"-"+string(quarter),"YQ")
format %tq dateyq
drop F G

/* Will merge this into Corelogic dataset */
tempfile hprice
save "`hprice'"

/* Corelogic */
use "${project}/corelogic_queries/merged_8_12_24.dta", clear

/* 3-digit zip, which FHFA has in integer format  */
gen zip3 = substr(property_zipcode, 1, 3) if strlen(property_zipcode) == 5
drop if missing(zip3)
destring zip3, force replace


merge m:1 zip3 dateyq using  "`hprice'", nogen keep(1 3) keepusing(pindex)

/* Clean further */
drop if missing(pindex)
drop if missing(apn)

* Drop properties that were never resold
bysort fips apn seq: egen ntrans = count(sale_amount)
drop if ntrans == 1

* Drop properties resold too many times
drop if ntrans >= 20

* Property price at new construction sale
gen t_price_new_con = sale_amount if first_sale_new_con
bysort fips apn seq: egen price_new_con = max(t_price_new_con)
drop t_price_new_con

* Index price at new construction sale
gen t_index_new_con = pindex if first_sale_new_con
bysort fips apn seq: egen index_new_con = max(t_index_new_con)
drop t_index_new_con

* Relative price change
gen xit = (sale_amount / pindex) / (price_new_con / index_new_con)

* Days since sold as new construction bins
gen days_round_100 = ceil(dsince/100)

#delimit ;
hist days_round_100, plotregion(color(white))
	xtitle("Days since sold as new construction (in hundreds)");
graph export "${outdir}/counts_bin_100.pdf", replace;
collapse (mean) xit, by(days_round_100);
#delimit ;
twoway scatter xit days_round_100,
	plotregion(color(white)) msize(tiny)
	xtitle("Days since sold as new construction (in hundreds)")
	ytitle("Mean adjusted relative price change, xit");
graph export "${outdir}/mean_xit_100.pdf", replace;
#delimit cr
