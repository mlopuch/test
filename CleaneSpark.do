* Clean eSpark data for end of year analysis for Utica
* June 11, 2013

clear all
cd "/Users/maya/Documents/PD/TestAnalyses/Utica"

******* Load eSpark data
insheet using eSparkPull.csv, clear
rename nwea_student_id nwea_id
drop if began_on=="NULL"
gen complete = completed_activity_count/activity_count
gen began = date(began_on, "YMD###")

gen fall_end = date("2012-12-31","YMD")
gen win_begin = date("2013-01-01","YMD")
gen fall = (began<fall_end)
gen winter = (began>=win_begin)
drop school section domain_description completed completed_activity_count activity_count ///
	closed_on attempt began fall_end win_begin began_on

* When students loop in the same term, keep the record with the highest completion rate
gsort student_id domain -complete
duplicates drop student_id grade_level domain, force

save temp.dta, replace

insheet using eSparkLogins.csv, clear
rename days DaysLoggedIn
merge 1:m student_id using temp.dta, keep(match) nogen

save CleaneSpark.dta, replace

