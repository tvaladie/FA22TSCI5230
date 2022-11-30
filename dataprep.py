#11/16/22
# import python libraries
import pandas as pd
import numpy as np
import os
import pickle

#Ensure staged data exists
if not os.path.exists('data.pickle'): # if the file data.pickle does not exist, run data.py then read file
  import runpy
  runpy.run_path('data.py')

#Load staged data
dd = pickle.load(open('data.pickle', 'rb'))
#dd.keys() gets names of individual tables
#dd['admissions'] get individual tables

#Creat table: demographics FROM admissions, patients
demographics = dd['admissions'].copy()

patients = dd['patients'].copy().drop('dod', axis = 1)

#Create LOS variable
demographics['LOS'] = (pd.to_datetime(demographics['dischtime']) - 
  pd.to_datetime(demographics['admittime']))/np.timedelta64(1,'D')

demographics1 = demographics.groupby('subject_id').agg(admits = ('subject_id','count'),
  eth = ('ethnicity','nunique'),
  ethnicity_combo = ('ethnicity',lambda xx: ':'.join(sorted(list(set(xx))))),
  language = ('language','last'),
  dod = ('deathtime',lambda xx: max(pd.to_datetime(xx))),
  LOS = ('LOS', np.median),
  numED = ('edregtime',lambda xx: xx.notnull().sum())).reset_index(drop = False).\
  merge(patients, on = 'subject_id')

#11/30
# Mapping the variables.

# build list of keywords
kw_abx = ["vanco", "zosyn", "piperacillin", "tazobactam", "cefepime", "meropenam", "ertapenem", "carbapenem", "levofloxacin"]
kw_lab = ["creatinine"]
kw_aki = ["acute renal failure", "acute kidney injury", "acute kidney failure", "acute kidney", "acute renal insufficiency"]
kw_aki_pp = ["postpartum", "labor and delivery"]

# search for those keywords in the tables to find the full label names
# remove post partum from aki in last line here
# may need to remove some of the lab labels as well (pending)
label_abx = "|".join(kw_abx)
label_aki = "|".join(kw_aki)
label_aki_pp = "|".join(kw_aki_pp)

# use dplyr filter to make tables with the item_id for the keywords above
items_abx = dd['d_items'][dd['d_items'].label.str.contains(label_abx, case = False)].copy()
items_abx = items_abx[items_abx['category'] == 'Antibiotics']
items_aki = dd['d_icd_diagnoses'][dd['d_icd_diagnoses'].long_title.str.contains(label_aki, case = False)]
items_aki = items_aki[~items_aki.long_title.str.contains(label_aki_pp, case = False)] #reverse following T/F
items_lab = dd['d_labitems'][dd['d_labitems'].label.str.contains(kw_lab[0], case = False, na=False)]
items_lab = items_lab[items_lab['fluid' == 'Blood']]

given_abx = items_abx.merge(dd['inputevents'], on = 'itemid')
given_abx['group'] = np.where(given_abx.label == 'Vancomycin','Vanc',
  np.where(given_abx.label.str.contains('Piperacillin'), "Zosyn", 'Other'))
given_abx['starttime'] = pd.to_datetime(given_abx['starttime']).dt.date
given_abx['endtime'] = pd.to_datetime(given_abx['endtime']).dt.date

#Apply lets you specify a funciton and then apply it on every row. Lambda means it
#is an inline function that won't apply it permanently but just temporarily w/in the command
#Specifically, using given_abx table, takes start time of a row, takes the range between that and the end time on that same row, and gives a range in "D(ays)"
#That column from above row/hash is now given the name ip_dates
given_abx['ip_dates'] = given_abx.apply(lambda row: 
  pd.date_range(row['starttime'], row['endtime'], freq = 'D'), axis = 1)
abx_dates = given_abx.explode('ip_dates')

#Create new columns in abx_dates, Vanc, Zosyn and Other
abx_dates['vanc'] = 1
abx_dates['zosyn'] = 1
abx_dates['other'] = 1

aki_diagnosis = dd['diagnoses_icd'][dd['diagnoses_icd'].icd_code.str.contains("^584|^N17", case = False)]

cr_labevents = items_lab.merge(dd['labevents'], on = 'itemid')
cr_labevents['ip_dates'] = pd.to_datetime(cr_labevents['charttime']).dt.date
cr_labevents = cr_labevents[(cr_labevents.category == 'Chemistry') & (cr_labevents.fluid == 'Blood')][['hadm_id','ip_dates','valuenum','flag']].groupby(['hadm_id','ip_dates']).agg(
  Creatinine = ('valuenum','max'), cr_flag = ('flag',lambda xx : max(np.where(xx == 'abnormal','1','0')))).reset_index(drop = False).drop_duplicates()

emar_abx = dd['emar'][dd['emar'].medication.str.contains(label_abx, case = False, na = False)]

#Admission_scaffold
admissions_scaffold = dd['admissions'][['hadm_id', 'admittime', 'dischtime']].copy()
admissions_scaffold['admittime'] = pd.to_datetime(admissions_scaffold['admittime']).dt.round('D')
admissions_scaffold['dischtime'] = pd.to_datetime(admissions_scaffold['dischtime']).dt.round('D')

# create a new column: ip_dates
admissions_scaffold['ip_dates'] = admissions_scaffold.apply(lambda row: 
  pd.date_range(row['admittime'], row['dischtime'], freq = 'D'), axis = 1)
admissions_scaffold = admissions_scaffold.explode('ip_dates')[['hadm_id','ip_dates']]

#Vanc, Zosyn and Other amongst abx
abx_dates = admissions_scaffold.merge(abx_dates[abx_dates['group'] == 'Zosyn'][['hadm_id', 'ip_dates', 'zosyn']], how='left'
  ).merge(abx_dates[abx_dates['group'] == 'Vanc'][['hadm_id', 'ip_dates', 'vanc']], how='left'
  ).merge(abx_dates[abx_dates['group'] == 'Other'][['hadm_id', 'ip_dates', 'other']], how='left'
  ).fillna(0).drop_duplicates()

abx_dates['ip_dates'] = pd.to_datetime(abx_dates['ip_dates']).dt.date
abx_dates.merge(cr_labevents, on = ['hadm_id','ip_dates'], how = 'left')
analysis_data = abx_dates.merge(cr_labevents, on = ['hadm_id','ip_dates'], how = 'left').fillna(method='ffill',axis=1)
