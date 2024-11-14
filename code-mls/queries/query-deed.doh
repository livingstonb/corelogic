
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
			max(d."new construction indicator"),
			max(d."resale indicator"),
			max(d."property indicator code - static"),
			max(d."land use code - static"),
			max(d."interfamily related indicator")
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
