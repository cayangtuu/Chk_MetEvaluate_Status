import sqlite3
import pandas as pd
import os


### ===主程式===
def main():
    global workDir, TableNm, cur, conn
    ## 基本資料設定
    workDir = '/simenvi.a/model/cayang/Taipower/simenvi/proj001/wrf/data/wrfout/'
    TableNm = 'WRFDate'
    WrfNm_DAll = 388
    WrfNm_D4   = 97

    yesterDay = (pd.Timestamp.today()-pd.Timedelta(1,'d'))
    DirList = {tt.strftime('%Y%m%d'):WrfNm_DAll \
               if tt.strftime('%Y%m')==yesterDay.strftime('%Y%m') else WrfNm_D4 \
               for tt in pd.date_range(end=yesterDay, periods=8)}


    ## 連線至資料庫
    conn = sqlite3.connect('SimEnvi.DB')
    cur = conn.cursor()
    print('Connected to SQLite')


    ## 結果判讀及檔案輸出
    AutoJudge(DirList)

#   HTime = '20220831' # 輸入日期，格式為YYYYMMDD
#   HState = 'yes'     # 輸入'yes' or 'no'
#   HandJudge(HTime, HState)
    
    OutPut(DirList)

    ## 結束連線
    conn.commit()
    conn.close()


## ===資料庫相關設定===
def Create_Table(TableNm):
    cur.execute(""" CREATE TABLE {} (
                    Date DATE PRIMARY KEY,
                    State VARCHAR NOT NULL)""".format(TableNm))
    print(f'Created {TableNm}')
    return


def Insert_DD(TableNm, value):
    cur.execute("INSERT OR REPLACE INTO {} VALUES(?, ?)".format(TableNm), value)        
    print(f'Insert {value}')
    return


### ===進行氣象模擬資料執行結果判讀===

def AutoJudge(DirList):
    ## "自動"調整判讀結果及資料庫
    for Dir in DirList:
       DirNm = workDir+'wrfout.'+Dir+'12'
       if os.path.isdir(DirNm): 
          if len(os.listdir(DirNm)) >= DirList[Dir]:
             Insert_DD(TableNm, (Dir, 'yes'))  
          else:
             Insert_DD(TableNm, (Dir, 'no'))  
       else:
          Insert_DD(TableNm, (Dir, 'no'))  
    return


def HandJudge(HTime, HState):
    ## "手動"調整判讀結果及資料庫
    Insert_DD(TableNm, (workDir+'wrfout.'+HTime+'12', HState))
    return
     

### ===檔案輸出===

def OutPut(DirList):
    ## 讀取所有日期並輸出"Table.txt"檔案
    cur.execute("SELECT * FROM {}".format(TableNm))	   
    Table = cur.fetchall()
    print(Table)
    pd.read_sql("SELECT * FROM {}".format(TableNm), conn).to_csv('Table.txt', index=0)

    ## 讀取失敗日期並輸出"BadTable.txt"檔案
    cur.execute("SELECT Date FROM {} WHERE State='no' AND Date >= {}".format(TableNm, list(DirList.keys())[0]))	   
    BadTable = cur.fetchall()
    print(BadTable)
    pd.read_sql("SELECT Date FROM {} WHERE State='no' AND Date >= {}".format(TableNm, list(DirList.keys())[0]),\
                 conn).to_csv('BadTable.txt', index=0, header=0)

    return


if __name__ == '__main__':
    main()

