
#delimit ;

if "$singlecounty" != "" {;
	local restrict_county AND (p."fips code" in ('${singlecounty}'));
};

/* Query */
clear;
cap odbc load,
		dsn("SimbaAthena")
		exec(`"
		SELECT
			p."fips code" as fips,
			p."apn (parcel number unformatted)" as apn,
			p."apn sequence number" as apn_seq,
			p."year",
			max(p."situs core based statistical area (cbsa)") as cbsa,
			max(p."situs street address") as street_address,
			max(p."land square footage") as land_square_ft,
			max(p."number of bathrooms") as nbaths,
			max(p."universal building square feet") as building_square_ft,
			max(p."property indicator code") as prop_ind_code,
			max(p."land use code") as land_use_code,
			max(p."situs zip code") as zip
		FROM
			corelogic2.property_history as p
		WHERE (p."property indicator code" in ('10', '11', '20', '22', '21'))
			`restrict_county'
		GROUP BY
			p."fips code",
			p."apn (parcel number unformatted)",
			p."apn sequence number",
			p."year"
		ORDER BY
			p."fips code",
			p."apn (parcel number unformatted)",
			p."apn sequence number",
			p."year"
	"');

cap destring year, force replace;
