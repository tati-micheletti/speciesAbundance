---
title: "speciesAbundance Manual"
subtitle: "v.1.0.0"
date: "Last updated: 2024-04-12"
output:
  bookdown::html_document2:
    toc: true
    toc_float: true
    theme: sandstone
    number_sections: false
    df_print: paged
    keep_md: yes
editor_options:
  chunk_output_type: console
  bibliography: citations/references_speciesAbundance.bib
link-citations: true
always_allow_html: true
---

# speciesAbundance Module

<!-- the following are text references used in captions for LaTeX compatibility -->
(ref:speciesAbundance) *speciesAbundance*



[![made-with-Markdown](figures/markdownBadge.png)](https://commonmark.org)

<!-- if knitting to pdf remember to add the pandoc_args: ["--extract-media", "."] option to yml in order to get the badge images -->

#### Authors:

Tati Micheletti <tati.micheletti@gmail.com> [aut, cre]
<!-- ideally separate authors with new lines, '\n' not working -->

## Module Overview

### Module summary

The species abundance module will run from 2013 to 2022, which are the years for which we have data. The module simply (1) downloads data, (2) converts it to a raster, and (3) plots the data.

### Module inputs and parameters

The module requires only a data frame with the following columns: `counts` (abundance in anumeric form), `years` (year of the data collection in numericform) and coordinates in  latlong system (two columns, `lat` and`long`, indicating latitude and longitude, respectively)
The data for version 1.0.0. is available at: https://zenodo.org/records/10885997/files/abundanceData.csv

Table \@ref(tab:moduleInputs-speciesAbundance) shows the full list of module inputs.

<table class="table" style="margin-left: auto; margin-right: auto;">
<caption>(\#tab:moduleInputs-speciesAbundance)(\#tab:moduleInputs-speciesAbundance)List of (ref:speciesAbundance) input objects and their description.</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> objectName </th>
   <th style="text-align:left;"> objectClass </th>
   <th style="text-align:left;"> desc </th>
   <th style="text-align:left;"> sourceURL </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> abund </td>
   <td style="text-align:left;"> data.frame </td>
   <td style="text-align:left;"> data frame with the following columns: `counts` (abundance in anumeric form), `years` (year of the data collection in numericform) and coordinates in latlong system (two columns, `lat` and`long`, indicating latitude and longitude, respectively).In this example, we use the data v.2.0.0 </td>
   <td style="text-align:left;"> https://zenodo.org/records/10877463/files/abundanceData.csv </td>
  </tr>
</tbody>
</table>

Here is a summary of parameters (Table \@ref(tab:moduleParams-speciesAbundance))

<table class="table" style="margin-left: auto; margin-right: auto;">
<caption>(\#tab:moduleParams-speciesAbundance)(\#tab:moduleParams-speciesAbundance)List of (ref:speciesAbundance) parameters and their description.</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> paramName </th>
   <th style="text-align:left;"> paramClass </th>
   <th style="text-align:left;"> default </th>
   <th style="text-align:left;"> min </th>
   <th style="text-align:left;"> max </th>
   <th style="text-align:left;"> paramDesc </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> .plotInitialTime </td>
   <td style="text-align:left;"> numeric </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> Describes the simulation time at which the first plot event should occur. </td>
  </tr>
  <tr>
   <td style="text-align:left;"> .plotInterval </td>
   <td style="text-align:left;"> numeric </td>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Describes the simulation time interval between plot events. </td>
  </tr>
  <tr>
   <td style="text-align:left;"> areaName </td>
   <td style="text-align:left;"> character </td>
   <td style="text-align:left;"> Riparian.... </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Name for the study area used </td>
  </tr>
</tbody>
</table>

### Events

Before the simulation actually starts, the module will download data (in this case, because the user did not provide it), and then confirm that this data, which should be a data frame, has the expected format. Then in the first year, the module will convert the table of coordinates, years, and counts to a raster (which is a graphic representation of this data in the form of a grid of pixels which have the individual’s counts as their values). In the same year, this raster will be appended to a list that will contain rasters for all the years (or technically speaking, a raster stack), and the module will plot the raster data. This will be done for every year data is available.

### Module outputs

Description of the module outputs (Table \@ref(tab:moduleOutputs-speciesAbundance)).

<table class="table" style="margin-left: auto; margin-right: auto;">
<caption>(\#tab:moduleOutputs-speciesAbundance)(\#tab:moduleOutputs-speciesAbundance)List of (ref:speciesAbundance) outputs and their description.</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> objectName </th>
   <th style="text-align:left;"> objectClass </th>
   <th style="text-align:left;"> desc </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> abundaRas </td>
   <td style="text-align:left;"> SpatRaster </td>
   <td style="text-align:left;"> A raster object of spatially explicit abundance data for a given year </td>
  </tr>
  <tr>
   <td style="text-align:left;"> allAbundaRas </td>
   <td style="text-align:left;"> SpatRaster </td>
   <td style="text-align:left;"> a raster stack of all `abundaRas` </td>
  </tr>
</tbody>
</table>

### Links to other modules

This module is stand-alone, but has been created to be ran with the module `temperature` 
and `speciesAbundTempLM` as a way of demonstrating `SpaDES`.

### Getting help

Detailed module creation and functioning can be found at `https://html-preview.github.io/?url=https://github.com/tati-micheletti/EFI_webinar/blob/main/HandsOn.html`

- Please use GitHub issues (https://github.com/tati-micheletti/speciesAbundance/issues/new) 
if you encounter any problems in using this module.
