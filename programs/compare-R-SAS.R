# compare-r-sas
# Mariko Ohtsuka
# 2020/12/17 created
# 2024/9/25 fixed
# ------ Remove objects ------
rm(list=ls())
# ------ library ------
library(tidyverse)
library(haven)
library(here)
# ------ function ------
GetTargetColnames <- function(df) {
  res <- df |> colnames() |> sort() |> map_if( ~ . == kExcludeVar, ~ NULL) |> discard( ~ is.null(.)) |> list_c()
  return(res)
}
GetRObject <- function(datasetName) {
  file.path(kInputRPath, str_c(datasetName, kRExtention)) |> load()
  r_file <- get(datasetName)
  rm(list = datasetName)
  return(r_file)  
}
CompareDataset <- function(datasetName) {
  r_file <- GetRObject(datasetName)
  sas_file  <- file.path(kInputSasPath, str_c(datasetName, kSasExtention)) |> haven::read_sas()  
  rColnames <- r_file |> colnames() |> sort()
  sasColnames <- sas_file |> GetTargetColnames()
  if (!identical(rColnames, sasColnames)) {
    if (length(setdiff(sasColnames, rColnames)) > 0) {
      print(datasetName)
      stop("Error: The columns of the datasets do not match.")
    } else {
      # rawdataが空だとSAS側で変数が作成されないようなので不一致のすべての値が空白ならテスト通過とする
      diffColnames <- setdiff(rColnames, sasColnames)
      testTarget <- r_file |> select(all_of(diffColnames))
      checkNA <- all(is.na(testTarget))
      if (!all(is.na(testTarget))) {
        # rawdataが空だとSAS側で変数が作成されないようなので不一致のすべての値が空白ならテスト通過とする
        print(datasetName)
        stop("Error: The columns of the datasets do not match.")
      }
    }
  }
  if (datasetName == "ptdata") {
    ptdataColname <<- sasColnames
  }
  
  for (i in 1:length(sasColnames)) {
    targetColname <- sasColnames[i]
    test1 <- sas_file[[targetColname]] |> as.character()
    test2 <- r_file[[targetColname]] |> as.character()
    if (!identical(test1, test2)) {
      for (j in 1:length(test1)) {
        if (!identical(test1[j], test2[j])) {
          if (test1[j] != "" | !is.na(test2[j])) {
            test2[j] <- str_replace_all(test2[j], "搔", "　")
            test2[j] <- str_replace_all(test2[j], "µ", "μ")
            test2[j] <- str_remove_all(test2[j], "\n")
            test2[j] <- str_replace_all(test2[j], "〜", "～")
            test2[j] <- test2[j] |> trimws()
            if (!identical(test1[j], test2[j])) {
              print("compare ng")
              res <- list(colname=targetColname, sas=test1[j], r=test2[j], i=i, j=j)
              return(res)
            }
            
          }
        }
      }
    }
  }
  print(str_c(datasetName, " : compare ok."))
  return(NULL)
}
CreateFolder <- function(path, folderName) {
  outputFolder <- str_c(path, folderName)
  if (!dir.exists(outputFolder)) {
    dir.create(outputFolder)
  }
  return(outputFolder)
}
CreateDataSetForCompareBySas <- function(datasetName) {
  r_file <- GetRObject(datasetName)
  outputFolder <- CreateFolder(kInputRPath, kOutputFolderName)
  dummy <- CreateFolder(kInputSasPath, kOutputFolderName)
  df <- r_file |> map( ~ {
    targetCol <- .
    labels <- attr(targetCol, "labels")
    if (is.null(labels)) {
      return(targetCol)
    }
    res <- factor(targetCol, 
                  levels = labels, 
                  labels = names(labels))
    return(res)
  }) |> bind_rows()
  for (col in names(df)) {
    attr(df[[col]], "label") <- NULL
  }
  write_csv(df, file.path(outputFolder, str_c("r_", datasetName, ".csv")))
}
ExecCompareMain <- function(trialName) {
  kInputRPath <- file.path(kInputPath, str_c("r_ads_", trialName))
  kInputSasPath <- file.path(kInputPath, str_c("sas_ads_", trialName))
  rdaList <- kInputRPath |> list.files(pattern=kRExtention) |> 
    map_if( ~ . == "output_option_csv.Rda" | . == "output_sheet_csv.Rda", ~ NULL) |> discard( ~ is.null(.)) |> list_c()
  sas7bdatList <- kInputSasPath |> list.files(pattern=kSasExtention)
  datasetList <- str_remove(sas7bdatList, kSasExtention)
  if (!identical(str_remove(rdaList, kRExtention), datasetList)) {
    stop("Error: The datasets are not equal.")
  }
  res <- datasetList |> map( ~ CompareDataset(.))
  # ラベル適用後のデータセットを出力する
  dummy <- datasetList |> map( ~ CreateDataSetForCompareBySas(.))
  # フォーマット適用後のデータセット比較：ptdataのみCSVで比較
  r_csv_ptdata <- file.path(kInputRPath, kOutputFolderName, "r_ptdata.csv") |> read.csv(colClasses = "character", na.strings="")
  sas_csv_ptdata <- file.path(kInputSasPath, kOutputFolderName, "sas_ptdata.csv") |> 
    read.csv(fileEncoding="cp932", colClasses = "character") |> select(-all_of(kExcludeVar))
  if (!identical(targetColnames, sort(colnames(r_csv_ptdata)))) {
    r_csv_ptdata <- r_csv_ptdata |> select(all_of(ptdataColname))
  }
  if (!identical(nrow(r_csv_ptdata), nrow(sas_csv_ptdata))) {
    stop("Error: Row Mismatch Detected")
  }
  for (col in 1:ncol(sas_csv_ptdata)) {
    targetColname <- targetColnames[col]
    sas_target <- sas_csv_ptdata[[targetColname]]
    r_target <- r_csv_ptdata[[targetColname]] |> str_replace_all("NA", "")
    if (!identical(sas_target, r_target)) {
      warning(str_c("Error: Value mismatch detected. column: ", targetColname))
    }
  }
}
# ------ constant ------
kRExtention <- ".Rda"
kSasExtention <- ".sas7bdat"
kOutputFolderName <- "csv"
kExcludeVar <- "Var_Obs"
# ------ path setting ------
kInputPath <- "C:\\Users\\MarikoOhtsuka\\Documents\\GitHub\\ptosh-format\\ptosh-format\\"
# ------ processing ------
ExecCompareMain("CJLSG1902")
