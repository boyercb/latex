/*
EXAMPLE OF PROGRAM WHICH PUTS CUSTOM OUTPUT INTO A ESTOUT TABLE USING AN E-CLASS FUNCTION

BY: JONATHAN HOLMES (jholmes.hks@gmail.com)
SEPTEMBER 4, 2013

*/


capture program drop corr_table
program define corr_table, eclass
	/*	The following program is meant to provide the results from "reg <depvar> <variable>, <condlist>" for every <variable> in <varlist>.
		It then exports the results in e() as if it were a regression to be able to create a nice estout table. 	*/
		
	syntax varlist, depvar(varname) condlist(string asis) 
	
	tempname est_b est_V b V se nobs
	
	foreach var of local varlist {
		*HERE is the regression
		reg `depvar' `var', `condlist'
		
		*Save results from regression
		mat `est_b' = e(b)
		mat `est_V' = e(V)
		
		*Construct the fake "regression matrixes" which look like the results from a normal reg function
		mat `b'    	= nullmat(`b')   , `est_b'[1,1]
		mat `se' 	= nullmat(`se')  , `=sqrt(`est_V'[1,1])'
		mat `nobs'  = nullmat(`nobs'), e(N)
			
	}

	*Label the output matricies
	foreach mat in b se nobs{
		 mat coln ``mat'' = `varlist'
		 mat rown ``mat'' = `depvar'
	 }
	 
	 *Construct the fake "variance matrix" (only the diagonal matters to calculate t-statistics)
     mat `V' = `se''*`se'
	 
	 *Return the results in e() to be read by eststo. 
     eret post `b' `V', depname("`depvar'")
     eret local cmd "corr_table"
     foreach mat in nobs {
         eret mat `mat' = ``mat''
     }
	
end


sysuse auto.dta

eststo clear
eststo: corr_table headroom trunk weight length turn displacement gear_ratio, depvar(price) condlist(robust)
eststo: corr_table headroom trunk weight length turn displacement gear_ratio, depvar(mpg) condlist(robust)
esttab
