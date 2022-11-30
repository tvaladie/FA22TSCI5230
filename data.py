# import python libraries
import pandas as pd
import numpy as np
import os
import requests
import zipfile
import pickle
from tqdm import tqdm

# set the download url to 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip';
InputData = 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip'

# Create a data directory if it doesn't already exist (don't give an error if it does)
os.makedirs('data',exist_ok = True)

# Platform-independent code for specifying where the raw downloaded data will go
DownloadPath = os.path.join('data','TempData.zip')

# Download the file from the location specified by the Input_Data variable
# as per https://stackoverflow.com/a/37573701/945039
Request = requests.get(InputData,stream = True)
SizeInBytes = Request.headers.get('content-length',0)
BlockSize = 1024
ProgressBar = tqdm(total=int(SizeInBytes),unit='iB',unit_scale=True)
with open(DownloadPath,'wb') as file:
  for data in Request.iter_content(BlockSize):
    ProgressBar.update(len(data))
    file.write(data)

ProgressBar.close()

#Assertions are a condition to see if a certain condition is true
#Will interrupt the script if fails and could save time of running an entire process
#before finding out it doesn't work, or by forcing through a recoverable error
#to not have to restart the entire process
assert ProgressBar.n == int(SizeInBytes), 'Download failed'

to_unzip = zipfile.ZipFile(DownloadPath)

#In R, a vector is most similar to a list. In R, a list is most similar to a dictionary
dd = {}
for ii in to_unzip.namelist():
  if ii.endswith('csv.gz'):
    dd[os.path.split(ii)[1].replace('.csv.gz','')] = pd.read_csv(to_unzip.open(ii),compression = 'gzip',low_memory=False)
    
dd.keys() #returns the names

pickle.dump(dd,file=open('data.pickle','wb'));

#You would do that function in questions (to_unzip.namelist()) followed by [#]
#if you wanted a specific position in a list. Remember python starts numbering at 0

# Save the downloaded file to the data directory

# ... but the concise less readable way to do the same thing is:
# open(Zipped_Data, 'wb').write(requests.get(Input_data))

# Unzip and read the downloaded data into a dictionary named dd
# full names of all files in the zip
# look for only the files ending in csv.gz
# when found, create names based on the stripped down file names and
# assign to each one the corresponding data frame which will be uncompressed
# as it is read. The low_memory argument is to avoid a warning about mixed data types

# Use pickle to save the processed data
