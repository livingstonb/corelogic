clear
 use "${outdir}/monthly_counts_msa_11_26.dta"
rename mdate date
drop if date < ym(1970, 1)

destring msa, replace force
tsset msa date

tssmooth ma listings_ma = listings, window(6 1 5)
tssmooth ma sales_ma = sales, window(6 1 5)

gen pct_ch_sales = (sales_ma - l12.sales_ma) / l12.sales_ma
gen pct_ch_listings = (listings_ma - l12.listings_ma) / l12.listings_ma

// Find the last date at which sales or listings smoothed jump by over 200%
// Taking out the pandemic because there can be weird blips in sales and listings which brian is looking into

egen temporary = max(date) if pct_ch_sales > 1  & date < ym(2021,1), by(msa)
egen max_bad_sales = max(temporary), by(msa)
drop temporary

egen temporary = max(date) if pct_ch_listings > 1 & date < ym(2021,1), by(msa)
egen max_bad_listings = max(temporary), by(msa)
drop temporary

format max_bad_sales max_bad_listings %tm

egen max_sales = max(sales_ma), by(msa)
egen max_listings = max(listings_ma), by(msa)

gen line_bad_listings = (date > max_bad_listings) * max_listings
gen line_bad_sales = (date > max_bad_sales) * max_sales

gen temp_sales_gt_listings = sales > listings if !missing(sales, listings) ///
	& (date > max_bad_listings) & (date > max_bad_sales)
// egen NN = count(temp_sales_gt_listings), by(zip)
// replace temp_sales_gt_listings = temp_sales_gt_listings / NN
egen share_sales_gt_listings = mean(temp_sales_gt_listings), by(msa)
drop temp_sales_gt_listings

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
local msas
31080
35620
16980
19820
33100
38060
26420
47900
40140
33460
37980
19100
12060
42660
41860
14460
41740
45300
38900
41180
17460
17140
40900
16740
12580
19740
36740
47260
18140
28140
29820
12420
39300
38300
15980
33340
27260
31140
41940
46060
36420
14860
40060
46140
34820
35840
13820
25540
19660
35380
19430
49340
10420
46520
34940
38940
14260
37100
35300
12540
10580
10900
22220
44700
40380
12940
44140
45780
15380
49180
24660
30460
42220
39900
12700
22420
46700
29460
41540
33700
21340
49660
22660
39100
15940
36100
11700
21660
18580
29620
27140
29540
33860
31700
45060
14500
48900
25940
11460
33660
37460
16300
37340
36500
42020
39460
29420
35980
12100
42340
14740
43340
;

#delimit ;
cap graph drop p*;
local graphnames p1 p2 p3 p4 p5 p6 p7 p8;
local counter = 1;
local pagenum = 1;
cap putpdf clear;
putpdf begin;

foreach msa of local msas {;

	quietly sum share_sales_gt_listings if msa == `msa';
	local share_bad = r(max);
	if 	`share_bad' > 0.85 {;
		local dropped ", DROPPED";
	};
	else {;
		local dropped;
	};
	
	
	twoway (line listings_ma sales_ma line_bad_listings line_bad_sales date
		if msa == `msa' & date > ym(1985,1),
			lwidth(thick thick) lcolor(edkblue dkorange edkblue dkorange)
			legend(label(1 "Listings MA") label(2  "Sales MA")
				label(3 "Listings Good") label(4 "Sales Good") position(6) rows(2))
			xtitle("") ylabel(, grid ang(h)) tlabel(1990m1 2000m1 2010m1 2020m1)
			tmtick(1990m1 1995m1 2000m1 2005m1 2010m1 2015m1 2020m1, grid)
			title("{bf:`msa' (sale > list = `share_bad')`dropped'}", size(medium)) graphregion(color(white))
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



