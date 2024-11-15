
#delimit ;

if "$singlecounty" != "" {;
	local restrict_county AND (q."cmas_fips_code" in ('${singlecounty}'));
};

/*
local date1 = "`yy'" + "-" + substr("`mmdd1'",1,2) + "-" + substr("`mmdd1'",3,2);
local date2 = "`yy'" + "-" + substr("`mmdd2'",1,2) + "-" + substr("`mmdd2'",3,2);

if "`quicksearch_table'" == "quicksearch" {;
	local restrict_date AND (q."fa_listdate" BETWEEN '`date1'' AND '`date2'');
};
else {;
	local restrict_date;
};


/* Create local for tax table name */
if  (`yy'`mmdd1' < 20150401) {;
	/* Fix property characteristics for all pre-2015q2 transactions */
	local tax_table tax_2015_q2;
};
else {;
	local tax_table tax_`yy'_q`qq';
};
*/


/*
local date1 = "'" + "`date1'" + "'";
local date2 = "'" + "`date2'" + "'";
*/

/* Query */
odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT
			q."cmas_fips_code" as fips, 
			q."cmas_parcel_id" as apn,
			q."cmas_parcel_seq_nbr" as apn_seq,
			q."fa_listdate" as list_date,
			max(q."fa_propertytype") as mls_proptype,
			max(q."fa_listid") as listing_id,
			max(q."fa_originallistdate") as orig_listing_date,
			max(q."fa_postdate") as listing_post_date,
			max(q."modificationtimestamp") as listing_moddate,
			max(q."fa_offmarketdate") as listing_offmarketdate,
			max(q."fa_closedate") as listing_closedate,
			max(q."withdrawndate") as listing_withdrawndate
		FROM
			"corelogic-mls".`quicksearch_table' as q
		WHERE (q."fa_propertytype" in ('SF', 'CN', 'TH', 'RI', 'MF', 'AP'))
			AND (q."fa_rent_sale_ind"='S')
			AND (q."fa_listdate" != '')
			`restrict_county'
		GROUP BY
			q."cmas_fips_code",
			q."cmas_parcel_id",
			q."cmas_parcel_seq_nbr",
			q."fa_listdate"
		ORDER BY
			q."cmas_fips_code",
			q."cmas_parcel_id",
			q."cmas_parcel_seq_nbr",
			q."fa_listdate"
	"');
	
cap gen table = "`quicksearch_table'";

/*

			t."bedrooms",
			t."total`_s_'baths",
			t."year`_s_'built",
			t."building`_s_'square`_s_'feet",
			t."land`_s_'square`_s_'footage",
			t."batch`_s_'id",
			t."batch`_s_'seq"
			
FULL OUTER JOIN corelogic.`tax_table' as t
	ON (t."FIPS`_s_'CODE"=q."cmas_fips_code")
		AND (t."APN`_s_'UNFORMATTED"=q."cmas_parcel_id")
		AND (cast(t."APN`_s_'SEQUENCE`_s_'NUMBER" as bigint)=q."cmas_parcel_seq_nbr")
*/
