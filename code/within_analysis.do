

/* Zillow developmental 3-digit zip home price index */
#delimit ;
import excel using "${datadir}/zillow_hpi_at_3zip.xlsx",
	clear cellrange(A5) firstrow;
#delimit cr

gen dateyq = quarterly(string(year)+"-"+string(quarter),"YQ")
format %tq dateyq
drop F G

save "${tempdir}/zillow_home_prices.dta", replace

use "${outdir}/merged.dta", clear
