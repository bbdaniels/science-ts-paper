* Tables and figures – final

* Figure 1. Timeline

	use "$datadir/Constructed/installs_lsoas.dta",clear

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
			order(2 "Headline Tariff (GBP/kWh)" 3 "Daily Installations" 1 "Policy Shock Periods" )) ///
		xtit(" ") ytit(" ") ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
		ytit(, axis(2)) ytit(, axis(1))  yscale(alt) yscale( noline axis(2)) ylab(0 "0.00" .2 "0.20" .4 "0.40" .6 "0.60" .8 "0.80" 1 `""GBP" "1.00""' , axis(2))

		graph export "${datadir}/outputs/F1_timeline.png" , replace width(1000)

* Table 1. Summary statistics

	* Panel A. Installation Level

		use "$datadir/Constructed/installs_lsoas.dta",clear

			drop if installed_capacity == .
			replace income = installed_capacity * tariffpkwh * 8.50

			sumstats ///
				(tariffpkwh installed_capacity income) ///
				(urban density_hh households social_ab own_own hh_flat work_unemp) ///
				using "${datadir}/outputs/1a_summary.xls" , replace stats(mean sd min p25 p50 p75 max N)

	* Panel B. LLSOA Level

		use "$datadir/Constructed/installs_lsoas.dta",clear

			replace income = installed_capacity * tariffpkwh * 8.50

			labelcollapse (mean) urban density_hh households social_ab own_own hh_flat work_unemp ///
				(sum) installed_capacity income, by(llsoa) fast

				sumstats ///
				(installed_capacity income) ///
				(urban density_hh households social_ab own_own hh_flat work_unemp) ///
				using "${datadir}/outputs/1b_summary.xls" , replace stats(mean sd min p25 p50 p75 max N)

* Table 2. Installation-level summary by period

	use "$datadir/Constructed/installs_lsoas.dta",clear

	keep if installed_capacity != .

		sumstats ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 1) ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 2) ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 3) ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 4) ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 5) ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period == 6) ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period > 6) ///
		(period installed_capacity income urban density_hh households social_ab own_own hh_flat work_unemp if period < 7) ///
		using "${datadir}/outputs/2_periods.xls" , replace stats(mean sd N)

* Table 3. Model calibration

	use "$datadir/Constructed/ts_lsoas.dta",clear
		keep if period <= 6

		xisto reg1, clear command(reg) depvar(capacity_day) cl(llsoa) ///
			rhs( tariffpkwh total2 c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh)

		xisto reg2,    	  command(reg) depvar(income_day) cl(llsoa) ///
			rhs( tariffpkwh total2 c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh)

		xisto reg3,    	  command(reg) depvar(capacity_day) cl(llsoa) ///
			rhs(shock tariffpkwh total2 c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh)

		xisto reg4,       command(reg) depvar(income_day) cl(llsoa) ///
			rhs(shock tariffpkwh total2 c.social_ab c.own_own c.hh_flat c.work_unemp urban c.density_hh)

		xisto reg5,       command(xtreg) depvar(capacity_day) cl(llsoa) fe ///
			rhs(shock  total2 i.time)

		xisto reg6,       command(xtreg) depvar(income_day) cl(llsoa) fe ///
			rhs(shock  total2 i.time)

	xitab  ///
		using "${datadir}/outputs/3_model.xls" , replace stats(mean sd)

* Table 4. Main effect

	// Period-wise
  use "$datadir/Constructed/ts_lsoas_date.dta" if period < 7 , clear

  local model shock total2 1.shock#c.(social_ab own_own hh_flat work_unemp urban density_hh)

  forvalues time = 1/3 {
    foreach var in capacity income {
      reghdfe `var' `model' if time == `time' ///
        , cl(llsoa date) a(llsoa_code) nosample
        est sto reg_`var'_`time'
        local regs "`regs' reg_`var'_`time'"
    }
  }

  outwrite `regs' using "/users/bbdaniels/desktop/test.xlsx" , replace stats(N r2)



		xitab  ///
			using "${datadir}/outputs/4a_periods.xls" , replace stats(mean sd)

	* Differential effect

		use "$datadir/Constructed/ts_lsoas.dta",clear
			keep if period < 7

		xtset llsoa_code period

		xisto reg1 , clear 	command(xtreg) depvar(capacity_day) cl(llsoa) fe ///
			rhs(i.time shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)

		xisto reg2 ,    	command(xtreg) depvar(income_day) cl(llsoa) fe ///
			rhs(i.time shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)

		xitab  ///
			using "${datadir}/outputs/4b_summary.xls" , replace stats(mean sd)

	* Counterfactual - simulated shocks

		use "$datadir/Constructed/ts_lsoas.dta",clear
			keep if period > 6

		xisto reg1 , clear 	command(xtreg) depvar(capacity_day) cl(llsoa) fe  ///
			rhs(i.time shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)

		xisto reg2 ,    	command(xtreg) depvar(income_day) cl(llsoa) fe  ///
			rhs(i.time shock total2 shock*social_ab shock*own_own shock*hh_flat shock*work_unemp shock*urban shock*density_hh)

		xitab  ///
			using "${datadir}/outputs/4c_counterfactual.xls" , replace stats(mean sd)
-

* Table A: Tariff Rates

	insheet using "${datadir}/Data/Raw/tarifftable2015.csv" ,  clear

	keep if regexm(tariffcode,"PV") & regexm(tariffcode,"0-4")
	keep if fityr == 6
	sort description
	drop fityr

	export excel using "${datadir}/outputs/1_tariffs.xlsx" , replace first(varl)


* Have a lovely day!
