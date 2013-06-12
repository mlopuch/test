
* Cleans NWEA-name link and demog data for Island Park
* Updated June 10, 2013

clear all
foreach season in Fall Winter Spring {

cd "/Users/maya/Documents/NWEA/Island Park 2012-2013/"

insheet using "`season'/StudentBySchool.csv", clear
keep studentlastname studentfirstname studentethnicgroup studentid studentgender grade
foreach v in lastname firstname ethnicgroup gender {
	rename student`v' `v'
	}
rename studentid nwea_id
rename grade actual_grade

save Demog_`season'.dta, replace
}

merge 1:1 nwea_id using Demog_Winter.dta, nogen
merge 1:1 nwea_id using Demog_Fall.dta, nogen

gen ethnic=""
replace ethnic = "A" if ethnicgroup == "Asian                         "
replace ethnic = "B" if ethnicgroup == "Black                         "
replace ethnic = "W" if ethnicgroup == "White                         "
replace ethnic = "H" if ethnicgroup == "Hispanic"
drop ethnicgroup

gen grade_group = ""
replace grade_group = "1-2" if actual_grade<3
replace grade_group = "3-5" if actual_grade>=3 & actual_grade<=5
replace grade_group = "6-8" if actual_grade>=6 & actual_grade<=8

sort nwea_id
duplicates drop firstname lastname, force
save DemogFull.dta, replace
