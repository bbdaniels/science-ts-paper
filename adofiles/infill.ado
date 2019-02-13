// Program to infill after tsfill

cap prog drop infill
prog def infill

syntax varlist , by(varlist)

tempname temp

foreach var of varlist `varlist' {
  bys `by' : egen `temp' = min(`var')
  replace `var' = `temp' if `var' == .
  drop `temp'
}

end

// Have a lovely day!
