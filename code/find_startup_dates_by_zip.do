clear
 use "${outdir}/merged_deed_listing_counts_11_17.dta"
//  destring year month, replace
drop date
rename mdate date
 destring zip, replace force
// drop date
// gen date = ym(year, month)
// format date %tm
tsset zip date

tssmooth ma listings_ma = listings, window(6 1 5)
tssmooth ma sales_ma = sales, window(6 1 5)

gen pct_ch_sales = (sales_ma - l12.sales_ma) / l12.sales_ma
gen pct_ch_listings = (listings_ma - l12.listings_ma) / l12.listings_ma

// Find the last date at which sales or listings smoothed jump by over 200%
// Taking out the pandemic because there can be weird blips in sales and listings which brian is looking into

egen temporary = max(date) if pct_ch_sales > 1  & date < ym(2021,1), by(zip)
egen max_bad_sales = max(temporary), by(zip)
drop temporary

egen temporary = max(date) if pct_ch_listings > 1 & date < ym(2021,1), by(zip)
egen max_bad_listings = max(temporary), by(zip)
drop temporary

format max_bad_sales max_bad_listings %tm

egen max_sales = max(sales_ma), by(zip)
egen max_listings = max(listings_ma), by(zip)

gen line_bad_listings = (date > max_bad_listings) * max_listings
gen line_bad_sales = (date > max_bad_sales) * max_sales

/*
44022
2445
2138
2118
90049
60202
63935
*/
local zip = 44022
// #delimit ;
// twoway (line listings_ma date, lpattern()) (line sales_ma date)
// 	(line line_bad_listings date) (line line_bad_sales date)
// 		if zip == `zip' & date > ym(1985,1), legend(label(1 "Listings MA") label(2  "Sales MA") label(3 "Listings Good") label(4 "Sales Good") position(6) rows(1)) title("`zip'");

local zips 44022 2445 2138 2118 90049 60202 63935

#delimit ;
local zips
45011	95762	96161	30281	55044	34953	85032	34293	34145	33063	89015	89148	30040	60611	30188	21842	89131	30253	33467	97229	85142	28078	92562	89123	33411	20147	33904	77494	33418	34746	77573	85383	30135	23462	92262	29588	23464	48228	33914	33139	28277	92592	23320	85374	89129	96815	30043	55106	8701	94565	89074	33160	92264	33908	29577	20110	75070	77346	44256	92253	77584	92037	48224	92563	77459	92101	92057	37042	29582	34747	73099	77479	85308	55124	89108	92651	85249	95747	92336	77433	96150	77450	85255	30044	74012	30052	32828	33414	77007	34711	85208	28269	91709	66062	85225	33064	33319	60610	33027	32162	77084	23451	83646	85086	22193	92260	29579	85296	33009	60614	34787	60657;

#delimit ;
cap graph drop p*;
local graphnames p1 p2 p3 p4 p5 p6 p7 p8;
local counter = 1;
local pagenum = 1;
cap putpdf clear;
putpdf begin;

foreach zip of local zips {;
	
	twoway (line listings_ma sales_ma line_bad_listings line_bad_sales date
		if zip == `zip' & date > ym(1985,1),
			lwidth(thick thick) lcolor(edkblue dkorange edkblue dkorange)
			legend(label(1 "Listings MA") label(2  "Sales MA")
				label(3 "Listings Good") label(4 "Sales Good") position(6) rows(2))
			xtitle("") ylabel(, grid ang(h)) tlabel(1990m1 2000m1 2010m1 2020m1)
			tmtick(1990m1 1995m1 2000m1 2005m1 2010m1 2015m1 2020m1, grid)
			title("{bf:`zip'}", size(medium)) graphregion(color(white))
			plotregion(margin(1 1 1 1) lcolor(black)) ),
			name("p`counter'")
			;
	graph close;
	
	if `counter' == 8 {;
	
		/* graph combine `graphnames', col(2); */
		grc1leg2 `graphnames', cols(2) ysize(6) xsize(5.2) graphregion(color(white))
			imargin(small) iscale(.5);
		graph export "${tempdir}/start_dates_temp.png", replace;
		putpdf paragraph, halign(center);
		putpdf image "${tempdir}/start_dates_temp.png";
		putpdf paragraph, halign(right);
		putpdf text ("Page `pagenum'"), bold;
		local pagenum = `pagenum' + 1;
		if `pagenum' == 15 {;
			putpdf save "${tempdir}/start_date_figs.pdf", replace;
			putpdf clear;
			continue, break;
		};
		else {;
			putpdf pagebreak;
			cap graph drop p*;
			local counter = 0;
		};
	};
	local counter = `counter' + 1;
};



