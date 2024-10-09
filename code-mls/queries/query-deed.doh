
#delimit ;

if "$singlecounty" != "" {;
	local restrict_county AND (d."fips code" in ('${singlecounty}'));
};

/* Create local for tax table name */
if  (`yy'`mmdd1' < 20150401) {;
	/* Fix property characteristics for all pre-2015q2 transactions */
	local tax_table tax_2015_q2;
};
else {;
	local tax_table tax_`yy'_q`qq';
};


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
			d."batch seq",
			d."property indicator code",
			d."universal land use code",
			d."owner corporate indicator flag",
			d."document type code",
			d."equity flag code",
			d."inter family flag"
			d."forclosure code",
			d."owner ownership rights code",
			d."residential model indicator flag",
			d."sale code",
			d."transaction type code"
		FROM
			corelogic.deed as d
		WHERE (d."pri cat code" IN ('A'))
			AND (d."${datevar} date" BETWEEN `yy'`mmdd1' AND `yy'`mmdd2')
			AND (d."mortgage sequence number" is NULL)
			AND (d."property indicator code" in ('10', '11', '20', '22', '21'))
			AND (d."sale amount" > 0)
			`restrict_county'
		ORDER BY
			d."sale date",
			d."fips code",
			d."apn unformatted",
			d."apn sequence number"
	"');
