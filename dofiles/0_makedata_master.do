* Some of the files in this folder are used to compile the analysis-ready dataset.
* These must be run in a specific order but each saves progress after a major operation.
* This enables edits to be made at later stages without re-running all processes.

ieboilstart, v(13)
`r(version)'

global datadir "/Users/bbdaniels/GitHub/science-ts-paper"

	global graph_opts bgcolor(white) title("") note(, justification(left) color(black) span pos(7)) title(, justification(left) color(black) span pos(11)) subtitle(, justification(left) color(black) span pos(11)) graphregion(color(white)) ylab(,angle(0) nogrid) ytit("") xtit(,placement(left) justification(left)) yscale(noline) xscale(noline) legend(region(lc(none) fc(none)))
	global graph_opts1 bgcolor(white) graphregion(color(white)) legend(region(lc(none) fc(none))) ylab(,angle(0) nogrid) title(, justification(left) color(black) span pos(11)) subtitle(, justification(left) color(black))
	global comb_opts graphregion(color(white))
	global hist_opts ylab(, angle(0) axis(2)) yscale(off alt axis(2)) ytit(, axis(2)) ytit(, axis(1))  yscale(alt)
	global pct `" 0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%" "'
	global numbering `""(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)" "(9)" "(10)""'

qui do "${datadir}/Adofiles/tabstatout.ado"
// qui do "${datadir}/Adofiles/sumstats.ado"
qui do "${datadir}/Adofiles/labelcollapse.ado"
qui do "${datadir}/Adofiles/xiplus.ado"

	-

* Files:

qui do "${datadir}/1_makedata_importreport.do"
	* reads the current OFGEM report into Stata
	* output is saved as CurrentReport.dta

do $datadir\Dofiles\makellsoamerge.do
	* merges the raw 2011 Census data onto CurrentReport.dta, then appends LLSOAs which have no installations
	* output is saved as masterdata.dta

do $datadir\Dofiles\makellsoadata.do
	* collapses masterdata.dta into an LLSOA-level dataset; adds data from CES (LSOA_data\)
	* output is saved as llsoadata.dta

do $datadir\Dofiles\makellsoapanel.do
	* opens llsoadata.dta and adds fields for new and cumulative installations by year, plus "early" adopters
	* output is saved as llsoapaneldata.dta
