#install.packages(c('explore','DataExplorer','correlationfunnel'))

library(explore)
library(DataExplorer)
library(correlationfunnel)

inputdata = file.path('data','Analysis_Data_R.tsv')

if(!file.exists(inputdata)){system('R -f DataPrep.R')}
data = import(inputdata)

explore_shiny(data) #Opens shiny to view data file/analysis, R console tied up while looking through Shiny
create_report(data) #Creates static report (html by default) using DataExplorer

data_bin <- binarize(data)
data_cor <- correlate(data_bin, target = data_bin$value)
View(data_cor)
