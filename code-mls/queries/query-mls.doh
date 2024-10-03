
#delimit ;

if $singlecounty {;
	local restrict_county AND (q."cmas_fips_code" in ('32003'));
};

/* Create local for tax table name */
if  (`yy'`mmdd1' < 20150401) {;
	/* Fix property characteristics for all pre-2015q2 transactions */
	local tax_table tax_2015_q2;
};
else {;
	local tax_table tax_`yy'_q`qq';
};

local date1 = "`yy'" + "-" + substr("`mmdd1'",1,2) + "-" + substr("`mmdd1'",3,2);
local date2 = "`yy'" + "-" + substr("`mmdd2'",1,2) + "-" + substr("`mmdd2'",3,2);

local date1 = "'" + "`date1'" + "'";
local date2 = "'" + "`date2'" + "'";

/* Query */
odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT
			q."fa_apn",
			q."cmas_parcel_id",
			q."cmas_parcel_seq_nbr",
			q."cmas_fips_code", 
			q."listingid",
			q."syspropertyid",
			q."addressstateorprovince",
			q."addresscountyorparish",
			q."addressstreetaddress",
			q."addressunitnumber",
			q."cmas_zip5",
			q."fa_listdate",
			q."fa_listid",
			q."listdate",
			q."fa_originallistdate",
			q."originallistdate",
			q."fa_postdate",
			q."modificationtimestamp",
			q."dom",
			q."domcumulative",
			q."leasedate",
			q."fa_closedate",
			q."closedate",
			q."fa_rent_sale_ind",
			q."rentsalelease",
			q."fa_liststatus",
			q."fa_liststatuscategorycode",
			q."fa_iscurrentlisting",
			q."listingstatus",
			t."batch`_s_'id",
			t."batch`_s_'seq",
			t."bedrooms",
			t."total`_s_'baths",
			t."year`_s_'built",
			t."building`_s_'square`_s_'feet",
			t."land`_s_'square`_s_'footage"
		FROM
			"corelogic-mls".quicksearch as q
		INNER JOIN corelogic.`tax_table' as t
			ON (t."FIPS`_s_'CODE"=q."cmas_fips_code")
				AND (t."APN`_s_'UNFORMATTED"=q."fa_apn")
				AND (cast(t."APN`_s_'SEQUENCE`_s_'NUMBER" as bigint)=q."cmas_parcel_seq_nbr")
		WHERE (q."fa_propertytype" in ('SF', 'CN', 'TH'))
			AND (q."fa_rent_sale_ind"='S')
			AND (q."fa_listdate" BETWEEN `date1' AND `date2')
			`restrict_county'
		ORDER BY
			q."fa_listdate",
			q."cmas_fips_code",
			q."cmas_parcel_id",
			q."cmas_parcel_seq_nbr"
	"');
