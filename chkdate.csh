#!/bin/csh
set WorkDir=/simenvi.a/model/cayang/Taipower/simenvi/proj001/wrf/data/wrfout
set nowYYMMDD=`date +%Y%m%d`
set WRFDir=$WorkDir"/"$nowYYMMDD"12"
echo $WRFDir
set tmstart = `date --date="$nowYYMMDD"-8days +%Y%m%d`
set tmend = `date --date="$nowYYMMDD"-1days +%Y%m%d`
echo $tmstart
echo $tmend

## Yesterday's WRF RUN
#nohup /simenvi.a/model/cayang/Taipower/forecast/forecast.csh 1 1 1 1 00 12 96 360 >& /simenvi.a/model/cayang/Taipower/forecast/forecast.log & 
wait
## Check For Performance of All Date WRF 
#python chkdate.py
wait
#sqlite3 SimEnvi.DB
#select * from WRFDate
