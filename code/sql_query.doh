

/*
	Date variable is formatted differently in quicksearch_* tables
than in quicksearch, so have to query these differently. Do this by taking UNION
of these subqueries (local created here) and later UNION this with quicksearch.
*/
#delimit ;

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
		substring(fa_listdate, 5, 2) as day,
		fa_listdate as list_date,
		fa_propertytype as mls_proptype,
		fa_listid as listing_id,
		fa_rent_sale_ind as rent_sale_ind,
		listingservicename as mls_service_name,
		listingservicenamecode as mls_service_code,
		'listing' as entry
	FROM "corelogic-mls".quicksearch_`suffix'
	WHERE 
		(cmas_fips_code = '${chosen_fips}')
		AND (substring(fa_listdate, 8, 4) = '`yy'')
		AND (fa_propertytype in `mls_proptype_selections')
		AND (fa_rent_sale_ind='S')
		AND (fa_listdate != '')
		);
};

/* Query */
odbc load,
		dsn("SimbaAthena")
		exec(`"
		
		WITH
			
			/* TAX TABLES */
			raw_tax AS (
				SELECT
					/* `tsep' is _ in 2018q4, otherwise is space */
					"fips`tsep'code" as fips,
					"apn`tsep'unformatted" as apn,
					"apn`tsep'sequence`tsep'number" as apn_seq,
					"property`tsep'zipcode" as zip,
					"land`tsep'square`tsep'footage" as land_footage,
					"universal`tsep'building`tsep'square`tsep'feet" as building_sq_ft,
					"total`tsep'baths`tsep'calculated" as nbaths,
					"bedrooms",
					"recording`tsep'date" as sale_date_assessor,
					"sale`tsep'amount" as sale_amount_assessor,
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								"fips`tsep'code",
								"apn`tsep'unformatted",
								"apn`tsep'sequence`tsep'number"
							ORDER BY /* determines how to select among duplicates */
								"sale`tsep'amount" DESC
						) as rownum
				FROM corelogic.`tax_table'
				WHERE
					("fips`tsep'code" = '${chosen_fips}')
			),
			
			tax AS (
				SELECT *
				FROM raw_tax
				WHERE (rownum = 1) /* drops duplicates */
			),
			
			/* LISTINGS TABLES */
			raw_mls AS (
				SELECT *,
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								fips,
								apn,
								apn_seq,
								list_date
							ORDER BY /* determines how to select among duplicates */
								listing_id DESC /* not sure if necessary */
						) as rownum
				FROM (
					(SELECT
						cmas_fips_code as fips, 
						cmas_parcel_id as apn,
						cmas_parcel_seq_nbr as apn_seq,
						substring(trim(fa_listdate), 1, 4) as year,
						cast(substring(fa_listdate, 6, 2) as varchar) as month,
						cast(substring(fa_listdate, 9, 2) as varchar) as day,
						fa_listdate as list_date,
						fa_propertytype as mls_proptype,
						fa_listid as listing_id,
						fa_rent_sale_ind as rent_sale_ind,
						listingservicename as mls_service_name,
						listingservicenamecode as mls_service_code,
						'listing' as entry
					FROM "corelogic-mls".quicksearch
					WHERE
						(cmas_fips_code = '${chosen_fips}')
						AND (substring(trim(fa_listdate), 1, 4) = '`yy'')
						AND (cast(substring(fa_listdate,6,2) as varchar) in `mm')
						AND (fa_propertytype in `mls_proptype_selections')
						AND (fa_rent_sale_ind='S')
						AND (fa_listdate != '')
					)
				/* Take union with other quicksearch tables (quicksearch_******) */
				`UNION_MLS_SUBQUERIES' )
			),
			
			mls AS (
				SELECT *
				FROM raw_mls
				WHERE (rownum = 1) /* drops duplicates */
					AND (month in `mm') /* month was not previously filtered subqueries */
			),
			
			/* DEED TABLES */
			raw_deed AS (
				SELECT
					"fips code" as fips,
					"apn (parcel number unformatted)" as apn,
					"apn sequence number" as apn_seq,
					"sale derived recording date" as recording_date,
					substring("sale derived recording date", 1, 4) as year,
					substring("sale derived recording date", 5, 2) as month,
					substring("sale derived recording date", 8, 2) as day,
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
					'sale' as entry,
					ROW_NUMBER() OVER
						(	PARTITION BY /* variables selected for drop duplicates */
								"fips code",
								"apn (parcel number unformatted)",
								"apn sequence number",
								"sale derived recording date"
							ORDER BY /* determines how to select among duplicates */
								"sale amount" DESC
						) as rownum
				FROM
					corelogic2.ownertransfer
				WHERE ("fips code" = '${chosen_fips}')
					AND (substring("sale derived recording date", 1, 4) = '`yy'')
					AND (substring("sale derived recording date", 5, 2) in `mm')
					AND ("primary category code" in ('A'))
					AND ("property indicator code - static" in `deed_proptype_selections')
					AND ("sale amount" > 0)
			),
			
			deed AS (
				SELECT *
				FROM raw_deed
				WHERE (rownum = 1) /* drops duplicates */
			),
			
			/* append listings and deed queries
				- keep variables in same order for both tables
				- use NULL AS if variable does not show up in that table
			*/
			data AS (
				SELECT fips, apn, apn_seq, year, month, day, entry,
					list_date, mls_proptype, mls_service_name,
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
				SELECT fips, apn, apn_seq, year, month, day, entry,
				    NULL AS list_date,
				    NULL AS mls_proptype,
				    NULL AS mls_service_name,
					NULL AS mls_service_code,
				    recording_date, new_construction_ind, resale_ind, 
					land_use_code, buyer1, buyer2, seller1, seller2,
					sale_amount
				FROM deed
			)

		/* merge data subquery just made (listings + deed) with tax tables */
		SELECT 	d.fips,
				d.apn,
				d.apn_seq,
				d.year,
				d.month,
				d.day,
				d.entry,
				d.sale_amount,
				d.mls_proptype,
				d.mls_service_name,
				d.mls_service_code,
				t.zip,
				t.nbaths,
				t.bedrooms,
				t.land_footage,
				t.building_sq_ft,
				t.sale_date_assessor,
				t.sale_amount_assessor
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
	