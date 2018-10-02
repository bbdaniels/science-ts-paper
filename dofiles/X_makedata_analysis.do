* Make analysis datasets

	* Installs
	
		use "$datadir/Data/Public/installs_lsoas.dta", clear	
			
			gen period = .
			
			replace period = 13 if date <= date("30 Jun 2015","DMY")
			replace period = 12 if date <  date("1 Apr 2015","DMY")
			replace period = 11 if date <  date("1 Jan 2015","DMY")
			replace period = 10 if date <  date("1 Oct 2014","DMY")
			replace period = 9  if date <  date("1 Jan 2014","DMY")
			replace period = 8  if date <  date("1 Jul 2013","DMY")
			replace period = 7  if date <  date("1 Nov 2012","DMY")

			replace period = 6  if date <  date("Aug 1, 2012","MDY")
			replace period = 5  if date <= date("May 24, 2012","MDY")
			replace period = 4  if date <= date("Mar 2, 2012","MDY")
			replace period = 3  if date <= date("Jan 25, 2012","MDY")
			replace period = 2  if date <= date("Dec 12, 2011","MDY")
			replace period = 1  if date <= date("Oct 31, 2011","MDY")
			
			replace income = installed_capacity * tariffpkwh * 8.50
				label var income "Annual Income (GBP)"

		save "$datadir/Constructed/installs_lsoas.dta", replace	
	
	* Period Length 
	
		use "$datadir/Constructed/installs_lsoas.dta", clear
	
		collapse (max) maxdate = date (min) mindate = date (p99) tariffpkwh , by(period) fast
			drop if period == .
		
		tsset period
			replace mindate = l.maxdate+1 if period > 1
			
		gen period_days = maxdate-mindate
			gen period_mid = (maxdate+mindate)/2

		label var maxdate "Period End"
		label var mindate "Period Start"
		label var period_days "Period Length"
		
		tempfile periods
			save `periods' , replace
		
	* Time Series
	
		use "$datadir/Constructed/installs_lsoas.dta", clear
		
			merge m:1 period using `periods' , nogen update replace
			
				gen time = period
				replace time = time - 1 if (period == 2 | period == 4 | period == 6 ) 
			
				replace period = period*2 - 7 if period > 6
				replace period = period+1 if period > 6 & date > period_mid
				replace shock = 1 if period > 6 &  date > period_mid
				
			preserve 
				collapse (max) maxdate = date (min) mindate = date (p99) tariffpkwh , by(period) fast
				drop if period == .
				gen period_days = maxdate-mindate
				save `periods' , replace
			restore
			
		
			encode llsoa , gen(llsoa_code)
			
			preserve
				keep hh_flat work_unemp own_own own_mortgage social_ab ///
					density_hh households urban llsoa_code
					
				bys llsoa_code: gen place = _n
				keep if place == 1
					drop place
					
				tempfile chars
				save `chars' , replace
			restore 
		
			gen n_installs = (installed_capacity != 0 & installed_capacity != .)
			collapse (rawsum) installed_capacity n_installs (mean) time shock period_days , by(llsoa_code period) fast
				drop if period == .
				tsset llsoa_code period
				merge m:1 llsoa_code using `chars' , update replace nogen
				replace period = 1 if period == .
				tsfill , full
				replace installed_capacity = 0 if installed_capacity == .
				merge m:1 llsoa_code using `chars' , update replace nogen

			
			merge m:1 period using `periods' , nogen update replace
			
			tostring time, force replace
			replace time = string(period/2 + 0.9)
			replace time = substr(time,1,strpos(time,".")-1)
			destring time, force replace
			
			replace shock = time == (period/2)
			
			gen income = installed_capacity * tariffpkwh * 8.50
			
			gen income_day = income / period_days
			gen capacity_day = installed_capacity / period_days
			
			replace n_installs = 0 if n_installs == .
			bys llsoa: gen count = sum(n_installs) - n_installs
			
			gen total2 = households - count
			label var total2 "Households Without Installations"

			label var income "Annual Income (GBP)"
				
			label var tariffpkwh "Headline Tariff"
			label var shock "Policy Shock Period"
			label var urban "Urban Area"
			
			compress
			
		save "$datadir//Constructed/ts_lsoas.dta", replace 

	
	





* Have a lovely day!
