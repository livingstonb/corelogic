
#delimit ;

if "$singlecounty" != "" {;
	local restrict_county AND (d."fips code" in ('${singlecounty}'));
};

/* Query */
cap odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT DISTINCT ON
				(d."fips code" as fips,
				d."apn (parcel number unformatted)" as apn,
				d."apn sequence number" as apn_seq,
				d."transaction batch date" as trans_batch_date,
				d."transaction batch sequence number" as trans_batch_seq)
			d."sale derived date" as sale_date,
			d."sale derived recording date" as recording_date,
			d."sale amount") as sale_amount,
			d."new construction indicator",
			d."resale indicator",
			d."property indicator code - static",
			d."land use code - static",
			d."interfamily related indicator"
		FROM
			corelogic2.deed as d
		WHERE (d."pri cat code" IN ('A'))
			AND (d."sale derived recording date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd2')
			AND (d."property indicator code - static" in ('10', '11', '20', '22', '21'))
			AND (d."sale amount" > 0)
			`restrict_county'
		ORDER BY
			d."sale derived recording date",
			d."fips code",
			d."apn (parcel number unformatted)",
			d."apn sequence number",
			d."transaction batch date",
			d."transaction batch sequence number",
			d."sale amount"
	"');
