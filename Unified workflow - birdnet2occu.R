# A fully R-based workflow for BirdNET and occupancy modeling #


# Analyze Audio----

pak::pak("birdnet-team/birdnetR")
# error: 'could not find tools necessary to compile a package'
# updated R (now 4.5.1), installed Rtools 45, then installation worked.

#install.packages("birdnetR") # developer: Felix Guenther
library(birdnetR) 

# Initialize a BirdNET model
model <- load_birdnet(type = 'acoustic',
                      version = '2.4',
                      backend = 'tf',
                      precision = 'fp32', # what does this actually mean vs 'fp16' or 'int8'
                      lang = 'en_us') 

getwd()
# Specify input audio
audio_folders <- list.dirs('./test_data/G25_C3542_48kHz_wav',
                           recursive = T)

for (folder in audio_folders) {
  files <- list.files(folder, pattern = "\\.flac$", full.names = TRUE) # doesn't work for .flac?
  predictions <- predict(model, files)
  
  out_file <- file.path("results", paste0(basename(folder), ".csv"))
  write_predictions(predictions, 
                    file = out_file,
                    format = 'csv')
}

list.files(audio_folders[1], pattern = "\\.flac$", full.names = TRUE)

# Analyze audio
output <- as.data.frame(predict(model, audio_path))


# Process outputs ----

library(birdnetTools) # developer: Sunny Tseng


# Fit occupancy models ----

library(unmarked) # developers: Fiske and Chandler (2011), Ken Kellner (2023)
library(spOccupancy) # developer: Jeff Doser

