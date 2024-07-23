
use "/Users/brianlivingston/Dropbox/NU/Spring 2024/RA/corelogic/output/merged_7_19_24.dta", clear

gen nbaths = substr(total_baths, 1, 1)
destring nbaths, force replace

gen lamount = log(sale_amount)
gen lbsqft = log(universal_building_square_feet)
gen llsqft = log(land_square_footage)

drop if (land_square_footage < 300) & !missing(land_square_footage)
drop if (nbaths >= 7) & !missing(nbaths)

reg lamount i.quarter i.nbaths lbsqft llsqft, robust
predict resid, residuals

twoway scatter resid dsince_new_con, msize(0.1)
