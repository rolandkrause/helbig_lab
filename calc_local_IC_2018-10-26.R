#Create base and propagate table and calculate Local IC

######
#Load required libraries
######
library(tidyverse)
source("config.R")

######
#STEP 1: Load required files
######
#Freeze files from the 320 trio cohort

exp321 <- read_csv(file.path(data_dir, "320_Expanded_v2_RK_2018-11-05.csv"))


#allHPOs - static file
allHPOs <- read_csv(file.path(data_dir,  "HPO_is.a_tree.csv"))
allHPOs=allHPOs[!duplicated(allHPOs$term),]

#hpo_ancs - static file
hpo_ancs <- read_csv(file.path(data_dir, "HPO_Ancestors_Compressed.csv"))


######
#STEP 1: Create base and prop table
######

pat_table_base <- exp321 %>% 
  dplyr::select(famID,HPO) %>% 
  separate_rows(HPO, sep = ";") %>% unique()
  
pat_table_prop <- pat_table_base %>% 
  left_join(hpo_ancs %>% dplyr::select(-definition)) %>% 
  dplyr::select(famID, Ancestors) %>% 
  dplyr::rename(HPO = Ancestors) %>% 
  separate_rows(HPO, sep = ";") %>% 
  #Remove duplicated HPO terms in each patient
  unique

######
#STEP 2: Calculate Local IC
######

base_IC <- pat_table_base %>% 
  dplyr::count(HPO) %>% 
  mutate(local.Base.freq = n/length(unique(pat_table_base$famID))) %>% 
  mutate(Base.local.IC = -log2(local.Base.freq)) %>% 
  dplyr::select(-n)

prop_IC <- pat_table_prop %>% 
  dplyr::count(HPO) %>% 
  dplyr::mutate(local.Prop.freq = n/length(unique(pat_table_base$famID))) %>% 
  dplyr::mutate(Propagated.local.IC = -log2(local.Prop.freq)) %>% 
  dplyr::select(-n)

local_IC <- allHPOs %>% 
  dplyr::select(term) %>% 
  full_join(base_IC, by = c('term' = 'HPO')) %>% 
  full_join(prop_IC, by = c('term' = 'HPO')) %>% 
  replace(., is.na(.),0)


write.csv(local_IC, "Local_IC_320_log2.csv",row.names = F)

write.csv(pat_table_base, "Local_Base_per_patient_320",row.names = F)

write.csv(pat_table_prop, "Local_Prop_per_patient_320",row.names = F)




