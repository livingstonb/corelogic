/*
	Compute relative price changes and plot against time since sale as
	new construction.
*/


cap rename (var12 var14) (owner_buyer_1_frst_name owner_buyer_2_frst_name)

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

/* Deal with duplicates */
duplicates tag fips apn ddate, gen(dup)
drop if dup > 0
drop dup

/* 3-digit zip, which FHFA has in integer format  */
gen zip3 = substr(property_zipcode, 1, 3) if strlen(property_zipcode) == 5
drop if missing(zip3)
destring zip3, force replace

merge m:1 zip3 dateyq using  "`hprice'", nogen keep(3) keepusing(pindex)

/* Clean further */
drop if missing(pindex)
drop if missing(apn)
drop if missing(zip3)

* Property price at new construction sale
gen t_price_new_con = sale_amount if first_sale_new_con
bysort fips apn seq: egen price_new_con = max(t_price_new_con)
drop t_price_new_con

* Index price at new construction sale
gen t_index_new_con = pindex if first_sale_new_con
bysort fips apn seq: egen index_new_con = max(t_index_new_con)
drop t_index_new_con

drop if missing(price_new_con, index_new_con, pindex)

/* Drop properties that have no repeat sales, or an unreasonable number */
bysort fips apn seq: gen ct = _N
drop if (ct == 1) | (ct > 20)
drop ct


* Relative price change
gen xit = (sale_amount / pindex) / (price_new_con / index_new_con)
gen lxit = log(xit)

* Days since sold as new construction bins
gen days_round_100 = ceil(dsince/100)

gen counter = 1

#delimit ;
hist days_round_100, plotregion(color(white))
	xtitle("Days since sold as new construction (in hundreds)");
graph export "${outdir}/counts_bin_100.pdf", replace;

collapse (mean) lxit (sum) counter, by(days_round_100);

save "${outdir}/mean_lxit_100.dta", replace;

#delimit ;
twoway scatter lxit days_round_100,
	plotregion(color(white)) msymbol(Oh)
	xtitle("Days since sold as new construction (in hundreds)")
	ytitle("Mean log adjusted relative price change, log(xit)");
graph export "${outdir}/mean_lxit_100_unwtd.pdf", replace;
#delimit cr

#delimit ;
twoway scatter lxit days_round_100 [weight=counter],
	plotregion(color(white)) msymbol(Oh)
	xtitle("Days since sold as new construction (in hundreds)")
	ytitle("Mean log adjusted relative price change, log(xit)");
graph export "${outdir}/mean_lxit_100_wtd.pdf", replace;
#delimit cr


// #delimit ;
// twoway scatter xit days_round_100,
// 	plotregion(color(white)) msize(tiny)
// 	xtitle("Days since sold as new construction (in hundreds)")
// 	ytitle("Mean adjusted relative price change, xit");
// graph export "${outdir}/mean_xit_100.pdf", replace;
// #delimit cr
