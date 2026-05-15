# Analyze Audio----

install.packages("birdnetR") # developer: Felix Guenther
library(birdnetR) 

install_birdnet() # prompted by "No version of birdnet found"
reticulate::install_python(list = TRUE) # prompted by "Python release version '3.11' not found"

# Initialize a BirdNET model
model <- birdnet_model_tflite()


# Process outputs ----

library(birdnetTools) # developer: Sunny Tseng


# Fit occupancy models ----

library(unmarked) # developers: Fiske and Chandler (2011), Ken Kellner (2023)
library(spOccupancy) # developer: Jeff Doser

