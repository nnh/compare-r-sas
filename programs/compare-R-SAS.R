# compare-r-sas
# Mariko Ohtsuka
# 2020/12/17 created
# yyyy/mm/dd fixed
# ------ Remove objects ------
rm(list=ls())
# ------ library ------
library(tidyverse)
library(haven)
library(here)
library(stringr)
# ------ function ------
#' @title CheckDiffVector
#' @description Check the difference between the two vectors
#' @param target_1 : Vector to check
#' @param target_2 : Vector to check
#' @param message_list : Message list of check result
#' @return Message of check result
#' @example dataset_count_check <- CheckDiffVector(r_dataset_names, sas_dataset_names, c("NG：R", "NG：SAS", "OK"))
CheckDiffVector <- function(target_1, target_2, message_list){
  target_1_only <- setdiff(target_1, target_2)
  target_2_only <- setdiff(target_2, target_1)
  check_str <- ""
  if (length(target_1_only) > 0) {
    check_str <- str_c(check_str, message_list[1], str_c(target_1_only, collapse=","))
  }
  if (length(target_2_only) > 0) {
    check_str <- str_c(check_str, message_list[2], str_c(target_2_only, collapse=","))
  }
  if (length(target_1_only) == 0 && length(target_2_only) == 0) {
    check_str = message_list[3]
  }
  return (check_str)
}
#' @title Read_datasets
#' @description Import datasets and create a list of dataset names.
#' @param input_path : path of the input datasets
#' @param file_list : list of the input datasets
#' @param target_ext : extension of the file to be extracted
#' @param prefix_name : prefix for output dataset name
#' @return names of the imported dataset
#' @example r_dataset_names <- Read_datasets(here("input", "R"), r_files, ktargetRExt, "")
Read_datasets <- function(input_path, file_list, target_ext, prefix_name){
  file_path <- file_list %>% str_c(input_path, ., sep="/")
  dataset_names <- file_list %>% str_replace(target_ext, "")
  for (i in 1:length(dataset_names)){
    assign(str_c(prefix_name, dataset_names[i]), read.csv(file_path[i], header=T,stringsAsFactors=F), envir=.GlobalEnv)
  }
  return(dataset_names)
}
# ------ constant ------
ktargetRExt <- ".csv"
ktargetSasExt <- ".csv"
kOutputEol <- "\r\n"
# ------ path setting ------
input_r_path <- here("input", "R")
input_sas_path <- here("input", "SAS")
output_path <- here("output")
# ------ processing ------
# read R datasets
r_files <- list.files(input_r_path) %>% str_replace(str_c("^output_.*_csv\\", ktargetRExt, "$"), "exclusion") %>%
            str_subset(str_c(ktargetRExt, "$"))
r_dataset_names <- Read_datasets(here("input", "R"), r_files, ktargetRExt, "")
# read SAS datasets
sas_files <- list.files(input_sas_path) %>% str_replace(str_c("_contents", ktargetRExt, "$"), "exclusion") %>%
            str_subset(str_c(ktargetSasExt, "$"))
sas_dataset_names <- Read_datasets(input_sas_path, sas_files, ktargetSasExt, "sas_")
# check for over/under dataset
dataset_count_check <- CheckDiffVector(r_dataset_names, sas_dataset_names,
                                     c("NG：Rのみ存在するデータセット：", "NG：SASのみ存在するデータセット：",
                                       "OK：データセット名は同一です"))
output_text <- NULL
output_text <- str_c(output_text, "R : ", str_c(r_dataset_names, collapse=","), kOutputEol)
output_text <- str_c(output_text, "SAS : ", str_c(sas_dataset_names, collapse=","), kOutputEol)
output_text <- str_c(output_text, dataset_count_check, kOutputEol)
for (i in 1:length(r_dataset_names)){
  # trim, sort by subjid
  target_r <- get(r_dataset_names[i]) %>% sapply(trimws) %>% data.frame() %>% arrange(SUBJID)
  target_sas <- get(str_c("sas_", r_dataset_names[i])) %>% sapply(trimws) %>% data.frame() %>% arrange(SUBJID)
  # get the names of variable and sort
  temp_col_r <- colnames(target_r) %>% sort()
  temp_col_sas <- colnames(target_sas) %>% sort()
  # sort variables alphabetically
  target_r <- target_r[,temp_col_r]
  target_sas <- target_sas[,temp_col_sas]
  # delete the variable "Var_Obs" that is not compared
  deleteCheck <- str_detect(temp_col_sas, "Var_Obs") %>% any()
  if (deleteCheck) {
    target_sas <- target_sas %>% select(-Var_Obs)
  }
  # compare variables
  variable_check <- CheckDiffVector(colnames(target_r), colnames(target_sas),
                                   c("NG：Rのみ存在する変数：", "NG：SASのみ存在する変数：", "OK：変数名は同一です"))
  # compare datasets
  if (identical(target_r, target_sas)){
    dataset_check <- str_c("OK : ", r_dataset_names[i], "の内容は同一です")
  } else {
    dataset_check <- str_c("OK : ", r_dataset_names[i], "の内容に相違があります")
  }
  output_text <- str_c(output_text, str_c("****** ", r_dataset_names[i], " ******"),kOutputEol, variable_check, kOutputEol,
                      dataset_check, kOutputEol)
}
write_lines(output_text, str_c(output_path, "/Result_R.txt"))
