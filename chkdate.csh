#!/bin/csh
set WorkDir=/simenvi.a/model/cayang/Taipower/simenvi/proj001/wrf/data/wrfout
set nowYYMMDD=`date +%Y%m%d`
set WRFDir=$WorkDir"/"$nowYYMMDD"12"
echo $WRFDir
set tmstart = `date --date="$nowYYMMDD"-7days +%Y%m%d`
set tmend = `date --date="$nowYYMMDD"-1days +%Y%m%d`
echo $tmstart
echo $tmend
