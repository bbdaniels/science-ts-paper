* Tables and figures – final

/* Rolling Gini

	* Setup

		use "$datadir/Data/Public/installs_lsoas.dta",clear
		
			gen n = 1

			collapse (rawsum) n , by(llsoa) fast
			
			tempfile lsoa
				save `lsoa' , replace
			
		use "$datadir/Data/Public/installs_lsoas.dta",clear

		gen n = 1
		collapse (mean) shock* (p99) tariffpkwh ///
			(sum) declared_capacity installed_capacity income  ///
			(rawsum) n , by(date) fast
			
			su date
		
	* Build ginidate matrix
		
		set matsize 5000
		cap mat drop ginidate
		
		qui forvalues theDate = `r(min)'/`r(max)' {
			
			use "$datadir/Data/Public/installs_lsoas.dta", clear
			keep if date <= `theDate'
			
			collapse (sum) income , by(llsoa) fast
			merge 1:1 llsoa using `lsoa'
			
			replace income = 0 if income == .
			
			gen k = 1
			ginidesc income , gkmat(gini) mat(g2) by(k)
 
			local gini = gini[1,2]
			
			mat ginidate = nullmat(ginidate) \ [`gini' , `theDate']
			
		}
		
	* Load ginidate matrix to data
		
		clear
		svmat ginidate
		rename ginidate1 gini
		rename ginidate2 date
		
		tempfile ginidate
			save `ginidate' , replace
			
	* Graph

		use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		gen n = 1
		collapse (mean) shock* (p99) tariffpkwh ///
			(sum) declared_capacity installed_capacity income  ///
			(rawsum) n , by(date) fast
			
			merge 1:1 date using `ginidate' , keep(3) 
			
		gen tariff = tariffpkwh*0.01
			label var tariff "Average tariff per kWh (pounds)"
			
		tw (bar shock date , lc(gs12) fc(gs12) yaxis(1) ) ///
			(bar n date , lc(black) fc(black) fi(100) barw(2)) ///
			/// (line tariff date , lc(dkgreen) fc(dkgreen) lw(thick) yaxis(2) ) ///
			(line delta date , lc(black) fc(dkgreen) lw(thick) yaxis(2) ) ///
			, $graph_opts xsize(8) ///
			legend(ring(0) c(1) pos(11) symxsize(small) symysize(small) ///
				order(2 "Headline Tariff (GBP/kWh)" 3 "Daily Installations" 1 "Policy Shock Periods" 4 "#1: No Actual Cut" 4 "#2: 22p/kWh Cut" 4 "#3: 5p/kWh Cut"  )) ///
			xtit(" ") ytit(" ") ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
			ytit(, axis(2)) ytit(, axis(1))  yscale(alt) yscale( noline axis(2)) // ylab(0 "0.00" .2 "0.20" .4 "0.40" .6 "0.60" .8 "0.80" 1 `""GBP" "1.00""' , axis(2))
			
			graph export "${datadir}/outputs/F1_timeline.png" , replace width(1000)

*/
		

* Figure 1: Installs and Shocks

	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
	gen n = 1
	collapse (mean) shock* (p99) tariffpkwh ///
		(sum) declared_capacity installed_capacity income  ///
		(rawsum) n , by(date) fast
		
	gen tariff = tariffpkwh*0.01
		label var tariff "Average tariff per kWh (pounds)"
	
	tw (bar shock date , lc(gs12) fc(gs12) yaxis(2) ) ///
		(bar n date , lc(black) fc(black) fi(100) barw(2)) ///
		(line tariff date , lc(dkgreen) fc(dkgreen) lw(thick) yaxis(2) ) ///
		, $graph_opts xsize(8) ///
		legend(ring(0) c(1) pos(11) symxsize(small) symysize(small) ///
			order(2 "Headline Tariff (GBP/kWh)" 3 "Daily Installations" 1 "Policy Shock Periods" 4 "#1: No Actual Cut" 4 "#2: 22p/kWh Cut" 4 "#3: 5p/kWh Cut"  )) ///
		xtit(" ") ytit(" ") ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
		ytit(, axis(2)) ytit(, axis(1))  yscale(alt) yscale( noline axis(2)) ylab(0 "0.00" .2 "0.20" .4 "0.40" .6 "0.60" .8 "0.80" 1 `""GBP" "1.00""' , axis(2))
		
		graph export "${datadir}/outputs/F1_timeline.png" , replace width(1000)


* Table (A?1): Tariff Rates

	insheet using "${datadir}/Data/Raw/tarifftable2015.csv" ,  clear
		
	keep if regexm(tariffcode,"PV") & regexm(tariffcode,"0-4")
	keep if fityr == 6
	sort description
	drop fityr
	
	export excel using "${datadir}/outputs/1_tariffs.xlsx" , replace first(varl)
	
* Table: Summary overall

	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		drop if installed_capacity == .
		replace income = installed_capacity * tariffpkwh * 8.50
		
		sumstats ///
			(tariffpkwh installed_capacity income) ///
			(urban density_hh households social_ab own_own hh_flat work_unemp) ///
			using "${datadir}/outputs/2a_summary.xls" , replace stats(mean sd min p25 p50 p75 max N)
			
	use "$datadir/Data/Public/installs_lsoas.dta",clear	
	
		replace income = installed_capacity * tariffpkwh * 8.50
		
		labelcollapse (mean) urban density_hh households social_ab own_own hh_flat work_unemp ///
			(sum) installed_capacity income, by(llsoa) fast
			
			sumstats ///
			(installed_capacity income) ///
			(urban density_hh households social_ab own_own hh_flat work_unemp) ///
			using "${datadir}/outputs/2b_summary.xls" , replace stats(mean sd min p25 p50 p75 max N)

* Table – summary by period
			
	use "$datadir/Data/Public/installs_lsoas.dta",clear	
	
		replace income = installed_capacity * tariffpkwh * 8.50
		
		gen period = 0
		replace period = 6 if date < date("Aug 1, 2012","MDY")
		replace period = 5 if date <= date("May 24, 2012","MDY")
		replace period = 4 if date <= date("Mar 2, 2012","MDY")
		replace period = 3 if date <= date("Jan 25, 2012","MDY")
		replace period = 2 if date <= date("Dec 12, 2011","MDY")
		replace period = 1 if date <= date("Oct 31, 2011","MDY")
		
		keep if installed_capacity != .
		
			sumstats ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 1) ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 2) ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 3) ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 4) ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 5) ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 6) ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 0) ///
			(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period != 0) ///
			using "${datadir}/outputs/3_periods.xls" , replace stats(mean sd N)

* Table – differenced regression
	
	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
	replace income = 8.5 * installed_capacity * tariffpkwh

	drop shock*
	
	gen period = 0
	drop if date >= date("Aug 1, 2012","MDY")
		replace period = 6 if date < date("Aug 1, 2012","MDY")
		replace period = 5 if date <= date("May 24, 2012","MDY")
		replace period = 4 if date <= date("Mar 2, 2012","MDY")
		replace period = 3 if date <= date("Jan 25, 2012","MDY")
		replace period = 2 if date <= date("Dec 12, 2011","MDY")
		replace period = 1 if date <= date("Oct 31, 2011","MDY")
	
	* Natural
	
		label def period ///
			1 "No Cut, Pre-Announcement" ///
			2 "No Cut, Post-Announcement" ///
			3 "22p/kWh Cut, Pre-Announcement" ///
			4 "22p/kWh Cut, Post-Announcement" ///
			5 "5p/kWh Cut, Pre-Announcement" ///
			6 "5p/kWh Cut, Post-Announcement"
			
			label val period period

	gen shock = (period == 2 | period == 4 | period == 6 )
	gen likely = 0
		replace likely = 1 if (period == 3 | period == 4)
		replace likely = 2 if (period == 5 | period == 6)
		
	label def likely 0 "No Actual Cut" 1 "Time 2" 2 "Time 3", modify
		label val likely likely
	
	cap mat drop theResults
	local theList social_ab own_own hh_flat work_unemp urban density_hh
	 foreach var of varlist social_ab own_own hh_flat work_unemp urban density_hh {
		
		preserve
		local theVar "`var'"
		local vars : list theList - theVar
		
		su `var'
			local theMean = r(mean)
			local theSD = r(sd)
			replace `var' = (`var'-`theMean')/`theSD'
	
		reg `var' ///
			i.shock##i.likely  ///
			[pweight=income]
			
			mat temp = r(table)
			mat theResult = temp[1,2] \ temp[2,2] \ temp[1,10] \ temp[2,10] \ temp[1,11] \ temp[2,11] \ [`e(N)'] \ [`theMean'] \ [`theSD']
			mat colnames theResult = "`var'"
			mat theResults = nullmat(theResults) , theResult
		restore
		=
			}
			
		mat rownames theResults = "Shock 1" "SE" "Shock 2" "SE" "Shock 3" "SE" "N" "Mean" "SD"
		matlist theResults
		
		xml_tab theResults using "${datadir}/outputs/regs_1.xls" , replace 
		
		cap mat drop theResults
		qui foreach var of varlist social_ab own_own hh_flat work_unemp urban density_hh {
			
			preserve
			local theVar "`var'"
			local vars : list theList - theVar
			
			su `var'
				local theMean = r(mean)
				local theSD = r(sd)
				replace `var' = (`var'-`theMean')/`theSD'
		
			reg `var' ///
				i.shock##i.likely  ///
				[pweight=installed_capacity]
				
				mat temp = r(table)
				mat theResult = temp[1,2] \ temp[2,2] \ temp[1,10] \ temp[2,10] \ temp[1,11] \ temp[2,11] \ [`e(N)'] \ [`theMean'] \ [`theSD']
				mat colnames theResult = "`var'"
				mat theResults = nullmat(theResults) , theResult
			restore
			
				}
				
			mat rownames theResults = "Shock 1" "SE" "Shock 2" "SE" "Shock 3" "SE" "N" "Mean" "SD"
			matlist theResults
			
			xml_tab theResults using "${datadir}/outputs/regs_2.xls" , replace 

* Table – Shock effect

	use "$datadir/Data/Public/ts_lsoas.dta",clear 
		keep if period <= 6
		
	gen income = tariffpkwh * 8.5 * installed_capacity
	
	label var tariffpkwh "Headline Tariff"
	label var shock "Policy Shock Period"
	label var urban "Urban Area"
	gen int_1 = tariffpkwh * (shock == 1)
	label var int_1 "Shock * Tariff"
	
	bys llsoa: gen total = sum(installed_capacity) - installed_capacity
	
	replace n_installs = 0 if n_installs == .
	bys llsoa: gen count = sum(n_installs) - n_installs
	
	gen total2 = households - count
	label var total2 "Households Without Installations"
	
	* Installs
	
	reg installed_capacity tariffpkwh total2 ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa)
		
		eststo reg1
		
	reg installed_capacity shock tariffpkwh total2 ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa)
		
		eststo reg2
		
	areg installed_capacity shock total2 ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa) a(time)
		
		eststo reg3
	
	xtreg installed_capacity shock  total2 i.time, fe
	
		eststo reg4
	
	xtreg installed_capacity shock  int_1 total2 i.time, fe
	
		eststo reg5
	
	* Income
	
	reg income tariffpkwh total2 ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa)
		
		eststo reg6
		
	reg income shock tariffpkwh total2 ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa)
		
		eststo reg7
		
	areg income shock total2 ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa) a(time)
		
		eststo reg8
	
	xtreg income shock  total2 i.time, fe
	
		eststo reg9
		
	xtreg income shock  int_1 total2 i.time, fe
	
		eststo reg10
		
	xml_tab reg1 reg2 reg3 reg4 reg5 ///
			reg6 reg7 reg8 reg9 reg10 ///
	using "${datadir}/outputs/shock_reg.xls" , replace below 

* Differential effect

	use "$datadir/Data/Public/ts_lsoas.dta",clear 
	
	label var tariffpkwh "Headline Tariff"
	label var shock "Policy Shock Period"
	label var urban "Urban Area"
		
	gen check = social_ab < .206
	gen income = installed_capacity * tariffpkwh * 8.50
	
	keep if period < 7
	
		gen weeks = 75
		replace weeks = 6 if period == 2
		replace weeks = 5 if period == 3
		replace weeks = 5 if period == 4
		replace weeks = 11 if period == 5
		replace weeks = 13 if period == 6
		
		replace income = income/weeks
	
	xtset llsoa_code period
	
	replace n_installs = 0 if n_installs == .
	bys llsoa: gen count = sum(n_installs) - n_installs
	
	gen total2 = households - count
	label var total2 "Households Without Installations"

	xisto reg1 , clear 	command(xtreg) depvar(installed_capacity) cl(llsoa) fe ///
		rhs(i.time shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	xisto reg2 ,    	command(xtreg) depvar(income) cl(llsoa) fe ///
		rhs(i.time shock weeks total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	
	  
	xitab  ///
		using "${datadir}/outputs/diff_reg.xls" , replace stats(mean)
		
* Differential effect – periodwise

	use "$datadir/Data/Public/ts_lsoas.dta",clear 
	
	label var tariffpkwh "Headline Tariff"
	label var shock "Policy Shock Period"
	label var urban "Urban Area"
		
	gen check = social_ab < .206
	gen income = installed_capacity * tariffpkwh * 8.50
	
	keep if period < 7
	
			gen weeks = 75
		replace weeks = 6 if period == 2
		replace weeks = 5 if period == 3
		replace weeks = 5 if period == 4
		replace weeks = 11 if period == 5
		replace weeks = 13 if period == 6
		
		replace income = income/weeks
	
	replace n_installs = 0 if n_installs == .
	bys llsoa: gen count = sum(n_installs) - n_installs
	
	gen total2 = households - count
		label var total2 "Households Without Installations"
	
	xtset llsoa_code period
	
	xisto reg1 if time == 1, clear 	command(xtreg) depvar(installed_capacity) cl(llsoa) fe ///
		rhs( shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh )
	  
	xisto reg2 if time == 1,    	command(xtreg) depvar(income) cl(llsoa) fe ///
		rhs( shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	xisto reg3 if time == 3,  	command(xtreg) depvar(installed_capacity) cl(llsoa) fe ///
		rhs( shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	xisto reg4 if time == 3,    	command(xtreg) depvar(income) cl(llsoa) fe ///
		rhs( shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	xisto reg5 if time == 5,  	command(xtreg) depvar(installed_capacity) cl(llsoa) fe ///
		rhs( shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	xisto reg6 if time == 5,    	command(xtreg) depvar(income) cl(llsoa) fe ///
		rhs( shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	
	  
	xitab  ///
		using "${datadir}/outputs/diff_reg_period.xls" , replace stats(mean)
		

		
* Counterfactual - simulated shocks

			
	use "$datadir/Data/Public/ts_lsoas_counterfact.dta",clear
	
	label var tariffpkwh "Headline Tariff"
	label var shock "Policy Shock Period"
	label var urban "Urban Area"
	
	xtset llsoa_code period
	gen income = installed_capacity * tariffpkwh * 8.50
	
	replace n_installs = 0 if n_installs == .
	bys llsoa: gen count = sum(n_installs) - n_installs
	
	gen total2 = households - count
	label var total2 "Households Without Installations"
	
	xisto reg1 , clear 	command(xtreg) depvar(installed_capacity) cl(llsoa) fe  ///
		rhs(i.time shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	  
	xisto reg2 ,    	command(xtreg) depvar(income) cl(llsoa) fe  ///
		rhs(i.time shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)
	
	xitab  ///
		using "${datadir}/outputs/diff_reg_2.xls" , replace stats(mean sd)
		
* Have a lovely day!

