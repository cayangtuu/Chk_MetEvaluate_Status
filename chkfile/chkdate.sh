#!/bin/bash 
ulimit -c unlimited

### Setting Area ###

MainDir=/path/to/main/directory
ChkDir=${MainDir}/path/to/chkfile
DDtmpDir=${MainDir}/path/to/wrf/data 
DDataDir=${DDtmpDir}
wktmpDir=${MainDir}/path/to/wrf/wktmp

### End Of Setting Area ###


### Executing Area ###

### Anaconda
export CondaDIR=${MainDir}/calpuff/anaconda3
export PATH=$CondaDIR/bin:$PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$CondaDIR/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
   eval "$__conda_setup"
else
   if [ -f "${CondaDIR}/etc/profile.d/conda.sh" ]; then
      . "${CondaDIR}/etc/profile.d/conda.sh"
   else
      export PATH="${CondaDIR}/bin:$PATH"
   fi
fi
unset __conda_setup
# <<< conda initialize <<<

### Initial Parameter
nowtag=`date +%Y%m%d%H`
nowYMD=`echo $nowtag | cut -c 1-8`
nowHH=`echo $nowtag | cut -c 9-10`
tmstart=`date --date="$nowYMD"-8days +%Y%m%d`
tmend=`date --date="$nowYMD"-1days +%Y%m%d`
echo "Working Times: "$nowtag
echo "Date Range: From "$tmstart" to "$tmend
echo ""

### Running WRF of Yesterday 
echo "***Running WRF of Yesterday***"
nohup ${MainDir}/forecast/forecast.csh 1 1 1 1 00 12 96 360 >& \
${MainDir}/forecast/forecast.log 
wait

### Check For Performance of WRF in Whole Period
echo "***Check For Performance of WRF***"
cd ${ChkDir}
conda activate pm25plot
python chkdate.py >& chkdate_${nowYMD}.out
wait

### Rerun WRF On Specific Date Determined By BadTable.txt
echo "***Rerun WRF On Specific Date***"
cd ${ChkDir}
echo `cat BadTable.txt`
for runTT in `cat BadTable.txt`; do
  if [[ $((10#$nowHH + 1)) -ge 2 && $((10#$nowHH + 1)) -lt 18 ]]; then
  echo ""
  echo "Rerun Date: "$runTT
  echo "Start of Running Hour: "$nowHH

  ### Remove WRF File and Forder On Specific Date
  # Remove Temporary Working Folder
  echo "Remove WRF Forder" 
  wktmpNm=`find "${wktmpDir}/${runTT}12_"*"/" -maxdepth 0`
  if [[ -d $wktmpNm ]]; then
     /bin/rm -rf ${wktmpDir}/${runTT}12_*
  fi
  # Remove Temporary Data Folder or Link(gfs & wrfout)
  if [[ -d ${DDtmpDir}/gfs/gfs.${runTT}12 ]]; then
     /bin/rm -rf ${DDtmpDir}/gfs/gfs.${runTT}12
  fi
  if [[ -f ${DDtmpDir}/wrfout/wrfout.${runTT}12 ]]; then
     /bin/rm -f ${DDtmpDir}/wrfout/wrfout.${runTT}12
  fi
  # Remove Data Folder(gfs & wrfout)
  if [[ -d ${DDataDir}/gfs/gfs.${runTT}12 ]]; then
     /bin/rm -rf ${DDataDir}/gfs/gfs.${runTT}12
  fi
  if [[ -d ${DDataDir}/wrfout/wrfout.${runTT}12 ]]; then
     /bin/rm -rf ${DDataDir}/wrfout/wrfout.${runTT}12
  fi
  wait

  ### Running WRF On Specific Date
  echo "Running WRF"
  nohup ${MainDir}/forecast/forecast.csh 1 2 1 1 ${runTT}1800 12 96 360 >& \
  ${MainDir}/forecast/forecast.log 
  wait
  ### Check For Performance of WRF in Whole Period
  echo "Check For Performance of WRF"
  cd ${ChkDir}
  conda activate pm25plot
  python chkdate.py >& rechkdate_${nowYMD}.out
  wait
  nowHH=`date +%H`
  echo "End of Running Hour: "$nowHH

  else echo "End of Running Due to "$nowHH
fi
done
echo "Finished"

### End Of Executing Area ###
