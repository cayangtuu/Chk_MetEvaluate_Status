import pandas as pd
import os

workDir = '/simenvi.a/model/cayang/Taipower/simenvi/proj001/wrf/data/wrfout/'
# 全部的日期
# 8天的日期
yesterDay = (pd.Timestamp.today()-pd.Timedelta(1,'d'))
DirList = [tt.strftime('%Y%m%d') for tt in pd.date_range(end=yesterDay, periods=8)]
WrfNm = 97

OutData = {}
for Dir in DirList:
   DirNm = workDir+'wrfout.'+Dir+'12'
   if os.path.isdir(DirNm):
     if (len(os.listdir(DirNm)) == WrfNm):
       OutData[Dir] = 'yes' 
     else:
       OutData[Dir] = 'no' 
   else: 
     pass
print(OutData)
