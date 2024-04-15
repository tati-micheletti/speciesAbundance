## Please do three things to ensure this template is correctly modified:
##
## 1. Rename this file based on the content you are testing using `test-functionName.R` format
##    so that your can directly call `moduleCoverage` to calculate module coverage information.
##    `functionName` is a function's name in your module (e.g., `", name, "Event1`).
##
## 2. Copy this file to the tests folder (i.e., `tests/testthat/`).
##
## 3. Modify the test description based on the content you are testing.
##
getOrUpdatePkg <- function(p, minVer = "0") {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    repo <- c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}
getOrUpdatePkg("testthat")

testthat::test_that("Test full module", {
  
  getOrUpdatePkg("waldo")
  
  Setup <- SpaDES.project::setupProject(
    paths = list(modulePath = "modules/",
                 outputPath = "outputs"),
    modules = "speciesAbundance",
    times = list(start = 2013,
                 end = 2032)
  )
  
  # You may need to set the random seed if your module or its functions use the
  # random number generator.
  set.seed(1234)
  
  # You have two strategies to test your module:
  # 1. Test the overall simulation results for the given objects, using the
  #    sample code below:
  
  results <- testthat::expect_warning(do.call(SpaDES.core::simInitAndSpades, Setup))
  
  # is output a simList?
  testthat::expect_is(results, "simList")
  
  # does output have your module in it
  testthat::expect_true(any(unlist(SpaDES.core::modules(results)) %in% "speciesAbundance"))
  
  # did it run to the end?
  testthat::expect_true(time(results) == 2032)
  
  # 2. Test the functions inside of the module using the sample code below:
  #    To allow the `moduleCoverage` function to calculate unit test coverage
  #    level, it needs access to all functions directly.
  #    Use this approach when using any function within the simList object
  #    (i.e., one version as a direct call, and one with `simList` object prepended).
  
  appenOut <- results$.mods$speciesAbundance$appendRaster(allAbundanceRasters = results$allAbundaRas, 
                                                          newRaster = results$abundaRas)
  
  testthat::expect_is(appenOut, "SpatRaster")
  testthat::expect_equal(names(appenOut)[length(names(appenOut))], "Riparian_Woodland_Reserve: 2022") # or other expect function in testthat package.
  
  currTime <- 2013
  convOut <- results$.mods$speciesAbundance$convertToRaster(dataSet = results$abund, 
                                                            currentTime = currTime, 
                                                            nameRaster = paste0("test:", currTime))
  
  testthat::expect_is(convOut, "SpatRaster")
  testthat::expect_equal(names(convOut), paste0("test:", currTime)) # or other expect 
  
  toRemove <- list.files("modules/speciesAbundance/tests/testthat/", full.names = TRUE)[list.files("modules/speciesAbundance/tests/testthat/") != "test-fullModule.R"]
  invisible(file.remove(toRemove))
  if (file.exists("modules/speciesAbundance/tests/testthat/.Rprofile")) invisible(file.remove("modules/speciesAbundance/tests/testthat/.Rprofile"))
  unlink(toRemove, recursive = TRUE)
  testthat::expect_true(list.files("modules/speciesAbundance/tests/testthat/", full.names = TRUE) == "modules/speciesAbundance/tests/testthat/test-fullModule.R")
})
