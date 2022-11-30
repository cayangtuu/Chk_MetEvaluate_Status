import sqlite3
import pandas as pd
import os


### ===主程式===
def main():
    global wrfDir, workDir, TableNm, cur, conn
    ## 基本資料設定
    wrfDir = '.../wrf/data/wrfout/' # WRF檔案目錄
    workDir = '.../forecast/chkfile/' #執行程式工作目錄
    TableNm = 'WRFDate'
    WrfNm_D4   = 97

    yesterDay = (pd.Timestamp.today()-pd.Timedelta(1,'d'))
    DirList = {tt.strftime('%Y%m%d'):WrfNm_D4 \
               for tt in pd.date_range(end=yesterDay, periods=8)}
    print(DirList)


    ## 連線至資料庫
    conn = sqlite3.connect(workDir+'SimEnvi.DB')
    cur = conn.cursor()
    print('Connected to SQLite')


    ## 結果判讀及檔案輸出
    # 自動判斷
    AutoJudge(DirList)
    
    #手動修改
      # 輸入欲做的修改類別，共有'Insert','Update','Remove'3種
      # 輸入修改資料，以列表表示之：
      # HList = [(HTIME, HState),]  
      # HTime:日期，格式為YYYYMMDD ; HState:狀態，格式為'yes' or 'no'
#   HType = 'Update'   
#   HList = [('20221011', 'yes')] 
#   HandJudge(HType, HList)


    MetFile_Exist()
    OutPut(DirList)
   
    ## 結束連線
    conn.commit()
    conn.close()


## ===資料庫相關設定===
def Create_Table(TableNm):
    # State: 該日期資料夾是否存在，是否重新模擬
    # Exist: 該日期檔案是否存在，顯示於網頁上
    cur.execute(""" CREATE TABLE {} (
                    Date DATE PRIMARY KEY,
                    State VARCHAR NOT NULL, 
                    Exist VARCHAR )""".format(TableNm)) 
    print(f'Created {TableNm}')
    return


def Insert_DD(HTime, HState):
    cur.execute("INSERT OR REPLACE INTO {} (Date,State) VALUES(?, ?)".format(TableNm), (HTime, HState))        
    print(f'Insert ({HTime}, {HState})')
    return

def Update_DD(HState, HTime):
    cur.execute("UPDATE {} SET State = '{}' WHERE Date = '{}'".format(TableNm, HState, HTime))
    print(f'Update ({HTime}, {HState})')
    return

def Remove_DD(HTime):
    cur.execute("DELETE FROM {} WHERE Date = '{}'".format(TableNm, HTime))
    print(f'Remove {HTime}')
    return


### ===進行氣象模擬資料執行結果判讀===

def AutoJudge(DirList):
    ## "自動"調整判讀結果及資料庫
    for Dir in DirList:
       DirNm = wrfDir+'wrfout.'+Dir+'12'
       if os.path.isdir(DirNm): 
          if len(os.listdir(DirNm)) >= DirList[Dir]:
             Insert_DD(Dir, 'yes')  
          else:
             Insert_DD(Dir, 'no')  
       else:
          Insert_DD(Dir, 'no')  
    return


def HandJudge(HType, HList):
    ## "手動"調整判讀結果及資料庫
    if HType=='Insert':
      for List in HList:
          HTime, HState = List
          Insert_DD(HTime, HState)

    if HType=='Update':
      for List in HList:
          HTime, HState = List
          Update_DD(HState, HTime)

    if HType=='Remove':
      for List in HList:
          HTime, HState = List
          Remove_DD(HTime)
    return


def MetFile_Exist():
    ## 自動判讀該日期是否有檔案存在，提拱給網頁
    cur.execute("SELECT * FROM {}".format(TableNm))	   
    for DD in cur.fetchall(): 
       Fls = [wrfDir+'wrfout.'+tt.strftime('%Y%m%d')+'12' \
              for tt in pd.date_range(end=str(DD[0]), periods=5)]
       if (os.path.isdir(Fls[0]) and os.path.isdir(Fls[-1])) or \
          (os.path.isdir(Fls[1]) or  os.path.isdir(Fls[2])   or os.path.isdir(Fls[3])):
          cur.execute("UPDATE {} SET Exist = '{}' WHERE Date = '{}'".format(TableNm, 'yes', DD[0]))      
       else:
          cur.execute("UPDATE {} SET Exist = '{}' WHERE Date = '{}'".format(TableNm, 'no', DD[0]))      


### ===檔案輸出===

def OutPut(DirList):
    ## 螢幕顯示資料庫資料
    cur.execute("SELECT * FROM {}".format(TableNm))	   
    print(cur.fetchall())

    ## 讀取所有日期並輸出"WebTable.txt"檔案
    pd.read_sql("SELECT Date,Exist FROM {}".format(TableNm), conn).to_csv(workDir+'WebTable.txt', index=0)

    ## 讀取失敗日期並輸出"BadTable.txt"檔案
    pd.read_sql("SELECT Date FROM {} WHERE State='no' AND Date >= '{}'".format(TableNm, list(DirList.keys())[0]),\
                 conn).to_csv(workDir+'BadTable.txt', index=0, header=0)

    return


if __name__ == '__main__':
   main()

