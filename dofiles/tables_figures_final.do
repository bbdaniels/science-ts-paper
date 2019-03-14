// Tables and figures

// Figure 1. Timeline

  // Shocks
  use "$datadir/Constructed/installs_lsoas.dta" ///
    if date <= date("31 July 2012","DMY") , clear

  	gen n = 1
  	collapse (mean) shock* (p99) tariffpkwh ///
  		(sum) declared_capacity installed_capacity income  ///
  		(rawsum) n , by(date) fast

    drop in 1 // Retroactive installations

  	gen tariff = tariffpkwh*0.01
  		label var tariff "Average tariff per kWh (pounds)"

  	tw (bar shock date , lc(gs12) fc(gs12) yaxis(2) ) ///
  		(bar n date , lc(black) fc(black) fi(100) barw(2)) ///
  		(line tariff date , lc(dkgreen) fc(dkgreen) lw(thick) yaxis(2) ) ///
  		, $graph_opts xsize(8) ///
  		legend(on ring(0) c(1) pos(11) symxsize(small) symysize(small) ///
  			order(2 "Headline Tariff (GBP/kWh)" 3 "Daily Installations" 1 "Policy Shock Periods" )) ///
  		xtit(" ") ytit(" ") ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
  		ytit(, axis(2)) ytit(, axis(1))  yscale(alt) yscale( noline axis(2)) ylab(0 "0.00" .2 "0.20" .4 "0.40" .6 "0.60" .8 "0.80" 1 `""GBP" "1.00""' , axis(2))

  		graph export "${datadir}/outputs/F1_timeline.eps" , replace

  // Counterfactual
  use "$datadir/Constructed/installs_lsoas.dta" ///
    if date > date("31 July 2012","DMY") , clear

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
  		legend(on ring(0) c(1) pos(11) symxsize(small) symysize(small) ///
  			order(2 "Headline Tariff (GBP/kWh)" 3 "Daily Installations" 1 "Policy Shock Periods" )) ///
  		xtit(" ") ytit(" ") ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
  		ytit(, axis(2)) ytit(, axis(1))  yscale(alt) yscale( noline axis(2)) ylab(0 "0.00" .2 "0.20" .4 "0.40" .6 "0.60" .8 "0.80" 1 `""GBP" "1.00""' , axis(2))

      graph export "${datadir}/outputs/F2_counterfactual.eps" , replace

// Table 1. Summary statistics

	// Panel A: Installation Level

		use "$datadir/Constructed/installs_lsoas.dta",clear

			drop if installed_capacity == .
			replace income = installed_capacity * tariffpkwh * 8.50

			sumstats ///
				(tariffpkwh installed_capacity income) ///
				(urban density_hh households social_ab own_own hh_flat work_unemp) ///
				using "${datadir}/outputs/1a_summary.xls" , replace stats(mean sd min p25 p50 p75 max N)

	// Panel B: LLSOA Level

		use "$datadir/Constructed/installs_lsoas.dta",clear

			replace income = installed_capacity * tariffpkwh * 8.50

			labelcollapse (mean) urban density_hh households social_ab own_own hh_flat work_unemp ///
				(sum) installed_capacity income, by(llsoa) fast

				sumstats ///
				(installed_capacity income) ///
				(urban density_hh households social_ab own_own hh_flat work_unemp) ///
				using "${datadir}/outputs/1b_summary.xls" , replace stats(mean sd min p25 p50 p75 max N)

// Table 2: Tariff Rates

	insheet using "${datadir}/Data/Raw/tarifftable2015.csv" ,  clear

	keep if regexm(tariffcode,"PV") & regexm(tariffcode,"0-4")
	keep if fityr == 6
	sort description
	drop fityr

	export excel using "${datadir}/outputs/2_tariffs.xlsx" , replace first(varl)

// Table 3. Model calibration

	use "$datadir/Constructed/ts_lsoas_date.dta" ///
    if period < 7 , clear
    label var total2 "Households w/o installations"

    local model tariffpkwh total2 social_ab own_own hh_flat work_unemp urban density_hh

    local regs ""
    foreach var in capacity income {
      reg `var' `model' ///
        , cl(llsoa)
        est sto reg_`var'

      reg `var' `model' shock ///
        , cl(llsoa)
        est sto reg_`var'_shock

      areg `var' total2 shock i.time ///
        , cl(llsoa) a(llsoa_code)
        est sto reg_`var'_time

      local regs "`regs' reg_`var' reg_`var'_shock reg_`var'_time "
    }

	outwrite `regs' using "${datadir}/outputs/3_model.xlsx" , replace stats(N r2)

// Table 4. Main effect

	// Period-wise
  use "$datadir/Constructed/ts_lsoas_date.dta" ///
    if period < 7 , clear

    local model shock total2 1.shock#c.(social_ab own_own hh_flat work_unemp urban density_hh)

    local regs ""
    foreach time in 1 3 5 {
      foreach var in capacity income {
        areg `var' `model' if time == `time' ///
          , cl(llsoa) a(llsoa_code)
          est sto reg_`var'_`time'
          local regs "`regs' reg_`var'_`time'"
      }
    }

    outwrite `regs' using "${datadir}/outputs/4a_piecewise.xlsx" , replace stats(N r2) drop(i.time total2)

	// Full effect
  use "$datadir/Constructed/ts_lsoas_date.dta" ///
    if period < 7 , clear

    local model shock total2 1.shock#c.(social_ab own_own hh_flat work_unemp urban density_hh)

    local regs ""
    foreach var in capacity income {
      areg `var' `model' i.time ///
        , cl(llsoa) a(llsoa_code)
        est sto reg_`var'
        local regs "`regs' reg_`var'"
    }

    outwrite `regs' using "${datadir}/outputs/4b_overall.xlsx" , replace stats(N r2) drop(i.time total2)

	// Counterfactual - simulated shocks
	use "$datadir/Constructed/ts_lsoas_date.dta"  ///
		if period > 6 , clear

      local model i.time shock total2 1.shock#c.(social_ab own_own hh_flat work_unemp urban density_hh)

      local regs ""
      foreach var in capacity income {
        areg `var' `model' ///
          , cl(llsoa) a(llsoa_code)
          est sto reg_`var'
          local regs "`regs' reg_`var'"
      }

      outwrite `regs' using "${datadir}/outputs/4c_counterfactual.xlsx" , replace stats(N r2) drop(i.time total2)



// Have a lovely day!
