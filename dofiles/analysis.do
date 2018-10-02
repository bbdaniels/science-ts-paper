* Analysis for Time Series Paper

* Table 1: Key timeline (manual)

* Table (A?1): Tariff Rates

	insheet using "${datadir}/Data/Raw/tarifftable2015.csv" ,  clear
		
	keep if regexm(tariffcode,"PV") & regexm(tariffcode,"0-4")
	keep if fityr == 6
	sort description
	drop fityr
	
	export excel using "${datadir}/outputs/1_tariffs.xlsx" , replace first(varl)

* Table: Summary

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
			using "${datadir}/outputs/2c_summary.xls" , replace stats(mean sd N)

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
		
* Figure 2: Input Characteristics
		
	use "$datadir/Data/Public/installs_lsoas.dta",clear
		
	gen n = 1
	collapse (mean) shock* hh_flat density_hh work_unemp own_own social_ab (rawsum) n [pweight=installed_capacity], by(date) fast
	
	foreach var of varlist work_unemp own_own social_ab hh_flat {
		qui su `var' if date < date("Oct 31, 2011","MDY")
		local theLevel = `r(mean)'
		local theLines = "`theLines' yline(`theLevel', lw(thin) lp(dash) lc(black) axis(2))"
		qui su `var' if date > date("Mar 3, 2012","MDY")
		local theLevel = `r(mean)'
		local theLines = "`theLines' yline(`theLevel', lw(thin) lp(dash) lc(black) axis(2))"
		* di in red "`theLines'"
		}
	
	tw (bar shock date , lc(gs12) fc(gs12) yaxis(2) ) ///
		(bar n date , lc(black) fc(black) fi(100) barw(2)) ///
		(lpoly work_unemp date , lw(thick) lc(maroon) fc(maroon) yaxis(2) ) ///
		(lpoly own_own date , lw(thick) lc(navy) fc(navy) yaxis(2) ) ///
		(lpoly social_ab date , lw(thick) lc(dkgreen) fc(dkgreen) yaxis(2)) ///
		(lpoly hh_flat date , lw(thick) lc(black) fc(black) yaxis(2) ) ///
		, $graph_opts xsize(8) `theLines' ///
		legend(ring(0) c(1) pos(11) symxsize(small) symysize(small) ///
			order(1 "Policy Shock Period" 6 "Number of Installations" 2 "Avg % Unemployment" 3 "Avg % Homeowners" 4 "Avg % Highest Social Class" 5 "Avg % Flat-dwellers" )) ///
		xtit(" ") ytit(" ") ylab(, angle(0) axis(2)) yscale(off alt axis(1)) ///
		ytit(, axis(2)) ytit(, axis(1)) yscale( noline axis(2)) ylab(${pct},axis(2)) 
		
		graph export "${datadir}/outputs/F2_characteristics.png" , replace width(1000)

* LLSOA regression 1: shock effect

	use "$datadir/Data/Public/ts_lsoas.dta",clear 
		keep if period <= 6
		
	gen income = tariffpkwh * 8.5 * installed_capacity
	
	label var tariffpkwh "Headline Tariff"
	label var shock "Policy Shock Period"
	label var urban "Urban Area"
	gen int_1 = tariffpkwh * (shock == 1)
	label var int_1 "Shock * Tariff"
	
	bys llsoa: gen total = sum(installed_capacity) - installed_capacity
	
	* Installs
	
	reg installed_capacity shock tariffpkwh  ///
		, cl(llsoa)
		
		eststo reg1
		
	reg installed_capacity shock tariffpkwh ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa)
		
		eststo reg2
		
	areg installed_capacity shock ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa) a(time)
		
		eststo reg3
	
	xtreg installed_capacity shock tariffpkwh , fe
	
		eststo reg4
	
	xtreg installed_capacity shock tariffpkwh int_1 , fe
	
		eststo reg5
	
	* Income
	
	reg income shock tariffpkwh ///
		, cl(llsoa)
		
		eststo reg6
		
	reg income shock tariffpkwh ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa)
		
		eststo reg7
		
	areg income shock ///
		c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh ///
		, cl(llsoa) a(time)
		
		eststo reg8
	
	xtreg income shock tariffpkwh , fe
	
		eststo reg9
		
	xtreg income shock tariffpkwh int_1, fe
	
		eststo reg10
		
	xml_tab reg1 reg2 reg3 reg4 reg5 ///
			reg6 reg7 reg8 reg9 reg10 ///
	using "${datadir}/outputs/shock_reg.xls" , replace below 
	
	
	
* LLSOA regression 2: differential effect
	
	use "$datadir/Data/Public/ts_lsoas.dta",clear 
		keep if period <= 6
		
	gen income = tariffpkwh * 8.5 * installed_capacity
	
	label var tariffpkwh "Headline Tariff"
	label var shock "Policy Shock Period"
	label var urban "Urban Area"
	gen int_1 = tariffpkwh * (shock == 1)
	label var int_1 "Shock * Tariff"
	
	sort llsoa period
		replace n_installs = 0 if n_installs == .
		bys llsoa: gen total = sum(installed_capacity) - installed_capacity
		bys llsoa: gen total2 = households - sum(n_installs) + n_installs
	
	* Installs

		gen weeks = 75
			replace weeks = 6 if period == 2
			replace weeks = 5 if period == 3
			replace weeks = 5 if period == 4
			replace weeks = 11 if period == 5
			replace weeks = 13 if period == 6
			
		char period[omit] 1	
		
			* keep if shock == 1
			
			xtreg installed_capacity i.time i.shock ///
			 (1.shock)#(c.social_ab c.own_own c.hh_flat c.work_unemp c.density_hh 1.urban ) ///
				total2 ///
			, fe coefl
			
			xtreg installed_capacity i.time i.shock ///
			 (2.period)#(c.social_ab ) ///
			 (4.period)#(c.social_ab ) ///
			 (6.period)#(c.social_ab ) ///
			 (1.shock)#( c.own_own c.hh_flat c.work_unemp c.density_hh 1.urban ) ///
				total2 ///
			, fe coefl
			
			xtreg installed_capacity i.time i.shock ///
			 (2.period)#(c.own_own ) ///
			 (4.period)#(c.own_own ) ///
			 (6.period)#(c.own_own  ) ///
			 (1.shock)#( c.social_ab c.hh_flat c.work_unemp c.density_hh 1.urban ) ///
				total2 ///
			, fe coefl
			
			
			
			
			
		
			
		xtreg installed_capacity i.time ///
			 (2.period)#(c.social_ab ) ///
			 (4.period)#(c.social_ab ) ///
			 (6.period)#(c.social_ab ) ///
			 total ///
			, fe 
			
		xtreg installed_capacity i.period ///
			 (2.period)#(c.own_own ) ///
			 (4.period)#(c.own_own ) ///
			 (6.period)#(c.own_own ) ///
			, fe 
		
		
			
		
			xtreg installed_capacity i.time ///
			 (1.shock)#(c.social_ab c.own_own c.hh_flat c.work_unemp c.density_hh i.urban) ///
			total  ///
			, fe 
			
			
			
		reg installed_capacity ///
			c.social_ab c.own_own c.hh_flat c.work_unemp c.density_hh ///
			if shock == 0
			
		
	
	
	
	
	
	
	///
		1.shock#(c.social_ab c.own_own c.hh_flat c.work_unemp i.urban c.density_hh), fe
	

		
		
	reg installed_capacity shock tariffpkwh ///
		own_own own_mortgage households hh_flat density_hh social_ab work_unemp urban ///
		, cl(llsoa)
		
	xtset llsoa_code period
	xtreg installed_capacity shock tariffpkwh , fe
	
	xtreg installed_capacity 1.shock tariffpkwh ///
		1.shock#(c.social_ab c.own_own c.hh_flat c.work_unemp i.urban c.density_hh), fe
		
	reg installed_capacity 1.shock tariffpkwh ///
		1.shock#(c.social_ab)
		
	xtreg installed_capacity i.time ///
		(c.social_ab c.own_own c.hh_flat c.work_unemp c.density_hh)#(2.period 4.period 6.period) , fe
		
	xtreg income tariffpkwh ///
		(c..social_ab c.own_own c.hh_flat c.work_unemp c.density_hh)#(1.shock) , fe
		
	
* Counterfactual - simulated shocks

			
	use "$datadir/Data/Public/ts_lsoas_counterfact.dta",clear
	
		
	
		
* Key regressions

	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
	drop shock*
	
	gen period = 0
	drop if date > date("Aug 1, 2012","MDY")
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
	
		su social_ab
			local theMean = `r(mean)'
	
		reg social_ab ///
			i.period date ///
			own_own hh_detached hh_dep_4 work_unemp urban ///
			[pweight=installed_capacity]
			
		
			
			margins period 
			marginsplot , recast(bar) plotopts( fc(gs10) lw(thin) lc(white)) ///
				ciopts( lc(black) ) ///
				xtit(" ") ytit(" ") title(" ") ///
				$graph_opts xsize(6)  horiz ///
				xlab(.2 "20%" `theMean' "25% (Mean)" .3 "30%") xline(`theMean', lc(black) lp(dash))
				
			graph export "${datadir}/outputs/F3_levels.png" , replace width(1000)
			
	* Diff-in-diff
	
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
			
		label def likely 0 "No Actual Cut" 1 "5p/kWh Actual Cut" 2 "22p/kWh Actual Cut", modify
			label val likely likely
		
		
		cap mat drop theResults
		local theList social_ab own_own hh_detached hh_dep_4 work_unemp urban
		qui foreach var of varlist social_ab own_own hh_detached hh_dep_4 work_unemp urban {
			
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
			
				}
				
			mat rownames theResults = "Shock 1" "SE" "Shock 2" "SE" "Shock 3" "SE" "N" "Mean" "SD"
			matlist theResults
			
			xml_tab theResults using "${datadir}/outputs/regs_1.xls" , replace 
		
		cap mat drop theResults
		qui foreach var of varlist social_ab own_own hh_detached hh_dep_4 work_unemp urban {
			
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
			
		
		
		label def likely 0 `""No Actual Cut" "(+0.016 SD)""' 1 `""5p/kWh Actual Cut" "(+0.076 SD)""' 2 `""22p/kWh Actual Cut" "(+0.14 SD)""' , modify
			label val likely likely
		
		reg social_ab ///
			i.shock##i.likely date ///
			own_own hh_detached hh_dep_4 work_unemp urban  ///
			[pweight=installed_capacity] 
			
			margins i.likely , dydx(shock)
			marginsplot, recast(bar) plotopts(fc(gs10) lw(thick) lc(white)) ///
				ciopts( lc(black)) ///
				xtit(" ") ytit(" ") title(" ") ///
				$graph_opts xsize(6) ///
				ylab(0 "No Shock Effect" 0.005 "+0.5%" 0.01 "+1.0%" .015 "+1.5%" .02 "+2.0%")
		
		graph export "${datadir}/outputs/F4_differences.png" , replace width(1000)
		
	* Diff-in-diff (counterfactual)
	
	use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		drop shock*
			
		gen period = 0
		drop if date > date("Aug 1, 2012","MDY")
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
		gen likely = ( period == 3 | period == 5 | period == 4 | period == 6 )
			replace likely = 2 if (period == 3 | period == 4)
			replace likely = 1 if (period == 5 | period == 6)

	
		reg own_own   ///
			i.shock##i.likely date ///
			hh_detached social_ab hh_dep_4 work_unemp urban  ///
			[pweight=installed_capacity]
			
			margins i.likely , dydx(shock)
			marginsplot, recast(bar) plotopts(fc(gs10) lw(thick) lc(white)) ///
				ciopts( lc(black)) ///
				xtit(" ") ytit(" ") title(" ") ///
				$graph_opts xsize(6) ///
				ylab(0 "No Shock Effect" 0.005 "+0.5%" 0.01 "+1.0%" .015 "+1.5%" .02 "+2.0%")
		
		graph export "${datadir}/outputs/F5_counterfactual.png" , replace width(1000)
		
	
		
	* RD
	
		use "$datadir/Data/Public/installs_lsoas.dta",clear
	
		drop shock*
		
		gen period = date > date("Aug 1, 2012","MDY")
		
		reg social_ab c.date c.date#1.period period own_own hh_detached hh_dep_4 work_unemp urban

* Time series 

	use "$datadir/Data/Public/ts_lsoas.dta",clear 
		
	gen check = social_ab < .206
	gen income = installed_capacity * tariffpkwh * 8.50
	
	label def check 0 "Top 50%" 1 "Bottom 50%" , modify
		label val check check
		
	label def period ///
		1 "Period 1" 2 "Shock Period 2" 3 "Period 3" 4 "Shock Period 4" 5 "Period 5" 6 "Shock Period 6" ///
		7 "Period 7" 8 "Period 8" 9 "Period 9" 10 "Period 10" 11 "Period 11" 12 "Period 12" 13 "Period 13" ///
		, modify
		label val period period
	
	graph hbar (sum) income , over(check) over(period) asy stack perc yline(50) ///
		$graph_opts1 bar(2 , lw(none) fc(none)) legend(off) ylab(0 "0%" 25 "25%" 50 "50%" 75 "75%" 100 "100%") ///
		ytit("Proportion of Income to Top 50% LLSOAs") // Proportion of income
		
		graph export "${datadir}/outputs/F_incomepct.png" , replace width(1000)

	graph hbar (sum) income, over(check) over(period) asy stack ///
		$graph_opts1 ytit("Total Annual Income to Top and Bottom 50% LLSOAs") ///
		ylab(0 "GBP 0" 50000000 "50,000,000" 100000000 "100,000,000") legend(c(1) pos(5) ring(0))
		
		graph export "${datadir}/outputs/F_income.png" , replace width(1000)

	keep if period <= 6
	
	xtset llsoa_code period
	
		xtreg installed_capacity i.period i.period#(c.social_ab c.own_own c.hh_flat c.work_unemp i.urban c.density_hh) ///
			///
			if  !(period == 2 | period == 4 | period == 6 ) ///
			, fe
			
			predict cap_counter , xbu
			replace cap_counter = 0 if cap_counter < 0
		
		xtreg installed_capacity i.time i.shock 1.shock#(c.social_ab c.own_own c.hh_flat c.work_unemp i.urban c.density_hh)
			
			predict cap_hat , xbu
			replace cap_hat = 0 if cap_hat < 0
			
			gen income = installed_capacity*tariffpkwh
			gen income_hat = cap_hat*tariffpkwh
			gen income_counter = cap_counter*tariffpkwh
			
		* drop if period > 6
			
		collapse (mean) urban density_hh households social_ab own_own hh_flat work_unemp ///
			(sum) income* installed_capacity cap* , by(llsoa_code) fast
		
			gen tariff = income/installed_capacity
			gen tariff_hat = income_hat/cap_hat
			gen tariff_counter = income_counter/cap_counter
			
			gen income_percap = income/households
			gen income_percap_hat = income_hat/households
			gen income_percap_counter = income_counter/households
			
	// own_own hh_flat density_hh work_unemp
		
* Have a lovely day!






