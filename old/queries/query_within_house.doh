
#delimit ;

/* Queries deed data within a YYYYMMDD date range */
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
			d."batch seq",
			d."property zipcode",
			d."owner buyer 1 last name",
			d."owner buyer 1 first name & m i",
			d."owner buyer 2 last name",
			d."owner buyer 2 first name & m i",
			d."owner corporate indicator flag",
			d."seller last name",
			d."seller first name"
		FROM
			corelogic.deed as d
		WHERE (d."pri cat code" IN ('A'))
			AND (d."${datevar} date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd2')
			AND (d."mortgage sequence number" is NULL)
			AND (d."property indicator code" in ('10'))
			AND (d."sale amount" > 0)
		ORDER BY
			d."recording date",
			d."fips code",
			d."apn unformatted",
			d."apn sequence number"
	"');
