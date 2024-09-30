#' title
#' description
#' @file execPtosh-format.R
#' @author Mariko Ohtsuka
#' @date 2024.9.30
#'
################################################ 
# ptosh-format\ptosh-format\program            #
# にこのプログラムをコピーして実行してください #
################################################ 
rm(list=ls())
# ------ libraries ------
library(tidyverse)
library(here)
# ------ constants ------
# ------ functions ------
GetHomeDir <- function() {
  os <- Sys.info()["sysname"]
  if (os == "Windows") {
    home_dir <- Sys.getenv("USERPROFILE")
  } else if (os == "Darwin") {
    home_dir <- Sys.getenv("HOME")
  } else {
    stop("Unsupported OS")
  }
  return (home_dir)
}

ExecPtoshFormat <- function(trialName) {
  ptosh_format_prg_dir <- here("program") 
  ptosh_format_log_dir <- here("log")
  kRawDatafolderName <- "rawdata"
  kExtfolderName <- "ext"
  kSheetCsv <- "sheets.csv"
  kOptionCsv <- "options.csv"
  # remove dir
  if (file.exists(ptosh_format_input_dir) && dir.exists(ptosh_format_input_dir)) {
    unlink(ptosh_format_input_dir, recursive = T)
  }
  # file copy
  dir.create(ptosh_format_input_dir)
  rawdataDir <- file.path(ptosh_format_input_dir, kRawDatafolderName)
  dir.create(rawdataDir)
  extDir <- file.path(ptosh_format_input_dir, kExtfolderName)
  dir.create(extDir)
  inputFolder <- file.path(target_dir, trialName, "input")
  file.copy(file.path(inputFolder, kExtfolderName, kSheetCsv), file.path(extDir))
  file.copy(file.path(inputFolder, kExtfolderName, kOptionCsv), file.path(extDir))
  rawDataList <- list.files(file.path(inputFolder, kRawDatafolderName), full.names=T)
  rawDataList |> map( ~ file.copy(., rawdataDir))
  source(file.path(ptosh_format_prg_dir, "ptosh-format.R"), encoding='utf-8')
  file.rename(here("ads"), here(str_c("r_ads_", trialName)))
}
# ------ main ------
homeDir <- GetHomeDir()
target_dir <- file.path(homeDir, "Box\\Datacenter\\Users\\ohtsuka\\ptosh_format_test")
ptosh_format_dir <- file.path(homeDir, "Documents\\GitHub\\ptosh-format")
ptosh_format_input_dir <- file.path(ptosh_format_dir, "input")
targetTrials <- list.files(target_dir)
for (execPtoshFormatIdx in 1:length(targetTrials)) {
  print(targetTrials[execPtoshFormatIdx])
  ExecPtoshFormat(targetTrials[execPtoshFormatIdx])
  rm(list=setdiff(ls(), c("execPtoshFormatIdx", "targetTrials", "ExecPtoshFormat", "ptosh_format_input_dir", "target_dir")))
}