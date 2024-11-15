
#delimit ;

if "$singlecounty" != "" {;
	local restrict_county AND (d."fips code" in ('${singlecounty}'));
};

/* Query */
cap odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT
			d."fips code" as fips,
			d."apn (parcel number unformatted)" as apn,
			d."apn sequence number" as apn_seq,
			d."transaction batch date" as trans_batch_date,
			d."transaction batch sequence number" as trans_batch_seq,
			max(d."sale derived date") as sale_date,
			max(d."sale derived recording date") as recording_date,
			max(d."sale amount") as sale_amount,
			max(d."new construction indicator") as new_construction_ind,
			max(d."resale indicator") as resale_ind,
			max(d."land use code - static") as land_use_code,
			max(d."interfamily related indicator") as interfamily,
			max(d."buyer 1 full name") as buyer1,
			max(d."buyer 2 full name") as buyer2,
			max(d."buyer 3 full name") as buyer3,
			max(d."seller 1 full name") as seller1,
			max(d."seller 2 full name") as seller2
		FROM
			corelogic2.ownertransfer as d
		WHERE (d."primary category code" IN ('A'))
			AND (d."property indicator code - static" in ('10', '11', '20', '22', '21'))
			AND (d."sale amount" > 0)
			`restrict_county'
		GROUP BY
			d."fips code",
			d."apn (parcel number unformatted)",
			d."apn sequence number",
			d."transaction batch date",
			d."transaction batch sequence number"
		ORDER BY
			d."fips code",
			d."apn (parcel number unformatted)",
			d."apn sequence number",
			d."transaction batch date",
			d."transaction batch sequence number"
	"');
