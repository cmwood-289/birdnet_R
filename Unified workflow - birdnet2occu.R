# Analyze Audio----

pak::pak("birdnet-team/birdnetR")
# error: 'could not find tools necessary to compile a package'
# updated R (now 4.5.1), installed Rtools 45, then installation worked.

#install.packages("birdnetR") # developer: Felix Guenther
library(birdnetR) 

# Initialize a BirdNET model
model <- load_birdnet() # how much version control do we have here?


getwd()
# Specify input audio
# not currently working, waiting for Felix's input
audio_path <- system.file("./test_data",
                          "163134SoCalOwls02_032K_G25-C3642-U1_S0062_20250424_180000-0700.flac", 
                          package = "birdnetR")

file.path("./test_data/163134SoCalOwls02_032K_G25-C3642-U1_S0062_20250424_180000-0700.flac")


# Analyze audio
output <- as.data.frame(predict(model, audio_path))


# Process outputs ----

library(birdnetTools) # developer: Sunny Tseng


# Fit occupancy models ----

library(unmarked) # developers: Fiske and Chandler (2011), Ken Kellner (2023)
library(spOccupancy) # developer: Jeff Doser

