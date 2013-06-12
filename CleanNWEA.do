
* Cleans NWEA data for Utica
* Updated June 11, 2013 at 8pm
* need to update this with macros

** Something weird is going on with Winter -- do we have hidden strings?
* Verify that the data is as raw as it can get

clear all
foreach season in Fall Winter Spring {

cd "/Users/maya/Documents/NWEA/Utica 2012-2013/"
insheet using "`season'/AssessmentResults.csv", clear

drop measurements growthmeasure testtype testduration rittoreading* *range *adjective ///
	goal5* goal6* goal7* goal8* teststarttime percentcorrect projectedprof ///
	typicalfalltofallgrowth typicalspringtospringgrowth
	
drop if discipline=="Science"

* Drop duplicates
gsort studentid discipline -testritscore
duplicates drop studentid discipline, force

* Reshape into one row per student-goal

forvalues n=1/4 {
	rename goal`n'name name`n'
	rename goal`n'ritscore score`n'
	rename goal`n'stderr se`n'
	}

reshape long name score se, i(studentid discipline) j(goal)

order studentid discipline goal name score se, first

gen domain1 = ""
gen domain2 = ""

* Mathematics mappings
replace domain1 = "OA" if name=="Algebra & Functions"
replace domain2 = "EE" if name=="Algebra & Functions"
replace domain1 = "OA" if name=="Algebra and Functions"
replace domain2 = "EE" if name=="Algebra and Functions"

replace domain1 = "OA" if name=="Operations and Algebraic Thinking"
replace domain2 = "EE" if name=="Operations and Algebraic Thinking"

replace domain1 = "OA" if name=="Algebraic Concepts"
replace domain2 = "EE" if name=="Algebraic Concepts"

replace domain1 = "OA" if name=="Problem Solving"
replace domain2 = "EE" if name=="Problem Solving"

replace domain1 = "OA" if name=="Algebraic Thinking"
replace domain2 = "EE" if name=="Algebraic Thinking"

replace domain1 = "NBT" if name=="Real & Complex Number Systems"
replace domain2 = "NS" if name=="Real & Complex Number Systems"
replace domain1 = "NBT" if name=="Real and Complex Number Systems"
replace domain2 = "NS" if name=="Real and Complex Number Systems"

replace domain1 = "G" if name=="Geometry"
replace domain1 = "G" if name=="Graphing"

replace domain1 = "SP" if name=="Statistics & Probability"
replace domain1 = "SP" if name=="Statistics and Probability"
replace domain1 = "SP" if name=="Statistics / Probability"

replace domain1 = "NBT" if name=="Computation"
replace domain2 = "NS" if name=="Computation"

replace domain1 = "NBT" if name=="Number Sense"
replace domain2 = "NS" if name=="Number Sense"

replace domain1 = "NBT" if name=="Numbers & Operations"
replace domain2 = "NS" if name=="Numbers & Operations"
replace domain1 = "NBT" if name=="Numbers and Operations"
replace domain2 = "NS" if name=="Numbers and Operations"

replace domain1 = "NBT" if name=="Number and Operations in Base Ten"
replace domain2 = "NS" if name=="Number and Operations in Base Ten"
replace domain1 = "NBT" if name=="Number & Operations in Base Ten"
replace domain2 = "NS" if name=="Number & Operations in Base Ten"

replace domain1 = "NBT" if name=="Number & Operations"
replace domain2 = "NS" if name=="Number & Operations"
replace domain1 = "NBT" if name=="Number and Operations"
replace domain2 = "NS" if name=="Number and Operations"

replace domain1 = "MD" if name=="Measurement"
replace domain1 = "MD" if name=="Measurement & Data"
replace domain1 = "MD" if name=="Measurement and Data"

replace domain1 = "NF" if name=="Fractions"

* Reading mappings
replace domain1 = "RL" if name=="Literature"

replace domain1 = "RI" if name=="Informational Text"

replace domain1 = "RF" if name=="Foundations/Vocabulary"
replace domain1 = "RF" if name=="Foundations / Vocabulary"
replace domain1 = "RF" if name=="Foundational Skills"

replace domain1 = "RL" if name=="Literature and Informational"
replace domain2 = "RI" if name=="Literature and Informational"
replace domain1 = "RL" if name=="Literature & Informational"
replace domain2 = "RI" if name=="Literature & Informational"

replace domain1 = "L" if name=="Language and Writing"
replace domain1 = "L" if name=="Language & Writing"

replace domain1 = "L" if name=="Writing and Language"
replace domain1 = "L" if name=="Writing & Language"

* Language mappings
replace domain1 = "L" if name=="Understand Grammar / Usage"
replace domain1 = "L" if name=="Punctuate / Spell Correctly"

* Check mappings
* R: Vocabulary Use and Functions ->	N/A
* R: Vocabulary and Functions ->	N/A
* L: Plan / Organize / Research -> N/A
tab name if domain1=="" & discipline=="Mathematics"
tab name if domain1=="" & discipline=="Reading"
tab name if domain1=="" & discipline=="Language Usage"

* Determine duplicates in domain. With L, just average the duplicates
duplicates tag studentid domain1, g(tag)
tab domain1 if tag>0

* Create new row if the score maps to two domains
expand 2 if domain2!="", gen(copy)
replace domain1 = domain2 if copy==1
drop domain2 copy
save temp.dta, replace

* L needs to be dealt with separately because of duplicates
foreach d in EE G MD NBT NF NS OA RF RI RL SP {
use temp.dta, clear
keep if domain=="`d'"
keep studentid score se typicalfalltospringgrowth testritscore testpercentile
rename score score`season'`d'
rename se se`season'`d'
rename testritscore OverallRIT`season'
rename testpercentile OverallPtile`season'
save temp`d'.dta, replace
}

use temp.dta, clear
keep if domain=="L"
keep studentid testritscore teststandarderr typicalfalltospringgrowth testpercentile
rename testritscore score`season'L
rename teststandarderr se`season'L
gen OverallRIT`season' = score`season'L
rename testpercentile OverallPtile`season'
duplicates drop
save tempL.dta, replace

foreach d in EE G MD NBT NF NS OA RF RI RL SP {
merge 1:1 studentid using temp`d'.dta, nogen
}
compress
save "Clean_`season'.dta", replace
}

merge 1:1 studentid using Clean_Winter.dta, nogen
drop typ*
merge 1:1 studentid using Clean_Fall.dta, nogen

foreach d in EE G L MD NBT NF NS OA RF RI RL SP {
	gen growthFallToSpring`d' = (scoreSpring`d' - scoreFall`d') / typicalfalltospringgrowth
	gen growthWinToSpring`d' = (scoreSpring`d' - scoreWinter`d') / (typicalfalltospringgrowth / 2)
	}
keep studentid growth* Overall*
rename studentid nwea_id

* Create columns for SRR, SRM, CC
foreach s in Fall Win {
	gen growth`s'ToSpringSRR = growth`s'ToSpringRF
	gen growth`s'ToSpringSRM = growth`s'ToSpringNBT
	gen growth`s'ToSpringCC = growth`s'ToSpringNBT
}

cd "/Users/maya/Documents/NWEA/Utica 2012-2013/"
save CleanNWEA.dta, replace

