#!/bin/csh
set WorkDir=/path/to/data1/directory
set Work2Dir=/path/to/data2/directory

set rmYYMMDD=`date +%Y%m%d  --date="-2 year -1 days"`
set rmDateDir=wrfout.${rmYYMMDD}12
echo $rmDateDir

set mvYYMMDD=`date +%Y%m%d  --date="-1 year -4 month -1 days"`
set mvDateDir=wrfout.${mvYYMMDD}12
echo $mvDateDir

if ( -d $Work2Dir/$rmDateDir ) then
   /bin/rm -rf $Work2Dir/$rmDateDir
   /bin/rm -rf $WorkDir/$rmDateDir
   echo rm Dir:$rmDateDir
endif
if ( -d $WorkDir/$mvDateDir  && ! -d $Work2Dir/$mvDateDir) then
   /bin/mv $WorkDir/$mvDateDir $Work2Dir
   ln -s $Work2Dir/$mvDateDir  $WorkDir
   echo mv Dir:$mvDateDir
endif

