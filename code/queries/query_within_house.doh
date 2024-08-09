
#delimit ;

/* Query */
cap odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT
			d."fips code",
			d."apn unformatted",
			d."apn sequence number",
			d."recording date",
			d."sale date",
			d."sale amount",
			d."resale new construction code",
			d."batch id",
			d."batch seq"
		FROM
			corelogic.deed as d
		WHERE (d."pri cat code" IN ('A'))
			AND (d."${datevar} date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd2')
			AND (d."mortgage sequence number" is NULL)
			AND (d."property indicator code" in ('10'))
			AND (d."sale amount" > 0)
			${restrict_fips}
		ORDER BY
			d."sale date",
			d."fips code",
			d."apn unformatted",
			d."apn sequence number"
	"');
