
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
		cmas_fips_code as fips,
		cmas_parcel_id as apn,
		cmas_parcel_seq_nbr as apn_seq,
		substring(fa_listdate,8,4) as year,
		CASE substring(fa_listdate,1,3)
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
		fa_listdate as list_date,
		cmas_zip5 as zip,
		fa_propertytype as mls_proptype,
		fa_listid as listing_id,
		fa_rent_sale_ind as rent_sale_ind,
		listingservicename as mls_service_name,
		listingservicenamecode as mls_service_code
	FROM "corelogic-mls".quicksearch_`suffix'
	WHERE 
		(cmas_fips_code = '${singlecounty}')
		AND (substring(fa_listdate, 8, 4) = '`yy'')
		AND (fa_propertytype in `mls_proptype_selections')
		AND (fa_rent_sale_ind='S')
		AND (fa_listdate != '')
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
					"bedrooms",
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
								fips,
								apn,
								apn_seq,
								list_date
							ORDER BY
								listing_id DESC
						) as rownum
				FROM (
					(SELECT
						cmas_fips_code as fips, 
						cmas_parcel_id as apn,
						cmas_parcel_seq_nbr as apn_seq,
						substring(trim(fa_listdate), 1, 4) as year,
						cast(substring(fa_listdate,6,2) as varchar) as month,
						fa_listdate as list_date,
						cmas_zip5 as zip,
						fa_propertytype as mls_proptype,
						fa_listid as listing_id,
						fa_rent_sale_ind as rent_sale_ind,
						listingservicename as mls_service_name,
						listingservicenamecode as mls_service_code
					FROM "corelogic-mls".quicksearch
					WHERE
						(cmas_fips_code = '${singlecounty}')
						AND (substring(trim(fa_listdate), 1, 4) = '`yy'')
						AND (cast(substring(fa_listdate,6,2) as varchar) in `mm')
						AND (fa_propertytype in `mls_proptype_selections')
						AND (fa_rent_sale_ind='S')
						AND (fa_listdate != '')
					)
				`UNION_MLS_SUBQUERIES' )
			),
			
			mls AS (
				SELECT *
				FROM raw_mls
				WHERE (rownum = 1)
					AND (month in `mm')
			),
			
			raw_deed AS (
				SELECT
					"fips code" as fips,
					"apn (parcel number unformatted)" as apn,
					"apn sequence number" as apn_seq,
					"sale derived recording date" as recording_date,
					substring("sale derived recording date", 1, 4) as year,
					substring("sale derived recording date", 5, 2) as month,
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
			),
			
			data AS (
				SELECT fips, apn, apn_seq, year, month,
					list_date, zip, mls_proptype, mls_service_name,
					mls_service_code,
					NULL AS recording_date,
					NULL AS new_construction_ind,
					NULL AS resale_ind,
					NULL AS land_use_code,
					NULL AS buyer1,
					NULL AS buyer2,
					NULL AS seller1,
					NULL AS seller2,
					NULL as sale_amount
				FROM mls 
				UNION
				SELECT fips, apn, apn_seq, year, month,
				    NULL AS list_date,
				    NULL AS zip,
				    NULL AS mls_proptype,
				    NULL AS mls_service_name,
					NULL AS mls_service_code,
				    recording_date, new_construction_ind, resale_ind, 
					land_use_code, buyer1, buyer2, seller1, seller2,
					sale_amount
				FROM deed
			)

		SELECT 	d.fips,
				d.apn,
				d.apn_seq,
				d.year,
				d.month,
				d.list_date,
				d.zip,
				d.sale_amount,
				d.mls_proptype,
				d.mls_service_name,
				d.mls_service_code,
				t.nbaths,
				t.bedrooms,
				t.land_footage
		FROM data as d
		LEFT JOIN tax as t
			ON
				(d.fips = t.fips)
				AND (d.apn = t.apn)
				AND (cast(d.apn_seq as int) = cast(t.apn_seq as int))
		ORDER BY
			d.fips,
			d.apn,
			d.apn_seq,
			d.list_date
	"');
	