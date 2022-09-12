#!/bin/csh

### Setting Area ###

set ChkDir = `pwd`
set MainDir = /simenvi.a/model/cayang/Taipower
set DDtmpDir = ${MainDir}/simenvi/proj001/wrf/data 
set DDataDir = ${DDtmpDir}
set wktmpDir = ${MainDir}/simenvi/proj001/wrf/wktmp

### End Of Setting Area ###


### Executing Area ###

### Anaconda
setenv CondaDIR ${MainDir}/calpuff/anaconda3

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if ($? != 0 ) then
   eval "$__conda_setup"
   if ( -f ${CondaDIR}/etc/profile.d/conda.csh ) then
      source ${CondaDIR}/etc/profile.d/conda.csh
   else
      setenv PATH "${CondaDIR}/bin:$PATH"
   endif
endif
unset __conda_setup
# <<< conda initialize <<<

### Initial Parameter
set nowtag = `date +%Y%m%d%H`
set nowYMD = `echo $nowtag | cut -c 1-8`
set nowHH  = `echo $nowtag | cut -c 9-10`
set tmstart = `date --date="$nowYMD"-8days +%Y%m%d`
set tmend = `date --date="$nowYMD"-1days +%Y%m%d`

### Running WRF Yesterday 
#nohup ${MainDir}/forecast/forecast.csh 1 1 1 1 00 12 96 360 >& \
#${MainDir}/forecast/forecast.log 
wait

### Check For Performance of WRF in Whole Period
conda activate Taipower
nohup python ${ChkDir}/chkdate.py >& ${ChkDir}/chkdate.out
wait

### Rerun WRF On Specific Date Determined By BadTable.txt
cd ${ChkDir}
set readFil=`cat BadTable.txt`
set BadDate=1
while ( $BadDate < = $#readFil & ($nowHH>2 | $nowHH<18))
  echo $readFil[$BadDate]
  set runTT = "$readFil[$BadDate]1800"

  ### Remove WRF File and Forder On Specific Date
  # 刪除站存工作資料夾
  if ( -d ${wktmpDir}/$readFil[$BadDate]12_* ) then
     /bin/rm -rf ${wktmpDir}/$readFil[$BadDate]12_*
  endif
  # 刪除暫存資料夾(gfs & wrfout)
  if ( -d ${DDtmpDir}/gfs/gfs.$readFil[$BadDate]12) then
     /bin/rm -rf ${DDtmpDir}/gfs/gfs.$readFil[$BadDate]12
  endif
  if ( -f ${DDtmpDir}/wrfout/wrfout.$readFil[$BadDate]12) then
     /bin/rm -f ${DDtmpDir}/wrfout/wrfout.$readFil[$BadDate]12
  endif
  # 刪除檔案資料夾(gfs & wrfout)
  if ( -d ${DDataDir}/gfs/gfs.$readFil[$BadDate]12) then
     /bin/rm -rf ${DDataDir}/gfs/gfs.$readFil[$BadDate]12
  endif
  if ( -d ${DDataDir}/wrfout/wrfout.$readFil[$BadDate]12) then
     /bin/rm -rf ${DDataDir}/wrfout/wrfout.$readFil[$BadDate]12
  endif
  wait

  ### Running WRF On Specific Date
  nohup ${MainDir}/forecast/forecast.csh 1 2 1 1 ${runTT} 12 96 360 >& \
  ${MainDir}/forecast/forecast.log 
  wait
  ### Check For Performance of WRF in Whole Period
  conda activate Taipower
  nohup python ${ChkDir}/chkdate.py >& ${ChkDir}/chkdate.out
  wait
  @ BadDate = $BadDate + 1
end

### End Of Executing Area ###
