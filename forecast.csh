#!/bin/csh
################################################################################
# C shell script to run wrf. Created by Liu on 20170928
# Run: forecast.csh 1 1 1 201709301200 00
# 2nd parameter: 0, 1, 2, option for GFS downloading
# 3rd parameter: 0, 1, option for WPS processing
# 4th parameter: 0, 1, option for WRF processing
# 5th parameter: YYYYMMDDHHMM, job id to specify GFS data (no function if 1st option is 1)
# 6th parameter: 00, 06, 12, 18, GFS forecast hour
# If nothing specified in running parameters, 00 and current time are default.
# Note: job time is presumed local time, and will be translated to GMT time
################################################################################
# User specified settings
################################################################################
# Input parameters
set optrun    = $1   # 1:normal run, 2:test run
set optgfs    = $2   # 1:run at current local time, 2: run at specified GMT time, 0:off
set optwps    = $3   # 1:run, 0:off
set optwrf    = $4   # 1:run, 0:off
set daytag    = $5   # specified GMT time to forecast
set gfshr     = $6   # GFS forecast hour
set runhr     = $7   # Forecast hour
set timestep  = $8   # WRF forecast time step
# default parameters
if ( $daytag == '' ) then
  set daytag = `date +%Y%m%d%H%M`
endif
if ( $runhr == '' ) then
  set runhr = 96
endif
set inchr     = 6    # Time interval hours for GFS data
set errorcode = 0    # Return code of process
# Working directories and path
set worktmp  = /path/to/wktmp
set datadir  = /path/to/data
set wrfdir   = /path/to/WRF
set ncephost = "ftpprd.ncep.noaa.gov"
#set ncephost = "140.90.101.61"
set nceppath = "${ncephost}/data/nccf/com/gfs/prod"
################################################################################
# Don't touch below unless you know what you are doing
################################################################################
# Set working directory
set workYr = `date +%Y`
set workmo = `date +%m`
set workcd = `date +%d`
set workhr = `date +%H`
set workmn = `date +%M`
echo WORK LOCAL TIME: $workYr/$workmo/$workcd ${workhr}:${workmn}
# Add current time to id of work directory
set worktag = ${workYr}${workmo}${workcd}${workhr}${workmn}
# Set running options
if ( $optgfs == 1 ) then
  echo DOWNLOAD GFS AND RUNNING WRF AT CURRENT TIME
  set tzlag  = -8   # GMT related to local time
else if ( $optgfs == 2 ) then
  echo DOWNLOAD GFS AND RUNNING WRF AT SPECIFIED GMT TIME
  set workYr = `echo $daytag | cut -c 1-4`
  set workmo = `echo $daytag | cut -c 5-6`
  set workcd = `echo $daytag | cut -c 7-8`
  set workhr = `echo $daytag | cut -c 9-10`
  set workmn = `echo $daytag | cut -c 11-12`
  set tzlag  = 0
else
  echo RUNNING WRF AT SPECIFIED GMT TIME
  set workYr = `echo $daytag | cut -c 1-4`
  set workmo = `echo $daytag | cut -c 5-6`
  set workcd = `echo $daytag | cut -c 7-8`
  set workhr = `echo $daytag | cut -c 9-10`
  set workmn = `echo $daytag | cut -c 11-12`
  set tzlag  = 0
endif
# Set gfs forecast hour
if ( $gfshr == '' ) then
 set gfshr = '12'
endif
# Set work GMT time
set gmtYr = `date +%Y --date="${tzlag} hour ${workmo}/${workcd}/${workYr} ${workhr}:00:00"`
set gmtmo = `date +%m --date="${tzlag} hour ${workmo}/${workcd}/${workYr} ${workhr}:00:00"`
set gmtcd = `date +%d --date="${tzlag} hour ${workmo}/${workcd}/${workYr} ${workhr}:00:00"`
set gmthr = `date +%H --date="${tzlag} hour ${workmo}/${workcd}/${workYr} ${workhr}:00:00"`
echo JOB GMT TIME: $gmtYr/$gmtmo/$gmtcd ${gmthr}:00
# Set GMT of simulation
set jobsYr = `date +%Y --date="${gmtmo}/${gmtcd}/${gmtYr} ${gfshr}:00:00"`
set jobsmo = `date +%m --date="${gmtmo}/${gmtcd}/${gmtYr} ${gfshr}:00:00"`
set jobscd = `date +%d --date="${gmtmo}/${gmtcd}/${gmtYr} ${gfshr}:00:00"`
set jobshr = `date +%H --date="${gmtmo}/${gmtcd}/${gmtYr} ${gfshr}:00:00"`
echo JOB START GMT TIME: $jobsYr/$jobsmo/$jobscd ${jobshr}:00
set jobeYr = `date +%Y --date="${runhr} hour ${jobsmo}/${jobscd}/${jobsYr} ${jobshr}:00:00"`
set jobemo = `date +%m --date="${runhr} hour ${jobsmo}/${jobscd}/${jobsYr} ${jobshr}:00:00"`
set jobecd = `date +%d --date="${runhr} hour ${jobsmo}/${jobscd}/${jobsYr} ${jobshr}:00:00"`
set jobehr = `date +%H --date="${runhr} hour ${jobsmo}/${jobscd}/${jobsYr} ${jobshr}:00:00"`
echo JOB END GMT TIME: $jobeYr/$jobemo/$jobecd ${jobehr}:00
# Set working directory
if ( $optwps == 1 || $optwrf == 1 ) then
  set workdir = ${worktmp}/${jobsYr}${jobsmo}${jobscd}${jobshr}_${worktag}
  echo WORKING DIRECTORY: $workdir
  mkdir -p $workdir
endif
#
# Download GFS data
#
if ( $optgfs >= 1 && $errorcode == 0 ) then
  echo 'Downloading GFS data'
  set gfssrc = "${nceppath}/gfs.${jobsYr}${jobsmo}${jobscd}/${gfshr}/atmos"
  set gfsdir = "${datadir}/gfs/gfs.${jobsYr}${jobsmo}${jobscd}${gfshr}"

  [ -d $gfsdir ] && rm -r $gfsdir
  mkdir -p $gfsdir
  cd $gfsdir
  @ i = 0
  while ( $i <= $runhr && $errorcode == 0 )
    if ( $i < 10 ) then
      set ihr = 00$i
    else if ( $i < 100 ) then
      set ihr = 0$i
    else
      set ihr = $i
    endif
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 20 --no-check-certificate https://${gfssrc}/gfs.t${gfshr}z.pgrb2.1p00.f${ihr} -P ${gfsdir}
    @ trynm = 0
    while ( $trynm < 5 )
      if (-e "${gfsdir}/gfs.t${gfshr}z.pgrb2.1p00.f${ihr}") then
#       set filesize = `du -s "${gfsdir}/gfs.t${gfshr}z.pgrb2.1p00.f${ihr}" |awk '{print $1}'`
#       if (${filesize} >= 25000) then
        echo "f${ihr}  sucess"
        @ trynm = 5
      else
        sleep 2s
        @ trynm = $trynm + 1
        echo "f${ihr}  try: ${trynm}"
        wget -c --no-check-certificate https://${gfssrc}/gfs.t${gfshr}z.pgrb2.1p00.f${ihr} -P ${gfsdir}
      endif
    end
    @ i = $i + $inchr
  end
endif   # optgfs
#
# Running WPS, geogrid.exe not run here.
#
if ( $optwps == 1 && $errorcode == 0 ) then
  echo 'Processing WPS'
  cd $workdir
  set gfsdir = "${datadir}/gfs/gfs.${jobsYr}${jobsmo}${jobscd}${gfshr}"
  mkdir metgrid
  ln -s $wrfdir/WPS/link_grib.csh .
  ln -s $wrfdir/WPS/namelist.wps.ref .
  ln -s $wrfdir/WPS/ungrib.exe .
  ln -s $wrfdir/WPS/metgrid.exe .
  ln -s $wrfdir/WPS/geo_em.d0?.nc .
# ln -s /raid5.c/model/bokai/forecast_test/simenvi/WRF/WRF321/WPS/GEOG_Operation/NEW_usgs/geo_em.d0?.nc .
  ln -s $wrfdir/WPS/Vtable .
  ln -s $wrfdir/WPS/metgrid/METGRID.TBL metgrid/.
  /bin/rm -f metgrid.log metgrid.out ungrib.log ungrib.out FILE* PFILE* met_em.d0* GRIBFILE.*
  ./link_grib.csh  $gfsdir/gfs.*
  sed -e 's/SY/'${jobsYr}'/g' -e 's/SM/'${jobsmo}'/g' -e 's/SD/'${jobscd}'/g' -e 's/SH/'${jobshr}'/g' -e 's/EY/'${jobeYr}'/g' -e 's/EM/'${jobemo}'/g' -e 's/ED/'${jobecd}'/g' -e 's/EH/'${jobehr}'/g' namelist.wps.ref > namelist.wps
  nohup time ./ungrib.exe >& ungrib.out
  nohup time ./metgrid.exe >& metgrid.out
endif
#
# Running WRF
#
if ( $optwrf == 1 && $errorcode == 0 ) then
  echo 'Processing WRF'
  cd $workdir
  ln -s $wrfdir/WRFV3/run/real.exe .
  ln -s $wrfdir/WRFV3/run/wrf.exe .
  ln -s $wrfdir/WRFV3/run/namelist.input.ref .
  ln -s $wrfdir/WRFV3/run/LANDUSE.TBL .
  ln -s $wrfdir/WRFV3/run/RRTMG_LW_DATA .
  ln -s $wrfdir/WRFV3/run/RRTMG_SW_DATA .
  ln -s $wrfdir/WRFV3/run/VEGPARM.TBL .
  ln -s $wrfdir/WRFV3/run/SOILPARM.TBL .
  ln -s $wrfdir/WRFV3/run/GENPARM.TBL .
  ln -s $wrfdir/WRFV3/run/URBPARM.TBL .
  /bin/rm -f real.out wrf.out wrfout_d0*
  sed -e 's/SY/'${jobsYr}'/g' -e 's/SM/'${jobsmo}'/g' -e 's/SD/'${jobscd}'/g' -e 's/SH/'${jobshr}'/g ' -e 's/EY/'${jobeYr}'/g' -e 's/EM/'${jobemo}'/g' -e 's/ED/'${jobecd}'/g' -e 's/EH/'${jobehr}'/g' -e 's/RH/'${runhr}'/g' -e 's/TIMESTEP/'${timestep}'/g' namelist.input.ref > namelist.input

  setenv LD_LIBRARY_PATH /simenvi.a/model/cayang/Taipower/simenvi/WRF/WRFV3/pgilib/

  nohup time ./real.exe >& real.out
  setenv OMP_NUM_THREADS 24
  echo 'Berfore  wrf.exe'
  nohup time ./wrf.exe >& wrf.out
  echo 'After  wrf.exe'
  if ( $optrun == 1 ) then
  echo 'Inside wrfoutdir check'
    set wrfoutdir = "${datadir}/wrfout/wrfout.${jobsYr}${jobsmo}${jobscd}${jobshr}"
    if ( -d $wrfoutdir ) then
     /bin/rm -f $wrfoutdir/wrfout_d0*
  echo 'Remove old wrf data'
    else
  echo 'Create wrf dir'
     mkdir -p $wrfoutdir
    endif
    /bin/mv -f wrfout_d0* $wrfoutdir

#check
#    set check=`ls $wrfoutdir|wc -l`
#    if ( $check == 388 ) then
#     mail -s "Simulation Success" user1@example.com.tw < /path/to/forecast.log
#    else if ( $check < 388 ) then
#     mail -s "Simulation Fail" user1@example.com.tw < /path/to/log
#    endif

#
    /bin/rm -f FILE* met_em.d0* GRIBFILE.* wrfbdy_d01 wrffdda_d01 wrfinput_d0?
  echo 'Finish wrfoutdir check'
  endif
  echo 'Finish wrf'
endif
/bin/rm -f $wrfoutdir/wrfout_d0[1-3]*
exit $errorcode
