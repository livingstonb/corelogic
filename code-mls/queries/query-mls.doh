
#delimit ;

/* Create local for tax table name */
if (`yy' <= 2015) & (`qq' < 2) {;
	/* Fix property characteristics for all pre-2015q2 obs */
	local tax_table tax_2015_q2;
};
else if (`yy' >= 2022) & (`qq' > 2) {;
	/* Fix property characteristics for all post-2022q2 obs */
	local tax_table tax_2022_q2;
};
else {;
	local tax_table tax_`yy'_q`qq';
};

/* -- Query notes -- */
/* macro for mls property type codes */
local mls_proptype_selections ('SF', 'CN', 'TH', 'RI', 'MF', 'AP');

/* macro for extra quicksearch tables */
local suffixes 20190701 20191001 20200101 20200401 20200701 20201001
	20210101 20210401 20210701 20211001 20220101;
	
local UNION_MLS_SUBQUERIES;
foreach suffix of local suffixes {;
	local UNION_MLS_SUBQUERIES `UNION_MLS_SUBQUERIES'
	UNION
	(SELECT
		CASE substring(q."fa_listdate",1,3)
			WHEN 'Jan' THEN '01'
			WHEN 'Feb' THEN '02'
			WHEN 'Mar' THEN '03'
			WHEN 'Apr' THEN '04'
			WHEN 'May' THEN '05'
			WHEN 'Jun' THEN '06'
			WHEN 'Jul' THEN '07'
			WHEN 'Aug' THEN '08'
			WHEN 'Sep' THEN '09'
			WHEN 'Oct' THEN '10'
			WHEN 'Nov' THEN '11'
			WHEN 'Dec' THEN '12'
		END as month,
		substring(q."fa_listdate",8,4) as year,
		q."cmas_fips_code" as fips,
		q."cmas_parcel_id" as apn,
		q."cmas_parcel_seq_nbr" as apn_seq,
		q."fa_listdate" as list_date,
		q."fa_propertytype" as mls_proptype,
		q."fa_listid" as listing_id,
		q."fa_rent_sale_ind" as rent_sale_ind,
		q."cmas_zip5" as zip,
		ROW_NUMBER() OVER
			(	PARTITION BY
					q."cmas_fips_code",
					q."cmas_parcel_id",
					q."cmas_parcel_seq_nbr",
					q."fa_listdate"
				ORDER BY
					q."fa_listid" DESC
			) as rownum
	FROM "corelogic-mls".quicksearch_`suffix' as q
	WHERE 
		(q."cmas_fips_code" = '${singlecounty}')
		AND (substring(trim(q."fa_listdate"), 1, 4) = '`yy'')
		AND (substring(trim(q."fa_listdate"), 6, 2) in `mm')
		AND (q."fa_propertytype" in `mls_proptype_selections')
		AND (q."fa_rent_sale_ind"='S')
		AND (q."fa_listdate" != '')
		);
};
/*
- First set up subquery 'tax'
*/

/* Query */
odbc load,
		dsn("SimbaAthena")
		exec(`"
		
		WITH

			raw_tax AS (
				SELECT
					"fips code" as fips,
					"apn unformatted" as apn,
					"apn sequence number" as apn_seq,
					"land square footage" as land_footage,
					"total baths calculated" as nbaths,
					ROW_NUMBER() OVER
						(	PARTITION BY
								"fips code",
								"apn unformatted",
								"apn sequence number"
							ORDER BY
								"land square footage" DESC
						) as rownum
				FROM corelogic.tax_`yy'_q`qq'
				WHERE
					("fips code" = '${singlecounty}')
			),
			
			tax AS (
				SELECT *
				FROM raw_tax
				WHERE (rownum = 1)
			),
			
			raw_mls AS (
				SELECT *,
					ROW_NUMBER() OVER
						(	PARTITION BY
								cmas_fips_code,
								cmas_parcel_id,
								cmas_parcel_seq_nbr,
								fa_listdate
							ORDER BY
								fa_listid DESC
						) as rownum
				FROM
					(SELECT
						cmas_fips_code as fips, 
						cmas_parcel_id as apn,
						cmas_parcel_seq_nbr as apn_seq,
						cmas_zip5 as zip,
						fa_listdate as list_date,
						fa_propertytype as mls_proptype,
						fa_listid as listing_id,
						fa_rent_sale_ind as rent_sale_ind,
						substring(trim("fa_listdate"), 1, 4) as year,
						substring(trim("fa_listdate"), 6, 2) as month
					FROM "corelogic-mls".quicksearch
					WHERE
						(cmas_fips_code = '${singlecounty}')
						AND (substring(trim("fa_listdate"), 1, 4) = '`yy'')
						AND (substring(trim("fa_listdate"), 6, 2) in `mm')
						AND (mls_proptype in `mls_proptype_selections')
						AND (rent_sale_ind='S')
						AND (list_date != '')
					)
				`UNION_MLS_SUBQUERIES'
			),
			
			mls AS (
				SELECT *
				FROM raw_mls
				WHERE (rownum = 1)
			),
			
			raw_deed AS (
				SELECT
					"fips code" as fips,
					"apn (parcel number unformatted)" as apn,
					"apn sequence number" as apn_seq,
					"sale derived recording date" as recording_date,
					"transaction batch date" as trans_batch_date,
					"transaction batch sequence number" as trans_batch_seq,
					"sale derived date" as sale_date,
					"sale amount" as sale_amount,
					"new construction indicator" as new_construction_ind,
					"resale indicator" as resale_ind,
					"land use code - static" as land_use_code,
					"interfamily related indicator" as interfamily,
					"buyer 1 full name" as buyer1,
					"buyer 2 full name" as buyer2,
					"buyer 3 full name" as buyer3,
					"seller 1 full name" as seller1,
					"seller 2 full name" as seller2,
					ROW_NUMBER() OVER
						(	PARTITION BY
								"fips code",
								"apn (parcel number unformatted)",
								"apn sequence number",
								"sale derived recording date"
							ORDER BY
								"sale amount" DESC
						) as rownum
				FROM
					corelogic2.ownertransfer
				WHERE ("fips code" = '${singlecounty}')
					AND (substring("sale derived recording date", 1, 4) = '`yy'')
					AND (substring("sale derived recording date", 5, 2) in `mm')
					AND ("primary category code" in ('A'))
					AND ("property indicator code - static" in ('10', '11', '20', '22', '21'))
					AND ("sale amount" > 0)
			),
			
			deed AS (
				SELECT *
				FROM raw_deed
				WHERE (rownum = 1)
			)

		SELECT *
		FROM mls
		LEFT JOIN tax
			ON
				(mls.fips = tax.fips)
				AND (mls.apn = tax.apn)
				AND (mls.apn_seq = tax.apn_seq)
		ORDER BY
			fips,
			apn,
			apn_seq,
			mls.list_date
	"');
	
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
