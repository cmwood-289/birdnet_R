# A fully R-based workflow for BirdNET and occupancy modeling #


# Analyze Audio----

pak::pak("birdnet-team/birdnetR") # developer: Felix Guenther
# error: 'could not find tools necessary to compile a package'
# updated R (now 4.5.1), installed Rtools 45, then installation worked.

library(birdnetR) 

# Initialize a BirdNET model
model <- load_birdnet(type = 'acoustic',
                      version = '2.4',
                      backend = 'tf',
                      precision = 'fp32', # what does this actually mean vs 'fp16' or 'int8'
                      lang = 'en_us') 

## Specify input audio top-level folder ----

# two interchangeable options, one for wav / flac
audio_folders <- list.dirs('./test_data/G25_C3542_48kHz_wav/audio/0429_0430',
                           recursive = F)
audio_folders <- list.dirs('./test_data/G25_C3542_48kHz_flac/audio/0424_0425',
                           recursive = F)

## analyze audio----

birdnet_output_location <- "./test_data/G25_C3542_48kHz_wav/outputs/0429_0430"

for (folder in audio_folders) {
  files <- list.files(folder, pattern = "\\.wav$", full.names = TRUE) # doesn't work for .flac?
  #files <- list.files(folder, pattern = "\\.flac$", full.names = TRUE) # doesn't work for .flac?
  predictions <- predict(model, files)
  
  out_file <- file.path(birdnet_output_location, paste0(basename(folder), ".csv"))
  write_predictions(predictions, 
                    file = out_file,
                    format = 'csv')
  print(paste(which(audio_folders==folder),"of", length(audio_folders), "input folders", sep=" "))
}

# 48kHz flac was 696-687xRT; 48kHz .wav was 754-653 xRT


# Process outputs ----

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


# Fit occupancy models ----

library(unmarked) # developers: Fiske and Chandler (2011), Ken Kellner (2023)
library(spOccupancy) # developer: Jeff Doser

