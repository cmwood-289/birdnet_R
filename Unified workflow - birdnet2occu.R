# A fully R-based workflow for BirdNET and occupancy modeling #


# Analyze Audio with 'birdnetR' ----

pak::pak("birdnet-team/birdnetR") # developer: Felix Guenther
# error: 'could not find tools necessary to compile a package'
# updated R (now 4.5.1), installed Rtools 45, then installation worked.

library(birdnetR)
library(stringr)

# Initialize a BirdNET model
model <- load_birdnet(type = 'acoustic',
                      version = '2.4',
                      backend = 'tf',
                      precision = 'fp32', # what does this actually mean vs 'fp16' or 'int8'
                      lang = 'en_us') 

## Initial testing----
# specify input audio (top-level folder)
audio_folders <- list.dirs('./test_data/G25_C3542_48kHz_wav/audio/0429_0430', # .wav option
                           recursive = F)
audio_folders <- list.dirs('./test_data/G25_C3542_48kHz_flac/audio/0424_0425', # .flac option
                           recursive = F)

# analyze audio

birdnet_output_location <- "./test_data/G25_C3542_48kHz_wav/outputs/0429_0430"

for (folder in audio_folders) {
  files <- list.files(folder, pattern = "\\.wav$", full.names = TRUE) 
  #files <- list.files(folder, pattern = "\\.flac$", full.names = TRUE) 
  predictions <- predict(model, files)
  
  out_file <- file.path(birdnet_output_location, paste0(basename(folder), ".csv"))
  write_predictions(predictions, 
                    file = out_file,
                    format = 'csv')
  print(paste(which(audio_folders==folder),"of", length(audio_folders), "input folders", sep=" "))
}

# 48kHz flac was 696-687xRT; 48kHz .wav was 754-653 xRT

## Full-scale analysis ----

# Specify the top-level audio folder (used again with 'birdnetTools')
top_audio_folder <- 'S:/2023_USDA-USFS_CA_163134/163134_SoCalOwls_Dep02_FLAC'

# identify audio-containing folders
all_folders <- list.dirs(top_audio_folder,
                         recursive = T)
audio_folders <- all_folders[!sapply(all_folders, function(d) {
  any(startsWith(all_folders[all_folders != d], paste0(d, "/")))
})]

# specify output location (folder must be manually created first)
birdnet_output_location <- "./test_data/2025am_outputs" 


# analyze audio!

# (not used yet) subset_by_time = "yes" # if 'yes', check hard-coded timestamps

# note 1: 32kHz files run at 290-310xRT, a 50% penalty relative to 48kHz
# note 2: need to manually check the time-stamp positions are hard-coded into the subsetting part

for(folder in audio_folders) {
  files <- list.files(folder, pattern = "\\.flac$", full.names = TRUE)
  
  # isolate morning audio by timestamps in the filenames - positions are hardcoded!
  files_target <- files[ as.numeric(stringr::str_sub(files,-16,-15)) >= 05 & as.numeric(stringr::str_sub(files,-16,-15)) <= 09 ]
  if(length(files_target)==0){
    next
  }
  
  # analyze the targeted files
  predictions <- predict(model, files_target)
  
  # write the outputs
  out_file <- file.path(birdnet_output_location, paste0(basename(folder), ".csv"))
  write_predictions(predictions, 
                    file = out_file,
                    format = 'csv')
  print(paste(which(audio_folders==folder),"of", length(audio_folders), "input folders", sep=" "))
}

folder
# processed 1:folder of audio_folders

# 

#


# Process outputs with 'birdnetTools' ----

## Continuation of 'Initial testing' ----
pak::pak("birdnet-team/birdnetTools") # developer: Sunny Tseng
library(birdnetTools)


# combine input folder-level output files
outputs_combined <- birdnet_combine(birdnet_output_location) # 'output_location' defined above in the 'analyze audio' step

# minor cleaning for compatibility with downstream commands
names(outputs_combined)[1] <- "filepath"
outputs_combined$'Common Name' = sub(".*_", "", outputs_combined$species_name)

# filter to one species and score
WSO <- birdnet_filter(outputs_combined,
                      species = "Western Screech-Owl",
                      threshold = 0.9,
                      year = 2025,
                      #min_date = "2023-04-01",
                      #max_date = "2023-06-30",
                      hour = c(0:23) )

MOQU <- birdnet_filter(outputs_combined,
                      species = "Mountain Quail",
                      threshold = 0.9,
                      year = 2025,
                      #min_date = "2023-04-01",
                      #max_date = "2023-06-30",
                      hour = c(0:23) )

## Continuation of 'Full-sale analysis'----

remotes::install_github("birdnet-team/birdnetTools", 
                        ref = "occupancy-modelling-functions")
# skipped updates

library(tidyverse)
library(birdnetTools)



# combine input folder-level output files
full_outputs_combined <- birdnet_combine(birdnet_output_location) 
# 'output_location' defined above in the 'analyze audio' step
# note: can be slow when you have many thousands of output files for tens of thousands of hours of audio

# minor cleaning for compatibility with downstream commands
names(full_outputs_combined)[1] <- "filepath"
full_outputs_combined$'Common Name' = sub(".*_", "", full_outputs_combined$species_name)

# filter to one species and score
MOQU <- birdnet_filter(full_outputs_combined,
                       species = "Mountain Quail",
                       threshold = 0.382855133,  # pr(tp)>= 0.9 per 'Thresholds_2024_20260601.csv'
                       #year = 2025,
                       #min_date = "2023-04-01",
                       #max_date = "2023-06-30",
                       #hour = c(0:23) 
                       )
HEWA <- birdnet_filter(full_outputs_combined,
                       species = "Hermit Warbler",
                       threshold = 0.565058755, # pr(tp)>= 0.9 per 'Thresholds_2024_20260601.csv'
                       #year = 2025,
                       #min_date = "2023-04-01",
                       #max_date = "2023-06-30",
                       #hour = c(0:23) 
                       )
OSFL <- birdnet_filter(full_outputs_combined,
                       species = "Olive-sided Flycatcher",
                       threshold = 0.29307429, # pr(tp)>= 0.9 per 'Thresholds_2024_20260601.csv'
                       #year = 2025,
                       #min_date = "2023-04-01",
                       #max_date = "2023-06-30",
                       #hour = c(0:23)
                       )
save(MOQU, file='birdnet_filter_MOQU.rda')
save(HEWA, file='birdnet_filter_HEWA.rda')
save(OSFL, file='birdnet_filter_OSFL.rda')

# Make some heatmaps for fun
birdnet_heatmap(MOQU)
birdnet_heatmap(HEWA)
birdnet_heatmap(OSFL)


# Generate survey effort
effort <- birdnet_get_effort(top_audio_folder, i = -3) 
save(effort, file='effort.rda')

# note: numbers are slightly off because I filtered files by filename in the birdnet loop, not a problem here though

# Build the encounter histories
history_MOQU <- birdnet_detection_history(data = MOQU,
                                          effort_data = effort,
                                          survey_interval = "7 days",
                                          i = -3,
                                         min_unique_days = 2)
history_HEWA <- birdnet_detection_history(data = HEWA,
                                          effort_data = effort,
                                          survey_interval = "7 days",
                                          i = -3,
                                         min_unique_days = 2)
history_OSFL <- birdnet_detection_history(data = OSFL,
                                          effort_data = effort,
                                          survey_interval = "7 days",
                                          i = -3,
                                         min_unique_days = 2)

# history_output$detection_history  # The binary site-by-occasion matrix
# history_output$detection_summary  # The long-format diagnostic dataframe
#

sum(rowSums(history_MOQU$detection_history, na.rm=T)>0)/dim(history_MOQU$detection_history)[1]
# naive occupancy is 0.897
sum(rowSums(history_HEWA$detection_history, na.rm=T)>0)/dim(history_HEWA$detection_history)[1]
# naive occupancy is 0.366
sum(rowSums(history_OSFL$detection_history, na.rm=T)>0)/dim(history_OSFL$detection_history)[1]
# naive occupancy is 0.73


# Fit occupancy models ----

library(unmarked) # developers: Fiske and Chandler (2011), Ken Kellner (2023)
library(spOccupancy) # developer: Jeff Doser


## Mountain Quail ----
umf_MOQU <- unmarkedFrameOccu(y = history_MOQU$detection_history,
                              #siteCovs = NA,
                              obsCovs = list(
                                #effort = effort_MOQU, # 'effort_MOQU' not yet created
                                time = matrix(c(rep(scale(seq(1,dim(history_MOQU$detection_history)[2], by=1)),
                                                    dim(history_MOQU$detection_history)[1])),
                                              nrow = dim(history_MOQU$detection_history)[1],
                                              ncol = dim(history_MOQU$detection_history)[2],
                                              byrow = T)) )

MOQU.0=occu(~1
            ~1,
            data = umf_MOQU)
MOQU.1=occu(~time
            ~1,
            data = umf_MOQU)
MOQU.2=occu(~time + I(time^2)
            ~1,
            data = umf_MOQU)
modSel(fitList(null=MOQU.0, time=MOQU.1, time2=MOQU.2))

## Hermit Warbler ----
umf_HEWA <- unmarkedFrameOccu(y = history_HEWA$detection_history,
                              #siteCovs = NA,
                              obsCovs = list(
                                #effort = effort_HEWA, # 'effort_HEWA' not yet created
                                time = matrix(c(rep(scale(seq(1,dim(history_HEWA$detection_history)[2], by=1)),
                                                    dim(history_HEWA$detection_history)[1])),
                                              nrow = dim(history_HEWA$detection_history)[1],
                                              ncol = dim(history_HEWA$detection_history)[2],
                                              byrow = T)) )

HEWA.0=occu(~1
            ~1,
            data = umf_HEWA)
HEWA.1=occu(~time
            ~1,
            data = umf_HEWA)
HEWA.2=occu(~time + I(time^2)
            ~1,
            data = umf_HEWA)
modSel(fitList(null=HEWA.0, time=HEWA.1, time2=HEWA.2))

