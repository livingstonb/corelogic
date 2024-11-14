
#delimit ;

if "$singlecounty" != "" {;
	local restrict_county AND (d."fips code" in ('${singlecounty}'));
};

/* Query */
cap odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT DISTINCT
			d."fips code" as fips,
			d."apn (parcel number unformatted)" as apn,
			d."apn sequence number" as apn_seq,
			d."transaction batch date" as trans_batch_date,
			d."transaction batch sequence number" as trans_batch_seq,
			min(d."sale derived date") as sale_date,
			min(d."sale derived recording date") as recording_date,
			min(d."sale amount") as sale_amount,
			min(d."new construction indicator"),
			min(d."resale indicator"),
			min(d."property indicator code - static"),
			min(d."land use code - static"),
			min(d."interfamily related indicator")
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
			d."transaction batch sequence number"
	"');
