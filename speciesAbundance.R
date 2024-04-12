## Everything in this file and any files in the R directory are sourced during `simInit()`;
## all functions and objects are put into the `simList`.
## To use objects, use `sim$xxx` (they are globally available to all modules).
## Functions can be used inside any function that was sourced in this module;
## they are namespaced to the module, just like functions in R packages.
## If exact location is required, functions will be: `sim$.mods$<moduleName>$FunctionName`.
defineModule(sim, list(
  name = "speciesAbundance",
  description = paste0("This is a simple example module on how SpaDES work. It uses made up data",
                       "and is partially based on the example publised by Barros et al., 2022",
                       "(https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/2041-210X.14034)"),
  keywords = c("example", "SpaDES tutorial"),
  authors = structure(list(list(given = "Tati", family = "Micheletti", role = c("aut", "cre"), 
                                email = "tati.micheletti@gmail.com", comment = NULL)), 
                      class = "person"),
  childModules = character(0),
  version = list(speciesAbundance = "1.0.0"),
  timeframe = as.POSIXlt(c(2013, 2022)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("NEWS.md", "README.md", "speciesAbundance.Rmd"),
  reqdPkgs = list("SpaDES.core (>= 2.0.3)", "terra", "reproducible", "ggplot2"),
  parameters = bindrows(
    defineParameter(".plotInitialTime", "numeric", start(sim), start(sim), end(sim),
                    "Describes the simulation time at which the first plot event should occur."),
    defineParameter(".plotInterval", "numeric", 5, NA, NA,
                    "Describes the simulation time interval between plot events."),
    defineParameter("areaName", "character", "Riparian_Woodland_Reserve", NA, NA,
                    "Name for the study area used")
  ),
  inputObjects = bindrows(
    expectsInput(objectName = "abund", 
                 objectClass = "data.frame", 
                 desc = paste0("data frame with the following columns: `counts` (abundance in a",
                               "numeric form), `years` (year of the data collection in numeric",
                               "form) and coordinates in  latlong system (two columns, `lat` and",
                               "`long`, indicating latitude and longitude, respectively).",
                               "In this example, we use the data v.2.0.0"), 
                 sourceURL = "https://zenodo.org/records/10877463/files/abundanceData.csv")
  ),
  outputObjects = bindrows(
    createsOutput(objectName = "abundaRas", objectClass = "SpatRaster", 
                  desc = "A raster object of spatially explicit abundance data for a given year"),
    createsOutput(objectName = "allAbundaRas", objectClass = "SpatRaster",
                  desc = "a raster stack of all `abundaRas`")
  )
))

## event types
#   - type `init` is required for initialization

doEvent.speciesAbundance = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      ### check for more detailed object dependencies:
      ### (use `checkObject` or similar)
      
      # do stuff for this event
      # Check the data
      if (!is(sim$abund, "data.table"))
        sim$abund <- data.table(sim$abund)
      
      if (!all("abundance" %in% names(sim$abund), 
               "years" %in% names(sim$abund),
               "lat" %in% names(sim$abund),
               "long" %in% names(sim$abund)))
        stop("Please revise the column names in the abundance data")
      
      # schedule future event(s)
      sim <- scheduleEvent(sim, time(sim), "speciesAbundance", "tableToRasters")
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "speciesAbundance", "plot")
    },
    tableToRasters = {
      # ! ----- EDIT BELOW ----- ! #
      
      # do stuff for this event
      sim$abundaRas <- convertToRaster(dataSet = sim$abund, 
                                       currentTime = time(sim),
                                       nameRaster = paste0(P(sim)$areaName, ": ", time(sim)))
      sim$allAbundaRas <- appendRaster(allAbundanceRasters = sim$allAbundaRas, 
                                       newRaster = sim$abundaRas)
      
      # schedule future event(s)
      if (time(sim) < max(as.numeric(sim$abund[, years])))
        sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundance", "tableToRasters")
      
      # ! ----- STOP EDITING ----- ! #
    },
    plot = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event
      terra::plot(sim$abundaRas, main = paste0(P(sim)$areaName, ": ", time(sim)))

      if (time(sim) == max(as.numeric(sim$abund[, years]))){
        saveAbundRasters(allAbundanceRasters = sim$allAbundaRas, 
                         savingName = P(sim)$areaName, 
                         savingFolder = Paths$output)
      }
      
      # schedule future event(s)
      if ((time(sim) + P(sim)$.plotInterval) < max(as.numeric(sim$abund[, years])))
        sim <- scheduleEvent(sim, time(sim) + P(sim)$.plotInterval, 
                             "speciesAbundance", "plot")
      
      # ! ----- STOP EDITING ----- ! #
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

## event functions
#   - keep event functions short and clean, modularize by calling subroutines from section below.

convertToRaster <- function(dataSet, currentTime, nameRaster){
  ras <- rast(dataSet[years == currentTime, c("lat", "long", "abundance")], type="xyz")
  terra::crs(ras) <- "GEOGCRS[\"WGS 84 (CRS84)\",\n    DATUM[\"World Geodetic System 1984\",\n        ELLIPSOID[\"WGS 84\",6378137,298.257223563,\n            LENGTHUNIT[\"metre\",1]]],\n    PRIMEM[\"Greenwich\",0,\n        ANGLEUNIT[\"degree\",0.0174532925199433]],\n    CS[ellipsoidal,2],\n        AXIS[\"geodetic longitude (Lon)\",east,\n            ORDER[1],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n        AXIS[\"geodetic latitude (Lat)\",north,\n            ORDER[2],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n    USAGE[\n        SCOPE[\"unknown\"],\n        AREA[\"World\"],\n        BBOX[-90,-180,90,180]],\n    ID[\"OGC\",\"CRS84\"]]"
  names(ras) <- nameRaster
  return(ras)
}

appendRaster <- function(allAbundanceRasters, newRaster){
  if (is.null(allAbundanceRasters)){
    # This would happen in the first time we are appending the raster
    allAbundanceRasters <- newRaster
  } else {
    # This would happen in the next times
    allAbundanceRasters <- c(allAbundanceRasters, newRaster)
  }
  return(allAbundanceRasters)
}

saveAbundRasters <- function(allAbundanceRasters, savingName, savingFolder){
  terra::writeRaster(x = allAbundanceRasters,
                     filetype = "GTiff",
                     filename = file.path(savingFolder, paste0(savingName, "_abundance.tif")), 
                     overwrite = TRUE)
  message(paste0("All rasters saved to: \n", 
                 file.path(savingFolder, paste0(savingName, ".tif"))))
}


.inputObjects <- function(sim) {
  # Any code written here will be run during the simInit for the purpose of creating
  # any objects required by this module and identified in the inputObjects element of defineModule.
  # This is useful if there is something required before simulation to produce the module
  # object dependencies, including such things as downloading default datasets, e.g.,
  # downloadData("LCC2005", modulePath(sim)).
  # Nothing should be created here that does not create a named object in inputObjects.
  # Any other initiation procedures should be put in "init" eventType of the doEvent function.
  # Note: the module developer can check if an object is 'suppliedElsewhere' to
  # selectively skip unnecessary steps because the user has provided those inputObjects in the
  # simInit call, or another module will supply or has supplied it. e.g.,
  # if (!suppliedElsewhere('defaultColor', sim)) {
  #   sim$map <- Cache(prepInputs, extractURL('map')) # download, extract, load file from url in sourceURL
  # }
  
  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  
  # ! ----- EDIT BELOW ----- ! #
  if (!suppliedElsewhere(object = "abund", sim = sim)) {
    sim$abund <- reproducible::prepInputs(url = extractURL("abund"),
                            targetFile = "abundanceData.csv",
                            destinationPath = dPath,
                            fun = "read.csv",
                            header = TRUE)
    warning(paste0("abund was not supplied. Using example data"), immediate. = TRUE)
  }
  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}
