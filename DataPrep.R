#'---
#' title: "TSCI 5230: Introduction to Data Science"
#' author: 'Charles Valadie'
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
library(pander); # format tables
library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr);
library(tidyr);
library(purrr);
library(table1);

options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf);

if(!file.exists('data.R.rdata')){system('R -f data.R')}
load('data.R.rdata')

#Section 2-----
#GGplot
ggplot(data = patients, aes(x=anchor_age, fill = gender)) + geom_histogram() +
  geom_vline(xintercept = 65)

table(patients$gender)
length(unique(patients$subject_id))

# load data ----

#Introduction to dplyr
Demographics <- group_by(admissions, subject_id) %>%
  mutate(los = difftime(dischtime,admittime)) %>%
  summarise(admits = n(),
            eth = length(unique(ethnicity)),
            ethnicity_combo = paste(sort(unique(ethnicity)),collapse = ':'),
            language = tail(language,1),
            dod = max(deathtime, na.rm=TRUE),
            los = median(los),
            numED = length(na.omit(edregtime)))

#Subset of data frames
#subset(Demographics, eth > 1)
#table(Demographics$eth)

ggplot(data = Demographics, aes(x=admits)) + geom_histogram() #Distribution of admits by pt

#Demographics final
intersect(names(Demographics),names(patients))

#Inner join only keeps rows found in both data sets. Outer join only keeps unique values
#Find patients listed in one data set but not the other
intersect(Demographics$subject_id,patients$subject_id) #Should have 100 results if all are similar
setdiff(Demographics$subject_id,patients$subject_id) #setdiff is opposite of intersect
#Could then reverse either of these to ensure it is correct for both sides
setdiff(patients$subject_id,Demographics$subject_id)

#What about dod which is empty for patients?
setdiff(Demographics$dod,patients$dod) #Only get unique values present for L side compared to R

Demographics1 <- left_join(Demographics, select(patients, -dod), by = 'subject_id')

#patient = subset(patients, select = -c(dod))
#paste0(letters,LETTERS, collapse = '---')

############################Vanc/Zosyn study data
# build list of keywords
kw_abx <- c("vanco", "zosyn", "piperacillin", "tazobactam", "cefepime", "meropenam", "ertapenem", "carbapenem", "levofloxacin")
kw_lab <- c("creatinine")
kw_aki <- c("acute renal failure", "acute kidney injury", "acute kidney failure", "acute kidney", "acute renal insufficiency")
kw_aki_pp <- c("postpartum", "labor and delivery")


# search for those keywords in the tables to find the full label names
# remove post partum from aki in last line here
# may need to remove some of the lab labels as well (pending)
label_abx <- grep(paste0(kw_abx, collapse = '|'), d_items$label, ignore.case = T, value = T, invert = F)
label_lab <- grep(paste0(kw_lab, collapse = '|'), d_labitems$label, ignore.case = T, value = T, invert = F)
label_aki <- grep(paste0(kw_aki, collapse = '|'), d_icd_diagnoses$long_title, ignore.case = T, value = T, invert = F)
label_aki <- grep(paste0(kw_aki_pp, collapse = '|'), label_aki, ignore.case = T, value = T, invert = T)


# use dplyr filter to make tables with the item_id for the keywords above
item_ids_abx <- d_items %>% filter(label %in% label_abx)
item_ids_lab <- d_labitems %>% filter(label %in% label_lab)
item_ids_aki <- d_icd_diagnoses %>% filter(long_title %in% label_aki)

subset(item_ids_abx, category == 'Antibiotics') #Only selects rows with category of Antibiotics
subset(item_ids_abx, category == 'Antibiotics') %>%
  left_join(inputevents, by = 'itemid') #By using subset first in left_join, starting off
#by only selecting rows with antibiotics, and then pulling inputevents data for those
#patients that received the antibiotics with our specified IDs

Antibiotics <- subset(item_ids_abx, category == 'Antibiotics') %>%
  left_join(inputevents, by = 'itemid')

grep('N17', diagnoses_icd$icd_code, value = T) #ICD codes found within the dataset
grep('^548|^N17', diagnoses_icd$icd_code, value=T) #Either 548... or N17... values
#within the diagnosis_icd$icd_code data set
grepl('^548|^N17', diagnoses_icd$icd_code) #True/False for each row whether it contains value
subset(diagnoses_icd,grepl('^548|^N17',icd_code)) #Pulls only the rows that have ICD code of interest
Akidiagnoses_icd <- subset(diagnoses_icd,grepl('^548|^N17',icd_code))

Cr_labevents <- subset(item_ids_lab, fluid == "Blood") %>%
  left_join(labevents, by = 'itemid') #Filter only blood Cr and match to lab events

grepl(paste(kw_abx, collapse='|'),emar$medication)
subset(emar,grepl(paste(kw_abx, collapse='|'),medication,ignore.case = T))$event_txt%>%
  table()%>%sort() #Filter emar by antibiotic administration with individual event txt

#Did not finish: emar_abx <- subset(emar, grepl(paste(kw_abx, collapse = '|'), medication, ignore.case = T))

#Grouping of tables by Vanc, Zosyn or other
Antibiotics_Groupings<-group_by(Antibiotics,hadm_id) %>%
  summarise(Vanc = 'Vancomycin' %in% label, Zosyn = any(grepl('Piperacillin',label)),
            Other = length(grep('Piperacillin|Vancomycin',label,val=TRUE,invert = TRUE))>0,
            N = n(),
            Exposure1 = case_when(!Vanc ~ 'Other',
                                  Vanc&Zosyn ~ 'Vanc & Zosyn',
                                  Other ~ "Vanc & Other",
                                  !Other ~ "Vanc",
                                  TRUE ~ 'UNDEFINED'),)
            #Debug = {browser();TRUE})
#sapply(st,function(xx)){between()}

#Create Exposure 2 that uses different logic. Instead of using proposed shortcuts,
#Use 'Vanc and no Zosyn and no other" doing them all explicity. So as below
#Vanc & !Zosyn & !Other ~ 'Vanc'
#Goal is to show that the long way does match the shorthand we've done
#sapply takes a vector or a list and performs function on each element of the list

#Not using shortcut
#1
#sapply(Antibiotics_Groupings,summarise,Vanc'True')

#Antibiotics_Groupings %>% if(Vanc='FALSE',Zosyn='FALSE',Other='TRUE' %>% summarise(N=n()),)

#Antibiotics_Groupings %>% summarise(n=(sum(Vanc='FALSE',Zosyn='FALSE',Other='TRUE')))
#summary(Antibiotics_Groupings)

#Antibiotics_Groupings %>% grepl(paste(Other='True'))

group_by(Antibiotics_Groupings,Vanc,Zosyn,Other) %>%
  summarise(N=n())

#sapply(st, function(xx)){between()}

#9-28

Admission_scaffold <- admissions %>% select(hadm_id, admittime, dischtime) %>%
  transmute(hadm_id = hadm_id,
            ip_date = map2(as.Date(admittime), as.Date(dischtime), seq, by = "1 day"))%>%
  unnest(ip_date)

#Grep returns a value from a table, grepl (l = logical) puts it as a true/false
Antibiotics_dates <- Antibiotics %>%
    transmute(hadm_id = hadm_id,
              group = case_when('Vancomycin' == label ~ 'Vanc',
                                grepl('Piperacillin',label) ~ 'Zosyn',
                                TRUE ~ 'Other'),
              starttime = starttime,
              endtime = endtime) %>% unique() %>%
  subset(!is.na(starttime) & !is.na(endtime)) %>%
  transmute(hadm_id = hadm_id,
            ip_date = {oo <- try(map2(as.Date(starttime), as.Date(endtime), seq, by = '1 day'));
            if(is(oo, 'try-error'))browser()
            oo},
            group = group) %>%
  unnest(ip_date) %>% unique()

Antibiotics_dates <- split(Antibiotics_dates, Antibiotics_dates$group)

#names(Antibiotics_dates$Vanc)[3]<- 'Vanc' #Within Vanc set, changes column name to Vanc

#function(xx) does each of them in turn

Antibiotics_dates <- sapply(names(Antibiotics_dates), function(xx){
  names(Antibiotics_dates[[xx]])[3] <- xx
  Antibiotics_dates[[xx]]
  },simplify = FALSE) %>%
  Reduce(left_join,.,Admission_scaffold)

#mutate(Antibiotics_dates,Other = if_else(is.na(Other),'',Other),
#       Vanc = coalesce(Vanc,'')
#       ) %>% View()
mutate(Antibiotics_dates,
       across(all_of(c('Other','Vanc','Zosyn')),~coalesce(.x,'')),
       Exposure = paste(Vanc, Zosyn, Other)) %>%
  select(hadm_id, Exposure) %>% unique() %>%
  pull(Exposure) %>% table()

#10/5 Class
#Identify the first date pt administered Vanc and Zosyn
Cr_labevents2 <- Antibiotics_dates %>%
  group_by(hadm_id) %>%
  summarise(date_Vanc_Zosyn = min(ip_date[!is.na(Vanc) & !is.na(Zosyn)])) %>%
  subset(!is.infinite(date_Vanc_Zosyn)) %>%
  left_join(Cr_labevents,.)%>%
  subset(!is.na(hadm_id)) %>%
  arrange(hadm_id, charttime) %>%
  group_by(hadm_id) %>%
  mutate(Vanc_Zosyn = !all(is.na(date_Vanc_Zosyn)))

#subset(Cr_labevents2, !no_Vanc_Zosyn) %>% ggplot(aes(x=centered, y=valuenum, group=hadm_id))+
  #geom_line()+
  #geom_point(aes(col=after_Vanc_Zosyn))

Cr_labevents$charttime - Cr_labevents$date_Vanc_Zosyn %>% na.omit() %>% head()

#subset is for rows, select is for columns
#Join all of the tables (demographics, Cr_labevents2 via admissions table)
#together to get all of our variables in the same place

Analysis_Data <- left_join(Cr_labevents2,Demographics1)

ggplot(Analysis_Data, aes(x= Vanc_Zosyn, y = valuenum)) +
  geom_violin()+
  geom_boxplot()

paired_analysis <- c('valuenum', 'admits', 'flag', 'Vanc_Zosyn')

#Diagonal is distribution of each variable
Analysis_Data[,paired_analysis] %>% ggpairs()

Analysis_Data[,paired_analysis] %>% ggpairs(aes(col=Vanc_Zosyn))

#Table1 usually the first table to show in a table so why it's called table1
table1(~valuenum+admits+flag+anchor_age+gender | Vanc_Zosyn, data=Analysis_Data,
       render.continuous = my.render.cont())

#Example of a formula you can write in order to do your own renders
my.render.cont <- function(x) {
  with(stats.default(Analysis_Data$anchor_age),
       sprintf("%0.2f (%0.1f)", MEAN, SD))
}
#'with' helps use an object (like a data frame but does not have to be) temporarily
#to get a value without transforming the data frame

table1(strata, labels, groupspan=c(1, 3, 1), render.continuous=my.render.cont)

View(stats.default(Analysis_Data$anchor_age))

sprintf('hello')
#% says this is where a placeholder begins, then after the decimal is how much to
#round it to
sprintf('the mean is %0.1f', 6.598)
#output is 'the mean is 6.6'

#One line cheat sheet for how to do any kind of string formatting. Also present
#within Python, C, java, etc
sprintf('the mean is %0.1f. The SD is %d. The string is %s. The percentage is %0.1f%%', 6.598, 8, 'string', 25)


# Combined into 1 table
# Reduce(left_join, Antibiotics_dates) %>% View()
# Also including times where people have no abx
# Reduce(left_join, Antibiotics_dates, Admission_scaffold) %>% View()
#subset is for rows, select is for columns