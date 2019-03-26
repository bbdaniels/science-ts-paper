*** Produces long panel-data version of LLSOA data: new and cumulative installs for each.

	set more off

* -- Monthly Panel Setup -- *

use "$datadir\Data\CurrentReport.dta", clear

keep if (installtype == 2) | (installtype == .) // Drops 9718 non-domestic installations; keeps domestic installs and LLSOAs only.
drop if (installed_capacity > 50) & (installed_capacity != .) // Drops 6 oversized domestic installations.

generate date = date(commdate,"DMY")

keep if date > date("1/4/2010","DMY") // Drop observations that were transferred in from older incentive schemes.

local x = 1

local old "1/4/2010"
cap gen date = date(commdate,"DMY")

forvalues y = 2010/2013 {

	forvalues m = 1/12 {

		local new "1/`m'/`y'"

		if ( ( date("`new'","DMY") > date("1/4/2010","DMY") ) & ( date("`new'","DMY") < date("1/5/2013","DMY") ) ) {

			gen installations_old`y'`m' = 0

			gen installations_new`y'`m' = 0

			replace installations_old`y'`m' = 1 if ( date < date("`old'","DMY") )

			replace installations_new`y'`m' = 1 if ( date > date("`old'","DMY") & date < date("`new'","DMY") )

			gen month`y'`m' = `x'

			gen time_pre`y'`m'  = 0
			gen time_rush`y'`m' = 0
			gen time_post`y'`m' = 0

			replace time_pre`y'`m'  = 1 if ( date("`new'","DMY") < date("1/11/2011","DMY"))
			replace time_rush`y'`m' = 1 if ( date("`new'","DMY") < date("1/1/2012","DMY") & date("`new'","DMY") >= date("1/11/2011","DMY") )
			replace time_post`y'`m' = 1 if ( time_pre`y'`m' == 0 & time_rush`y'`m' == 0 )

			local ++x

			}

		local old `new'

		}

	}

	collapse (sum) installations* (mean) month* time* , by(llsoa)

	merge m:1 llsoa using "$datadir\Data\llsoadata.dta"

		foreach var of varlist installations_* {
		replace `var' = 0 if `var' == .
		}

	reshape long installations_old installations_new month time_pre time_post time_rush , i(llsoa)

	foreach var of varlist month time_pre time_rush time_post {

		bys _j : egen temp = mean(`var')
		replace `var' = temp if `var' == .
		drop temp

		}

	isid llsoa month, sort

		drop _j

		saveold "$datadir\Data\llsoapaneldatamonthly.dta", replace
