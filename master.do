// Master dofile for time series paper

//	Set up directory

	global directory "/Users/bbdaniels/GitHub/science-ts-paper/"

// Globals

	global graph_opts ///
		title(, justification(left) color(black) span pos(11)) ///
		graphregion(color(white) lc(white) lw(med) la(center)) /// <- Delete la(center) for version < 15
		ylab(,angle(0) nogrid) xtit(,placement(left) justification(left)) ///
		yscale(noline) xscale(noline) legend(region(lc(none) fc(none)))

	global graph_opts1 ///
		title(, justification(left) color(black) span pos(11)) ///
		graphregion(color(white) lc(white) lw(med) la(center)) /// <- Delete la(center) for version < 15
		ylab(,angle(0) nogrid)  ///
		yscale(noline) legend(region(lc(none) fc(none)))

// Dofiles





// Have a lovely day!
