#'---
#' title: "Data Extraction"
#' author: 'Author One ^1^, Author Two ^1^'
#' abstract: |
#'  | Provide a summary of objectives, study design, setting, participants,
#'  | sample size, predictors, outcome, statistical analysis, results,
#'  | and conclusions.
#' documentclass: article
#' description: 'Manuscript'
#' clean: false
#' self_contained: true
#' number_sections: false
#' keep_md: true
#' fig_caption: true
#' output:
#'  html_document:
#'    toc: true
#'    toc_float: true
#'    code_folding: show
#' ---
#'
#+ init, echo=FALSE, message=FALSE, warning=FALSE
# init ----
# This part does not show up in your rendered report, only in the script,
# because we are using regular comments instead of #' comments
debug <- 0;
knitr::opts_chunk$set(echo=debug>-1, warning=debug>0, message=debug>0);

library(ggplot2); # visualisation
library(GGally);
library(rio);# simple command for importing and exporting
library(pander); # format tables
library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr); #add dplyr library
library(fs); #add file systems

options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf);
whatisthis <- function(xx){
  list(class=class(xx),info=c(mode=mode(xx),storage.mode=storage.mode(xx)
                              ,typeof=typeof(xx)))};

#' # Import the data
Input_Data <- 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip'
dir.create('data',showWarnings = FALSE)
Zipped_Data <- file.path("data",'tempdata.zip')
download.file(Input_Data,destfile = Zipped_Data)

#' # Unzip the Data (exdir is extraction directory)
UnzippedData <- unzip (Zipped_Data, exdir = "data") %>% grep('gz',.,value = TRUE)
grep('gz',UnzippedData) #position in the vector where the pattern "gz" has been found
grep('gz',UnzippedData, value=TRUE) #return of the actual strings

Transfers<-import(UnzippedData[3],fread=FALSE)
TableNames <- basename(UnzippedData) %>% path_ext_remove() %>% path_ext_remove()
TableNames
assign(TableNames[3],import(UnzippedData[3],fread=FALSE))

for(ii in seq_along(TableNames)){
  assign(TableNames[ii],import(UnzippedData[ii],format = 'csv'),inherits = TRUE)}

mapply(function(xx,yy){
  c(length(xx),length(yy))},TableNames,UnzippedData)

mapply(function(xx,yy){
  assign(TableNames[ii],import(UnzippedData[ii],format = 'csv'),inherits = TRUE)},TableNames,UnzippedData)

mapply(function(xx,yy)
  assign(xx,import(yy,format = 'CSV'),inherits=TRUE),TableNames,UnzippedData)

save(list = TableNames, file = 'working_script.rdata')