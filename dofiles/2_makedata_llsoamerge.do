** Master statistics merge file

clear all
/*
* Create base LLSOA guide for correcting 2001-labeled observations in installs dataset.

	insheet using "$datadir/CensusMatchingData/LowerLADMatching.csv", clear
	
	drop in 1
	
	keep v1 v3 v7
	
	rename v1 llsoa01
	rename v3 llsoa
	rename v7 lad

* Code merge shorthand

	cap prog drop get
		prog define get
			syntax name, [Pct] [Norm] vars(numlist) varnames(namelist) labels(string)
qui {			
			* Save base file
				tempfile x
				save `x', replace
				clear
				
			* Open merge file
			
				insheet using "$mergedir/`namelist'/`namelist'DATA.CSV", nonames
				
			* Drop first row (labels)
				
				drop in 1
			
			* Merge onto master file, drop unused items from merge file, drop merge variable
				
				rename v1 llsoa
				
				local n : word count `vars'
				
				local varnums "v2"
				
				forvalues i = 1/`n' {
					local nextnum : word `i' of `vars'
					local varnums "`varnums' v`nextnum'"
					}
				
				keep llsoa `varnums'
				merge 1:m llsoa using `x'
					keep if _m==3
					drop _m
					
			* Collapse to correct for changes in LLSOAs
			
				foreach var of varlist v* {
					destring `var', replace
					egen temp= mean(`var'), by(llsoa01)
					drop `var'
					rename temp `var'
					}

			* Count number of variables, then name and label
			
				destring v2, replace
				
				forvalues i = 1/`n' {
				
					local a : word `i' of `vars'
					local b : word `i' of `varnames'
					local c : word `i' of `labels'

					replace v`a' = (v`a'/100) if "`norm'"=="norm"
					replace v`a' = (v`a'/v2)  if "`pct'"=="pct"
					
					rename v`a' `b'
					label var `b' "`c'"
					
					}
					
				cap drop v2					

}				
		end

* Begin merges

get KS101EW,	vars(8 9) ///
				varnames(area density) ///
				labels(`""Area (Hectares)" "Density (persons/hectare)""')

get KS101EW,	vars(10 11 12) n ///
				varnames(malepct femalepct householdpct) ///
				labels(`""% Male" "% Female" "% in households""')
				
get KS101EW,	vars(2) ///
				varnames(population) ///
				labels(`""Total population""')
				
get KS102EW,	vars(21(1)36) n ///
				varnames(a04 a57 a89 a1014 a15 a1617 a1819 a2024 a2529 a3044 a4559 a6064 a6574 a7584 a8589 a90) ///
				labels(`""% aged 0-4" "% aged 5-7" "% aged 8-9" "% aged 10-14" "% aged 15" "% aged 16-17" "% aged 18-19" "% aged 20-24" "% aged 25-29" "% aged 30-44" "% aged 45-59" "% aged 60-64" "% aged 65-74" "% aged 75-84" "% aged 85-89" "% aged 90+""')

get KS106EW,	vars(9 10) n ///
				varnames(unemp_child unemp_nochild) ///
				labels(`""% Households with no employed persons, with children" "% Households with no employed persons, no children""')

get KS201EW,	vars(21(1)38) n ///
				varnames(eth_british eth_irish eth_gypsy eth_whiteother eth_whitecarib eth_whiteaf eth_whiteasian eth_othermix eth_indian eth_pakistani eth_bangladeshi eth_chinese eth_asian eth_african eth_carib eth_black eth_arab eth_other) ///
				labels(`""% White: English/Welsh/Scottish/Northern Irish/British" "% White: Irish" "% White: Gypsy or Irish Traveller" "% White: Other White" "% Mixed/multiple ethnic groups: White and Black Caribbean" "% Mixed/multiple ethnic groups: White and Black African" "% Mixed/multiple ethnic groups: White and Asian" "% Mixed/multiple ethnic groups: Other Mixed" "% Asian/Asian British: Indian" "% Asian/Asian British: Pakistani" "% Asian/Asian British: Bangladeshi" "% Asian/Asian British: Chinese" "% Asian/Asian British: Other Asian" "% Black/African/Caribbean/Black British: African" "% Black/African/Caribbean/Black British: Caribbean" "% Black/African/Caribbean/Black British: Other Black" "% Other ethnic group: Arab" "% Any other ethnic group""')
				
get KS204EW,	vars(12(1)20) n ///
				varnames(birth_eng birth_ni birth_scot birth_wales birth_ukother birth_ireland birth_eu2001 birth_eupost2001 birth_other) ///
				labels(`""% born in England" "% born in Northern Ireland" "% born in Scotland" "% born in Wales" "% born in United Kingdom not otherwise specified\n" "% born in Ireland" "% born in Other EU: Member countries in March 2001" "% born in Other EU: Accession countries April 2001 to March 2011" "% born in Other countries""')

get KS206EW,	vars(7 8 9 10) n ///
				varnames(eng_all eng_some eng_noadult eng_none) ///
				labels(`""% hh where Everyone speaks English" "% hh where Not all adults speak English" "% hh where No adults but some children speak English" "% hh where No English""')
				
get KS401EW,	vars(16(1)27) n ///
				varnames(hh_unshared hh_share2 hh_share3 hh_one	hh_none hh_detached hh_semidetached hh_terrace hh_flat hh_converted hh_commercial hh_mobile) ///
				labels(`""% households with Unshared dwelling" "% households with Shared dwelling: Two household spaces" "% households with Shared dwelling: Three or more household spaces" "% households with Household spaces with at least one usual resident" "% households with Household spaces with no usual residents" "% households with Whole house or bungalow: Detached " "% households with Whole house or bungalow: Semi-detached" "% households with Whole house or bungalow: Terraced (including end-terrace)" "% households with Flat, maisonette or apartment: Purpose-built block of flats or tenement" "% households with Flat, maisonette or apartment: Part of a converted or shared house (including bed-sits)" "% households with Flat, maisonette or apartment: In commercial building" "% households with Caravan or other mobile or temporary structure""')
		
get KS402EW,	vars(11(1)18) n ///
				varnames(own_own own_mortgage own_shared own_council own_social own_landlord own_other own_norent) ///
				labels(`""% hh Owned: Owned outright" "% hh Owned: Owned with a mortgage or loan" "% hh Shared ownership (part owned and part rented)" "% hh Social rented: Rented from council (Local Authority)" "% hh Social rented: Other" "% hh Private rented: Private landlord or letting agency" "% hh Private rented: Other" "% hh Living rent free""')

get KS403EW,	vars(7 8 9) ///
				varnames(hh_size hh_rooms hh_bedrooms) ///
				labels(`""Avg household size" "Avg rooms/hh" "Avg bedrooms/hh""')
				
get KS404EW,	vars(9(1)13) n ///
				varnames(car_0 car_1 car_2 car_3 car_4) ///
				labels(`""% households with No cars or vans in household" "% households with 1 car or van in household" "% households with 2 cars or vans in household" "% households with 3 cars or vans in household" "% households with 4 or more cars or vans in household""')

get KS501EW,	vars(15(1)21) n ///
				varnames(edu_0 edu_1 edu_2 edu_appr edu_3 edu_4 edu_other) ///
				labels(`""% people with Highest level of qualification: no qualifications" "% people with Highest level of qualification: Level 1 qualifications" "% people with Highest level of qualification: Level 2 qualifications" "% people with Highest level of qualification: Apprenticeship" "% people with Highest level of qualification: Level 3 qualifications" "% people with Highest level of qualification: Level 4 qualifications and above" "% people with Highest level of qualification: Other qualifications""')
				
get KS601EW,	vars(17(1)30) n ///
				varnames(work_part work_full work_self work_unemp work_student work_retired work_studentno work_home work_sick work_other unemp_1624 unemp_5074 unemp_never unemp_longterm) ///
				labels(`""% people Economically active: Employee: Part-time" "% people Economically active: Employee: Full-time" "% people Economically active: Self-employed" "% people Economically active: Unemployed" "% people Economically active: Full-time student" "% people Economically inactive: Retired" "% people Economically inactive: Student (including full-time students)" "% people Economically inactive: Looking after home or family" "% people Economically inactive: Long-term sick or disabled" "% people Economically inactive: Other" "% people Unemployed: Age 16 to 24" "% people Unemployed: Age 50 to 74" "% people Unemployed: Never worked" "% people Long-term unemployed""')
				
get KS605EW,	vars(21(1)38) n ///
				varnames(ind_a ind_b ind_c ind_d ind_e ind_f ind_g ind_h ind_i ind_j ind_k ind_l ind_m ind_n ind_o ind_p ind_q ind_r) ///
				labels(`""% people in A Agriculture, forestry and fishing" "% people in B Mining and quarrying" "% people in C Manufacturing" "% people in D Electricity, gas, steam and air conditioning supply" "% people in E Water supply; sewerage, waste management and remediation activities" "% people in F Construction" "% people in G Wholesale and retail trade; repair of motor vehicles and motor cycles" "% people in H Transport and storage" "% people in I Accommodation and food service activities" "% people in J Information and communication" "% people in K Financial and insurance activities" "% people in L Real estate activities" "% people in M Professional, scientific and technical activities" "% people in N Administrative and support service activities" "% people in O Public administration and defence; compulsory social security" "% people in P Education" "% people in Q Human health and social work activities" "% people in R, S, T, U Other""')

get KS611EW,	vars(18(1)32) n ///
				varnames(nssec_1 nssec_2 nssec_3 nssec_4 nssec_5 nssec_6 nssec_7 nssec_8 nssec_9 nssec_10 nssec_11 nssec_12 nssec_13 nssec_14 nssec_15) ///
				labels(`""% people in 1. Higher managerial, administrative and professional occupations" "% people in 1.1 Large employers and higher managerial and administrative occupations" "% people in 1.2 Higher professional occupations" "% people in 2. Lower managerial, administrative and professional occupations" "% people in 3. Intermediate occupations" "% people in 4. Small employers and own account workers" "% people in 5. Lower supervisory and technical occupations" "% people in 6. Semi-routine occupations" "% people in 7. Routine occupations" "% people in 8. Never worked and long-term unemployed" "% people in L14.1 Never worked" "% people in L14.2 Long-term unemployed" "% people in Not classified" "% people in L15 Full-time students" "% people in L17 Not classifiable for other reasons""')
				
get QS106EW,	vars(3 4 5) p ///
				varnames(hh_nosecond hh_seconduk hh_secondother) ///
				labels(`""% people with No second address" "% people with Second address within the UK" "% people with Second address outside the UK""')

get QS111EW, 	vars(2) ///
				varnames(households) ///
				labels(`""Total households""')
				
get QS111EW,	vars(3(1)18) p ///
				varnames(hh_lifestage_1 hh_lifestage_2 hh_lifestage_3 hh_lifestage_4 hh_lifestage_5 hh_lifestage_6 hh_lifestage_7 hh_lifestage_8 hh_lifestage_9 hh_lifestage_10 hh_lifestage_11 hh_lifestage_12 hh_lifestage_13 hh_lifestage_14 hh_lifestage_15 hh_lifestage_16) ///
				labels(`""% households with Age of HRP under 35: Total" "% households with Age of HRP under 35: One person household" "% households with Age of HRP under 35: Two or more person household: No dependent children" "% households with Age of HRP under 35: Two or more person household: With dependent children" "% households with Age of HRP 35 to 54: Total" "% households with Age of HRP 35 to 54: One person household" "% households with Age of HRP 35 to 54: Two or more person household: No dependent children" "% households with Age of HRP 35 to 54: Two or more person household: With dependent children" "% households with Age of HRP 55 to 64: Total" "% households with Age of HRP 55 to 64: One person household" "% households with Age of HRP 55 to 64: Two or more person household: No dependent children" "% households with Age of HRP 55 to 64: Two or more person household: With dependent children" "% households with Age of HRP 65 and over: Total" "% households with Age of HRP 65 and over: One person household" "% households with Age of HRP 65 and over: Two or more person household: No dependent children" "% households with Age of HRP 65 and over: Two or more person household: With dependent children""')				
				
get QS119EW,	vars(3(1)7) p ///
				varnames(hh_dep_0 hh_dep_1 hh_dep_2 hh_dep_3 hh_dep_4) ///
				labels(`""% Household is not deprived in any dimension" "% Household is deprived in 1 dimension" "% Household is deprived in 2 dimensions" "% Household is deprived in 3 dimensions" "% Household is deprived in 4 dimensions""')				
				
get QS412EW,	vars(3(1)7) p ///
				varnames(hh_or_1 hh_or_2 hh_or_3 hh_or_4 hh_or_5) ///
				labels(`""% households with Occupancy rating (bedrooms) of +2 or more" "% households with Occupancy rating (bedrooms) of +1" "% households with Occupancy rating (bedrooms) of 0" "% households with Occupancy rating (bedrooms) of -1" "% households with Occupancy rating (bedrooms) of -2 or less""')				
			
get QS415EW,	vars(3(1)9) p ///
				varnames(hh_heat_0 hh_heat_1 hh_heat_2 hh_heat_3 hh_heat_4 hh_heat_5 hh_heat_6) ///
				labels(`""% households with No central heating " "% households with Gas central heating" "% households with Electric (including storage heaters) central heating" "% households with Oil central heating" "% households with Solid fuel (for example wood, coal) central heating" "% households with Other central heating" "% households with Two or more types of central heating""')				
	
get QS611EW,	vars(3(1)6) p ///
				varnames(social_ab social_c1 social_c2 social_de) ///
				labels(`""% people with Approximated social grade AB" "% people with Approximated social grade C1" "% people with Approximated social grade C2" "% people with Approximated social grade DE""')	
	
get QS803EW,	vars(3(1)7) p ///
				varnames(res_0 res_1 res_2 res_3 res_4) ///
				labels(`""% people Born in the UK" "% people Resident in UK: Less than 2 years" "% people Resident in UK: 2 years or more but less than 5 years" "% people Resident in UK: 5 years or more but less than 10 years" "% people Resident in UK: 10 years or more""')	

* Generate weighting variable to account for geographic changes.

	egen llsoas2011 = total(llsoa!=""), by(llsoa01)
		label var llsoas2011 "# 2011 LLSOAs included in this 2001 LLSOA code."
		
	order llsoa llsoa01 lad area density population households llsoas2011 , first
		
	save "$datadir/Data/census_llsoas.dta" , replace
		use "$datadir/Data/census_llsoas.dta" , clear
		
		duplicates drop llsoa, force
		
		save "$datadir/Data/census_llsoas_unique.dta" , replace
*/				
* Merge onto installations dataset.

	use "$datadir/Data/Public/census_llsoas.dta" , clear
	
	drop llsoa
	rename llsoa01 llsoa
	
	labelcollapse (sum) area population households ///
		(mean) density malepct-res_4  ///
		(firstnm) lad ///
		, by(llsoa) fast
	
		duplicates drop
		
		replace density = population/area
		gen density_hh = households/area
			label var density_hh "Households per Hectare"
		
	saveold "$datadir/Data/Public/census_llsoas01.dta" , replace
		use "$datadir/Data/Public/census_llsoas01.dta" , clear
		
	merge 1:m llsoa using "$datadir/Data/Public/smalldomesticpv.dta" , keep(1 2 3) nogen
	
	
	* merge m:1 llsoa using "$datadir/Data/Public/census_llsoas_unique.dta" , keep(1 3 4 5) update nogen

		
/* Import CSE LSOA data

	tempfile a
	save `a', replace
	
	insheet using "$datadir/LSOA_data/data.csv", c names clear
	
	keep lsoacode imd imdrank incomescore rankofincomescore decilesimdincomerank imdpopulation fpifull2003 fpibasic2003 noofsolidwall noofoffgas totalhouseholds totalresidents solid offgas
	rename lsoacode llsoa
		label var llsoa "LLSOA"
		
	merge 1:m llsoa using `a' 
	drop if _m == 1
	drop _m
*/

* Save: 513,070 installs and 3,407  LSOAs (all 2001 codes)
	
	gen date = date(appdate,"DMY")
	format date %tddd_Mon_CCYY
	
	gen shock = 0
		replace shock = 1 if date > date("Oct 31, 2011","MDY")
		replace shock = 0 if date > date("Dec 12, 2011","MDY")
	gen shock1 = shock
		replace shock = 1 if date > date("Jan 25, 2012","MDY")
		replace shock = 0 if date > date("Mar 2, 2012","MDY")
	gen shock2 = shock - shock1
		replace shock = 1 if date > date("May 24, 2012","MDY")
		replace shock = 0 if date >= date("Aug 1, 2012","MDY")
	gen shock3 = shock - shock1 - shock2
	
	gen income = installed_capacity * tariffpkwh
		label var income "Maximum Hourly Income"
		
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
		
	drop  if regexm(llsoa,"W")
	
	label var social_ab "Social AB"
		label var own_own "Own Home"
		label var hh_flat  "Live in Apartments"
		label var work_unemp "Unemployment"

order *, alpha
compress
saveold "$datadir/Data/Public/installs_lsoas.dta",replace
	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
* Latitude adjustment
	
use "/Users/bbdaniels/Dropbox/Projects/GRI/household_microgeneration_project/NSPL_NOV_2013_UK.dta", clear

	collapse (mean) oseast1m osnrth1m , by(llsoa)
	
	egen min = max(osnrth1m)
	egen max = min(osnrth1m)
	
	gen oldrange = (max - min)
	gen newrange = (975 - 788) /* JRC data here http://www.reuk.co.uk/Solar-Insolation.htm */
	
	gen kwhpa = (((osnrth1m - 11543) * newrange) / oldrange) + 975 /* formula here http://stackoverflow.com/questions/929103/convert-a-number-range-to-another-range-maintaining-ratio */
	
	keep kwhpa llsoa
	
	merge 1:m llsoa using "$datadir/Data/Public/installs_lsoas.dta"
	
	gen payment = kwhpa * tariffpkwh * installed_capacity 
	
saveold "$datadir/Data/Public/installs_lsoas_lat.dta",replace
	use "$datadir/Data/Public/installs_lsoas_lat.dta",clear	
	saveold "$datadir/Data/Public/installs_lsoas.dta",replace
	
	
	
* Time Series

	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		collapse (p99) tariffpkwh , by(date) fast
			tempfile headline
				save `headline' , replace
	
	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		drop tariffpkwh
	
		merge m:1 date using `headline'  , nogen
	
		
		gen period = 0
		replace period = 6 if date < date("Aug 1, 2012","MDY")
		replace period = 5 if date <= date("May 24, 2012","MDY")
		replace period = 4 if date <= date("Mar 2, 2012","MDY")
		replace period = 3 if date <= date("Jan 25, 2012","MDY")
		replace period = 2 if date <= date("Dec 12, 2011","MDY")
		replace period = 1 if date <= date("Oct 31, 2011","MDY")
		
		sort date, stable
		
		replace period = 7 if tariffpkw <= 17.22
		replace period = 8 if tariffpkw <= 16.12
		replace period = 9 if tariffpkw <= 15.55
		replace period = 10 if tariffpkw <= 15.15
		replace period = 11 if tariffpkw <= 14.62
		replace period = 12 if tariffpkw <= 13.89
		replace period = 13 if tariffpkw <= 13.40
		
		encode llsoa , gen(llsoa_code)
		
		preserve
			collapse (mean) tariffpkwh , by(period) fast
			save `headline' , replace
		restore
		preserve
			labelcollapse (mean) hh_flat work_unemp own_own own_mortgage social_ab ///
				density_hh households urban, by(llsoa_code) fast
			tempfile chars
			save `chars' , replace
		restore 
		
		gen n_installs = (installed_capacity > 0)
		collapse (rawsum) installed_capacity n_installs, by(llsoa_code period) fast
			
			tsset llsoa_code period
			tsfill , full
				replace installed_capacity = 0 if installed_capacity == .

		merge m:1 period using `headline' , nogen
			drop if tariffpkwh == .
		merge m:1 llsoa_code using `chars' , update replace nogen

			

		sort llsoa_code period
		
		gen time = period
			replace time = time - 1 if (period == 2 | period == 4 | period == 6 ) 
			
		gen shock = (period == 2 | period == 4 | period == 6 )
		
		decode llsoa_code , gen(llsoa)
			
saveold "$datadir/Data/Public/ts_lsoas.dta",replace
	use "$datadir/Data/Public/ts_lsoas.dta",clear	
	
	
* Time Series – counterfactual

	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		collapse (p99) tariffpkwh , by(date) fast
			tempfile headline
				save `headline' , replace
	
	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		drop tariffpkwh
	
		merge m:1 date using `headline'  , nogen
	
		
		gen period = 0
		replace period = 6 if date < date("Aug 1, 2012","MDY")
		replace period = 5 if date <= date("May 24, 2012","MDY")
		replace period = 4 if date <= date("Mar 2, 2012","MDY")
		replace period = 3 if date <= date("Jan 25, 2012","MDY")
		replace period = 2 if date <= date("Dec 12, 2011","MDY")
		replace period = 1 if date <= date("Oct 31, 2011","MDY")
		
		sort date, stable
		
		drop if period > 0
		
		replace period = 1 if tariffpkw <= 17.22
		replace period = 3 if tariffpkw <= 16.12
		replace period = 5 if tariffpkw <= 15.55
		replace period = 7 if tariffpkw <= 15.15
		replace period = 9 if tariffpkw <= 14.62
		replace period = 11 if tariffpkw <= 13.89
		replace period = 13 if tariffpkw <= 13.40
		
		gen time = period
		
		bys period: egen meddate = median(date)
			replace period = period + 1 if date > meddate
		
		encode llsoa , gen(llsoa_code)
		
		preserve
			collapse (mean) tariffpkwh time, by(period) fast
			save `headline' , replace
		restore
		preserve
			labelcollapse (mean) hh_flat work_unemp own_own own_mortgage social_ab ///
				density_hh households urban, by(llsoa_code) fast
			tempfile chars
			save `chars' , replace
		restore 
		
		gen n_installs = (installed_capacity > 0)
		collapse (rawsum) installed_capacity n_installs, by(llsoa_code period) fast
			
			tsset llsoa_code period
			tsfill , full
				replace installed_capacity = 0 if installed_capacity == .

		merge m:1 period using `headline' , nogen
			drop if tariffpkwh == .
		merge m:1 llsoa_code using `chars' , update replace nogen

			

		sort llsoa_code period
		
		* gen time = period
			* replace time = time - 1 if (period == 2 | period == 4 | period == 6 ) 
			
		gen shock = !mod(period,2) 
		
		decode llsoa_code , gen(llsoa)
			
saveold "$datadir/Data/Public/ts_lsoas_counterfact.dta",replace
	use "$datadir/Data/Public/ts_lsoas_counterfact.dta",clear	
	
	

			
			
			
			
			
			
