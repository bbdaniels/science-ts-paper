*** Compresses data to LLSOA-level dataset.
/*
* Add tariff rates

	insheet using "${datadir}/Data/tarifftable2015.csv" ,  clear
	
		isid tariffcode fityr, sort
		bys tariffcode: egen check = max(fityr)
			keep if check == fityr
		keep tariffcode tariffpkwh
		rename tariffcode tariff
	
	tempfile a
	save `a', replace
	
* Open installations + Census dataset to end up with (installations + LLSOAs without installations).
	
	use "$datadir/Data/masterdata.dta", clear

	merge m:1 tariff using `a' , keep(1 3) nogen
	
	
    /* 	Result                           # of obs.
    	-----------------------------------------
    	not matched                         3,487
    	    from master                     3,289  (_merge==1) : LSOAs without installations
   	    	from using                        198  (_merge==2) : Unused tariffs
	
   		matched                           342,547  (_merge==3) : All installations matched
   		----------------------------------------- */

*/	
* Generate community totals by LSOA
/*
	keep if installtype == 2
	rename installed_capacity community_capacity
	gen community_installs = 1
	
	collapse (sum) community_capacity (count) community_installs, by(llsoa)
	
	label var community_capacity "Community Capacity"
	label var community_installs "Community Installations"
	
	merge 1:m llsoa using "$datadir/Data/masterdata.dta" /*
		Result                           # of obs.
		-----------------------------------------
		not matched                         3,680
			from master                         0  (_merge==1)
			from using                      3,680  (_merge==2)

		matched                           342,156  (_merge==3)
		----------------------------------------- */
		
	replace community_capacity = 0 if community_capacity == .
	replace community_installs = 0 if community_installs == .
*/
/*
* Infill missing GOR data.

	replace gor = "Wales" if country == 4
	
	encode gor, g(temp)
	drop gor
	egen temp2 = mean(temp), by(lad)
		replace temp=temp2
		drop temp2
	rename temp gor
		label var gor "Government Office Region"
*/		
* Tag urban local authorites ("London" and "Metro" from http://en.wikipedia.org/wiki/Local_government_in_England and those labelled "City" by http://en.wikipedia.org/wiki/List_of_Welsh_principal_areas_by_population)

use "$datadir/Data/Public/installs_lsoas.dta", clear

	gen urban = 0
	
	#delimit ;
	
	local urban `" 
		"City of London" "Barking and Dagenham" "Barnet" "Bexley" "Brent" 
		"Bromley" "Camden" "Croydon" "Ealing" "Enfield" "Greenwich" "Hackney" 
		"Hammersmith and Fulham" "Haringey" "Harrow" "Havering" "Hillingdon"
		"Hounslow" "Islington" "Kensington and Chelsea" "Kingston upon Thames"
		"Lambeth" "Lewisham" "Merton" "Newham" "Redbridge" "Richmond upon Thames"
		"Southwark" "Sutton" "Tower Hamlets" "Waltham Forest" "Wandsworth" "Westminster"
		"Bolton" "Bury" "Manchester" "Oldham" "Rochdale" "Salford" "Stockport" "Tameside"
		"Trafford" "Wigan"
		"Knowsley" "Liverpool" "Sefton" "St. Helens" "Wirral"
		"Barnsley" "Doncaster" "Rotherham" "Sheffield"
		"Gateshead" "Newcastle upon Tyne" "North Tyneside" "South Tyneside" "Sunderland"
		"Birmingham" "Coventry" "Dudley" "Sandwell" "Solihull" "Walsall" "Wolverhampton"
		"Bradford" "Calderdale" "Kirklees" "Leeds" "Wakefield"
		"Cardiff" "Swansea" "Newport" "'
		;
		
	#delimit cr
		
	qui foreach name in `urban' {
		replace urban = 1 if lad == "`name'"
		}
		
	
	
	 gen date = date(appdate,"DMY")
		format date %tddd_Mon_CCYY
		
	gen income = installed_capacity * tariffpkwh
		label var income "Maximum Hourly Income"
		
	gen tariff_rate = tariff
		label var tariff_rate "Tariff"
		
	
	
	/* Drop non-domestic installs and installations over 50kW.

		preserve

		keep if installed_capacity != . // Drops 9718 non-domestic installations; keeps domestic installs and LLSOAs only. 
	
		
		
		save "$datadir/Data/pv_install_data.dta", replace
			use "$datadir/Data/pv_install_data.dta", clear
			
		restore
	*/

* Collapse data to LLSOA-level.

#delimit ;
	
	local mean "
		area density density_hh population urban country households malepct
		eng_all hh_rooms hh_bedrooms hh_unshared
		hh_lifestage_1 hh_lifestage_5 hh_lifestage_9 hh_lifestage_13
		hh_detached hh_semidetached hh_terrace hh_flat hh_converted hh_commercial
		ind_b ind_c ind_d ind_f
		own_own own_mortgage own_landlord own_council own_other hh_nosecond
		social_ab social_c1 social_c2 social_de
		hh_dep_0 hh_dep_1 hh_dep_2 hh_dep_3 hh_dep_4
		hh_heat_0 hh_heat_2
		work_unemp " ;
		
#delimit cr

	drop if llsoa == ""
	
	gen n_installs = declared_capacity != .
		
	labelcollapse	(firstnm) `mean' /// all values should be identical within llsoa for these vars, and also the mean tariff is calculated here
				(sum)	declared_capacity installed_capacity income n_installs /// capacity variable totals
				(firstnm) lad gor ///
		, by(llsoa) fast
	
	gen tariff = income / installed_capacity
		label var tariff "Average tariff per kWh (pence)"
		
	replace income = 0 if income == .
	replace installed_capacity = 0 if income == .
	
* Label variables

	label var tariff		"Average Tariff Rate"
	label var area 			"Area"
	label var density 		"Density (people/hectare)"
	label var population	"Population"
	label var urban 		"Urban?"
	label var country 		"Country"
	label var malepct		"% Male"
	label var hh_unshared	"% households with unshared dwelling"
	label var eng_all 		"% households where everyone speaks English"
	label var hh_rooms 		"mean rooms/household"
	label var hh_bedrooms 	"mean bedrooms/household"
	label var hh_lifestage_1 "% households with Age of HRP under 35: Total"
	label var hh_lifestage_5 "% households with Age of HRP 35 to 54: Total"
	label var hh_lifestage_9 "% households with Age of HRP 55 to 64: Total"
	label var hh_lifestage_13 "% households with Age of HRP 65+: Total"
	label var hh_detached 	"% hh Detatched House"
	label var hh_semidetached "% hh semi-detached house"
	label var hh_terrace 	"% hh terraced house"
	label var hh_flat 		"% hh flats" 
	label var hh_converted 	"% hh converted flats"
	label var hh_commercial "% hh flats in commercial buildings"
	label var households 	"# of households"
	label var ind_b 		"% people in B Mining and quarrying"
	label var ind_c			"% people in C Manufacturing"
	label var ind_f 		"% people in F Construction"
	label var ind_d			"% people in D Electricity, gas, steam and air conditioning supply"
	label var own_own 		"% hh Owned: Owned outright" 
	label var own_mortgage 	"% hh Owned: Owned with a mortgage or loan"
	label var own_landlord	"% hh Rented: Landlord or Agency"
	label var hh_nosecond	"% hh with no second address"
	label var social_ab		"% people Social grade AB"
	label var social_c1		"% people Social grade C1"
	label var social_c2		"% people Social grade C2"
	label var social_de		"% people Social grade DE"
	label var hh_dep_0		"% hh deprived in 0 dimensions"
	label var hh_dep_1		"% hh deprived in 1 dimensions"
	label var hh_dep_2		"% hh deprived in 2 dimensions"
	label var hh_dep_3		"% hh deprived in 3 dimensions"
	label var hh_dep_4		"% hh deprived in 4 dimensions"
	label var hh_heat_0		"% hh with no central heating"
	label var hh_heat_2		"% hh with electric central heating"
	label var work_unemp	"% people Unemployed"
	label var declared_capacity "Total declared capacity (kW)"
	label var installed_capacity "Total installed capacity (kW)"
		label var n_installs "Total number of installations"
	gen own = own_own + own_mortgage
		label var own 		"% hh owned"
	gen rent = own_council + own_landlord + own_other
		label var rent		"% hh rented"
	label var lad			"Local Authority"
	label var llsoa			"LLSOA (2001 Codes)"
	label var llsoa_name	"LLSOA Name (2001)"

* Save and export datasets

	saveold "$datadir/Constructed/analysis_llsoa.dta", replace
		use "$datadir/Constructed/analysis_llsoa.dta", replace
/*	
	outsheet using "$datadir\GIS\llsoaen.txt" if country==1, comma replace
	outsheet using "$datadir\GIS\llsoawa.txt" if country==4, comma replace
