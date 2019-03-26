* Prepares current Feed-in_tariff report as .dta file for merging with economic indicators.

set more off
set trace off

* Current Feed-in_Tariff installation report must be named CurrentReport.csv and placed in the Data folder.

	clear

* Insheet

	insheet using "$datadir/Data/Raw/Feed-in_tariff_installation_report_30_september_2015_p2.csv", c nonames

		tempfile a
			save `a' , replace

	clear

	insheet using "$datadir/Data/Raw/Feed-in_tariff_installation_report_30_september_2015_p1.csv", c nonames

		append using `a'

* Remove header -- make sure that whenever the report is updated we check to make sure the header is the same number of rows.

	drop if v1 == "FIT ID"

* Name and label variables.

	local x = 1

	local labels "FIT ID" "Post Code" "Technology Type" "Installed Capacity (kW)" "Declared Net Capacity (kW)" "Application Date" "Commissioned Date" "Export Status Type" "Tariff Code" "Description" ///
		"Installation Type" "Country Name" "Local Authority" "Government Office Region" "Accreditation No" "Supply MPAN No (first 2 digits)" "Community/School category (Applicable from 01/12/2012)" "LLSOA Code"

	foreach name in "`labels'" {
		local label`x' `name'
		di "`label`x''"
		local ++x
		}

	local x = 1

	foreach name in "fitid" "postcode" "techtype" "installed_capacity" "declared_capacity" "appdate" "commdate" "exstatus" "tariff" "description" "installtype" "country" "localauthority" "gor" "accreditation" "mpan" "category" "llsoa" {
		rename v`x' `name'
		label var `name' "`label`x''"
		local ++x
		}

* Destring and encode

	local destring installed_capacity declared_capacity mpan
	destring `destring', replace

	local encode techtype exstatus tariff description installtype country
	foreach var of varlist `encode' {
		local label : variable label `var'
		encode `var', g(`var'_code) l("`label'")
		}

	compress
	saveold "$datadir/Data/Public/CurrentReport.dta", replace
		use "$datadir/Data/Public/CurrentReport.dta", clear

* match tariffs


	insheet using "${datadir}/Data/Raw/tarifftable2015.csv" ,  clear

		keep if regexm(tariffcode,"PV") & regexm(tariffcode,"0-4")
		keep if fityr == 6
		sort tariffpkwh
		keep tariffcode tariffpkwh
		rename tariffcode tariff

		tempfile tariff
			save `tariff' , replace

	use "$datadir/Data/Public/CurrentReport.dta", replace
	keep if (country == "England" | country == "Wales"  )
		merge m:1 tariff using `tariff' , keep(3) nogen
		/*
		Result                           # of obs.
		-----------------------------------------
		not matched                        61,837
			from master                    61,833  (_merge==1)
			from using                          4  (_merge==2)

		matched                           604,319  (_merge==3) // All domestic PV 0-4kw
		-----------------------------------------
		*/



* Add LLSOA names

	preserve

		insheet using "$datadir/Data/Raw/LowerLADMatching.csv", clear

		drop in 1

		rename v1 llsoa
		rename v2 llsoa_name
		rename v3 llsoa_2011

		collapse (first) llsoa_name, by(llsoa) fast
			label var llsoa "LLSOA"
			label var llsoa_name "LLSOA Name"
			// 34,749 LLSOA – 32,482 in England

			tempfile a
				save `a'

		restore

	merge m:1 llsoa using `a' , nogen keep(3)

* Save

	compress
	order *, alpha


	saveold "$datadir/Data/Public/smalldomesticpv.dta", replace
		use "$datadir/Data/Public/smalldomesticpv.dta", clear
