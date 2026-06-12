# A fully R-based workflow for BirdNET and occupancy modeling #


# Analyze Audio----

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

# Specify the top-level audio folder
all_folders <- list.dirs('S:/2023_USDA-USFS_CA_163134/163134_SoCalOwls_Dep02_FLAC',
                           recursive = T)

# remove upper-level folders to retain only audio-containing folders
audio_folders <- all_folders[!sapply(all_folders, function(d) {
  any(startsWith(all_folders[all_folders != d], paste0(d, "/")))
})]

length(audio_folders)

# analyze audio
birdnet_output_location <- "./test_data/2025am_outputs" # specify output location (folder must be manually created first)

# note: 32kHz files run at 290-310xRT, a 50% penalty relative to 48kHz

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

# 

#


# Process outputs ----

pak::pak("birdnet-team/birdnetTools") # developer: Sunny Tseng
library(birdnetTools)

## Continuation of 'Initial testing' ----

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

# combine input folder-level output files
outputs_combined <- birdnet_combine(birdnet_output_location) # 'output_location' defined above in the 'analyze audio' step

# minor cleaning for compatibility with downstream commands
names(outputs_combined)[1] <- "filepath"
outputs_combined$'Common Name' = sub(".*_", "", outputs_combined$species_name)

# filter to one species and score
MOQU <- birdnet_filter(outputs_combined,
                       species = "Mountain Quail",
                       threshold = 0.382855133,  # pr(tp)>= 0.9 per 'Thresholds_2024_20260601.csv'
                       #year = 2025,
                       #min_date = "2023-04-01",
                       #max_date = "2023-06-30",
                       #hour = c(0:23) 
                       )
HEWA <- birdnet_filter(outputs_combined,
                       species = "Hermit Warbler",
                       threshold = 0.565058755, # pr(tp)>= 0.9 per 'Thresholds_2024_20260601.csv'
                       #year = 2025,
                       #min_date = "2023-04-01",
                       #max_date = "2023-06-30",
                       #hour = c(0:23) 
                       )

# plenty of quails in these files, no Hermit Warblers

#

# Fit occupancy models ----

library(unmarked) # developers: Fiske and Chandler (2011), Ken Kellner (2023)
library(spOccupancy) # developer: Jeff Doser

