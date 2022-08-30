import os
os.system('nohup python /simenvi.a/model/cayang/Taipower/forecast/chkfile/chkdate.py &')
os.system('wait')
print('First')
os.system('nohup /simenvi.a/model/cayang/Taipower/forecast/chkfile/chkdate.csh &')
print('Second')
