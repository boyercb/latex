/*
EXAMPLE OF PROGRAM WHICH CREATES A COMPLEX, NICE TABLE IN LATEX
BY: JONATHAN HOLMES (jholmes.hks@gmail.com)
SEPTEMBER 4, 2013
*/



/* The Easy Part - Run the Regressions! */
sysuse auto.dta, clear

tab rep78, gen(rep78_)

//Note - each estimate is stored with a name. This is important because we refer to them later. 
eststo clear
eststo ols1: reg price mpg headroom  if foreign == 1
eststo ols2: reg price mpg headroom rep78_1 rep78_2 rep78_3 rep78_4 if foreign == 1 
eststo ols3: reg price mpg headroom if foreign == 0
eststo ols4: reg price mpg headroom rep78_1 rep78_2 rep78_3 rep78_4 if foreign == 0

sort mpg
eststo fe1: areg price mpg headroom  if foreign == 1, absorb(turn)
eststo fe2: areg price mpg headroom rep78_1 rep78_2 rep78_3 rep78_4 if foreign == 1, absorb(turn)
eststo fe3: areg price mpg headroom if foreign == 0, absorb(turn)
eststo fe4: areg price mpg headroom rep78_1 rep78_2 rep78_3 rep78_4 if foreign == 0, absorb(turn)




/* Table Creation Functions */
//COMBINE MODELS - USE THIS FUNCTION (OR A VARIENT)
//(See the other do-file for an explanation of what this does)
cap program drop combine_models
program define combine_models, eclass
	syntax namelist (name=estimates id ="Estimates"), headings(namelist)
	
	tempname  b V rawV est_b est_V
	local counter 0
	foreach est of local estimates { 
		local ++counter
		gettoken heading headings: headings
		estimates restore `est'
		mat `est_b' = e(b)
		mat `est_V' = vecdiag(e(V))
		mat colnames `est_b' = `heading':
		mat colnames `est_V' = `heading':
		mat `b' = nullmat(`b') , `est_b'
		mat `rawV' = nullmat(`rawV'), `est_V'
		local N`counter' = e(N)
		local r2`counter' = e(r2)
	}
	mat define `V' = diag(`rawV')
	eret post `b' `V', depname("`=e(depvar)'") 
	forvalues n = 1/`counter'{
		ereturn scalar N`n' = `N`n''
		ereturn scalar r2`n' = `r2`n''
	}
end

/* Combine estimates into columns using the function we defined. */
forvalues x = 1/4{
	eststo combined`x': combine_models ols`x' fe`x', headings(ols fe)
}

/* Create the latex table! */
#delimit ;
esttab combined1 combined2 combined3 combined4 using auto-results.tex, 	   
		//Change the significance stars to whatever p-values suit you. Can also use other symbols too. 
		star(* .10 ** .05 *** .01) 
		
		//Set the format for the point estimates and standard errors
		b(%5.1f) se(%5.1f)
		
		
		//Coefficients for these controls do not appear in the table, but instead have a row in the bottom
		//of the table indicating that they exist. The stars are wildcads.
		//Note that if we just wanted to drop them and omit the row at the bottom of the table, we would use 
		//drop("") instead. 
		indicate("Repair Dummies = *rep78*")
		
		//Change the order of the coefficients
		order(headroom mpg)
	
		//Set the alignment of a table column. 
		/*	Alignments: 
			l - left
			c - center
			r - right
			S - scientific (requires siunitx, for aligning the decimal point in a column). 		*/
		
		alignment(S[table-format = 5.3])
		
		//Label the table rows
		label
		//Note: Coeflabels overwrites what is in 'label'
		coeflabels(
			mpg "Miles Per Gallon"
			headroom "Headroom"
		)
	
		
		//Label the subheadings - note that this only works for models with multiple panels (eg: Probit has both point estimates and marginal effects)
		eqlabels(
			//Embed latex code into the labels (emphasis)
			"\emph{Panel A: OLS Regressions}"
			"\emph{Panel B: Fixed Effects Regressions, Controlling for Headroom}", 
			
			//prefix is added before every eqlabel, and suffix after every exlabel. 
			//Span forces column to span accross rows, and @span is the width of the table
			// \addlinespace[1mm] adds extra space before table row. 
			prefix(\addlinespace[1mm] \multicolumn{@span}{l}{) suffix(}) span
		)
		
		
		//Label the "equation groups"
			//Multicolumn makes the command span accross rows. 
			//specialcell allows for line breaks in the cell (specialcell is a command that is defined in my latex document). 
			//An alternative to specialcell is to just insert a tabular inside the table. 
		mgroups(
			"\specialcell{Foreign \\ (Eg: Audi 5000)}"
			"\specialcell{Local \\ (Eg: AMC Concord)}", 
			
			pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span)
		
		nomtitles
		
		
		noobs stats(
				N1 N2 r21 r22, 
			labels(
				"Model 1 Observations" 
				"Model 2 Observations" 
				"Model 1 R2"
				"Model 2 R2"
			)
			layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}")	
			fmt("a3" "a3" "%3.2f" "%3.2f")
		)
		
		
		
		//Notes for the bottom of the table. No nonte removes the normal significance stars message. 
		addnote(
			"This is a very long note which will force the table to have a huge width if it weren't for the substitute command which follows."
			
		)

		
		//This is where some of the questionable coding practices in Latex sprout up. 
		
		//The first part of this next line substitute({l} {p{\linewidth}}) is is the code which allows for notes to span accross multiple lines. 
		//It relies on a function I found on stack overflow which sets the size of the table to \linewidth. 
		//See http://www.jwe.cc/2012/03/stata-latex-tables-estout/ for an example of this same effect using threeparttable instead. 
		
		//The second part of the next line is required in order to use siunitex, because siuitex crashes when it encounters regular text. 
			
		substitute({l} {p{\linewidth}} 					No {No} Yes {Yes})
		
		//Booktabs are slightly nicer tables. 
		booktabs replace
;
	
	
#delimit cr
