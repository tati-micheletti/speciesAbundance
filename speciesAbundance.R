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
  version = list(speciesAbundance = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(2013, 2022)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("NEWS.md", "README.md", "speciesAbundance.Rmd"),
  reqdPkgs = list("SpaDES.core (>= 2.0.3)", "ggplot2"),
  parameters = bindrows(
    defineParameter(".plotInitialTime", "numeric", start(sim), start(sim), end(sim),
                    "Describes the simulation time at which the first plot event should occur."),
    defineParameter(".studyAreaName", "character", "Riparian Woodland Reserve", NA, NA,
                    "Human-readable name for the study area used - e.g., a hash of the study",
                    "area obtained using `reproducible::studyAreaName()`")
  ),
  inputObjects = bindrows(
    expectsInput(objectName = "abund", 
                 objectClass = NA, 
                 desc = paste0("data frame with the following columns: `counts` (abundance in a",
                               "numeric form), `years` (year of the data collection in numeric",
                               "form) and coordinates in  latlong system (two columns, `lat` and",
                               "`long`, indicating latitude and longitude, respectively)"), 
                 sourceURL = "https://github.com/tati-micheletti/EFI_webinar/raw/main/abundanceData.csv")
  ),
  outputObjects = bindrows(
    createsOutput(objectName = "abundaRas", objectClass = "spatRaster", 
                  desc = "A raster object of spatially explicit abundance data for a given year"),
    createsOutput(objectName = "allAbundaRas", objectClass = "spatRaster", #<~~~~~~~~~~~~~~ DOUBLE CHECK THE CLASS UPLOADED!
                  desc = "a raster stack of all `abundaRas`"),  
    createsOutput(objectName = "modAbund", objectClass = "lm", 
                  desc = paste0("A fitted model (of the `lm` class) of abundance through time"))
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
      
      if (!all("abundance" %in% names(abund), 
               "years" %in% names(abund),
               "lat" %in% names(abund),
               "long" %in% names(abund)))
        stop("Please revise the column names in the abundance data")
      
      lastYearOfData <- max(as.numeric(sim$abund[, c("years")]))
      
      # schedule future event(s)
      sim <- scheduleEvent(sim, time(sim), "speciesAbundance", "tableToRasters")
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "speciesAbundance", "plot")
      sim <- scheduleEvent(sim, lastYearOfData, "speciesAbundance", "abundanceThroughTime")
    },
    tableToRasters = {
      # ! ----- EDIT BELOW ----- ! #
      
      # do stuff for this event
      sim$abundaRas <- convertToRaster(dataSet = sim$abund, 
                                       currentTime = time(sim))
      sim$allAbundaRas <- appendRaster(allAbundanceRasters = sim$allAbundaRas, 
                                       newRaster = sim$abundaRas)
      
      # schedule future event(s)
      sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundance", "tableToRasters")
      
      # ! ----- STOP EDITING ----- ! #
    },
    plot = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event
      plotAbundance(abundanceData = sim$abund, yearsToPlot = start(sim):time(sim))
      plot(ras, main = paste0(P(sim)$.studyAreaName, ": ", time(sim)))
      # schedule future event(s)
      sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundance", "plot")
      
      # ! ----- STOP EDITING ----- ! #
    },
    abundanceThroughTime = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event
      
      sim$modAbund <- modelAbundTime(abundanceData = sim$abund)
      
      # schedule future event(s)
      # No need to schedule further events as this one happens at the end of the 
      # module's data
      
      # ! ----- STOP EDITING ----- ! #
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}
## event functions
#   - keep event functions short and clean, modularize by calling subroutines from section below.

convertToRaster <- function(dataSet, currentTime){
  ras <- rast(dataSet[years == currentTime, c("lat", "lon", "abundance")], type="xyz")
  crs(ras) <- "GEOGCRS[\"WGS 84 (CRS84)\",\n    DATUM[\"World Geodetic System 1984\",\n        ELLIPSOID[\"WGS 84\",6378137,298.257223563,\n            LENGTHUNIT[\"metre\",1]]],\n    PRIMEM[\"Greenwich\",0,\n        ANGLEUNIT[\"degree\",0.0174532925199433]],\n    CS[ellipsoidal,2],\n        AXIS[\"geodetic longitude (Lon)\",east,\n            ORDER[1],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n        AXIS[\"geodetic latitude (Lat)\",north,\n            ORDER[2],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n    USAGE[\n        SCOPE[\"unknown\"],\n        AREA[\"World\"],\n        BBOX[-90,-180,90,180]],\n    ID[\"OGC\",\"CRS84\"]]"
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

plotAbundance <- function(abundanceData, yearsToPlot){
  dataplot <- abundanceData[years %in% yearsToPlot,]
  abundData <- Copy(dataplot)
  abundData[, years := as.factor(years)]
  abundData[, averageYear := mean(abundance), by = "years"]
  pa <- ggplot(data = abundData, aes(x = abundance, group=years, color=years, fill = years)) +
    geom_histogram(binwidth=5) +
    facet_grid(years ~ .) +
    geom_vline(data = unique(abundData[, c("years", "averageYear")]),
               aes(xintercept = averageYear),
               linetype="dashed", color = "black") +
    theme(legend.position = "none")
  return(pa)
}

modelAbundTime <- function(abundanceData){
  modAbund <- lm(formula = abundance ~ years, data = abundanceData)
  summary(modAbund)
  return(modAbund)
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
    sim$abund <- prepInputs(url = extractURL("abund"),
                            targetFile = "abundanceData.csv",
                            destinationPath = dPath,
                            fun = "data.frame",
                            header = TRUE)
    warning(paste0("abund was not supplied. Using example data"), immediate. = TRUE)
  }
  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}