import sqlite3
import pandas as pd
import os

#資料庫相關設定
def Create_Table(TableNm):
    cur.execute(""" CREATE TABLE {} (
                    Date DATE PRIMARY KEY,
                    State VARCHAR NOT NULL)""".format(TableNm))
    print(f'Created {TableNm}')
    return cur


def Insert_DD(TableNm, value):
    cur.execute("INSERT OR REPLACE INTO {} VALUES(?, ?)".format(TableNm), value)        
#   print('Insert')
    return



#主程式
workDir = '/simenvi.a/model/cayang/Taipower/simenvi/proj001/wrf/data/wrfout/'

yesDate = (pd.Timestamp.today()-pd.Timedelta(1,'d'))
DirList = [tt.strftime('%Y%m%d') for tt in pd.date_range(end=yesDate, periods=7)]
TableNm = 'WRFDate'


##連線至資料庫
conn = sqlite3.connect('SimEnvi.DB')
cur = conn.cursor()
print('Connected to SQLite')


for Dir in DirList:
   DirNm = workDir+'wrfout.'+Dir+'12'
   if os.path.isdir(DirNm): 
     if len(os.listdir(DirNm)) >= 197:
       Insert_DD(TableNm, (Dir, 'yes'))  
     else:
       Insert_DD(TableNm, (Dir, 'no'))  
   else:
     Insert_DD(TableNm, (Dir, 'not exists'))  
     

cur.execute("SELECT * FROM {}".format(TableNm))	   
table = cur.fetchall()
print(table)


conn.commit()
conn.close()
