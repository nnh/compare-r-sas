# compare-r-sas
# Mariko Ohtsuka
# 2020/12/17 created
# 2024/9/30 fixed
# ------ Remove objects ------
rm(list=ls())
# ------ library ------
library(tidyverse)
library(haven)
library(here)
# ------ function ------
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
GetTargetColnames <- function(df) {
  res <- df |> colnames() |> sort() |> map_if( ~ . == kExcludeVar, ~ NULL) |> discard( ~ is.null(.)) |> list_c()
  return(res)
}
GetRObject <- function(datasetName) {
  tempFileNames <- kInputRPath |> list.files()
  targetFileName <- tempFileNames |> str_extract(str_c("(?i)^", datasetName, kRExtention, "$")) |> na.omit()
  file.path(kInputRPath, targetFileName) |> load()
  r_file <- get(str_remove(targetFileName, kRExtention))
  tempColnames <- r_file |> colnames() |> trimws()
  colnames(r_file) <- tempColnames
  rm(list = str_remove(targetFileName, kRExtention))
  return(r_file)  
}
ExcludeTargetColumns <- function(datasetName, sasColnames) {
  if (is.null(excludeColumns)) {
    return(sasColnames)
  }
  for (i in 1:length(excludeColumns)) {
    tempDatasetName <- excludeColumns[[i]]$datasetName
    tempColname <- excludeColumns[[i]]$colname
    if (is.null(tempDatasetName)) {
      sasColnames <- sasColnames[!sasColnames %in% tempColname]
    } else {
      if (datasetName == tempDatasetName) {
        sasColnames <- sasColnames[!sasColnames %in% tempColname]
      }
    }
  }
  return(sasColnames)
}
CompareDataset <- function(datasetName) {
  r_file <- GetRObject(datasetName)
  sas_file  <- file.path(kInputSasPath, str_c(datasetName, kSasExtention)) |> haven::read_sas()  
  rColnames <- r_file |> colnames() |> sort()
  sasColnames <- sas_file |> GetTargetColnames()
  sasColnames <- sasColnames %>% ExcludeTargetColumns(datasetName, .)
  if (!identical(rColnames, sasColnames)) {
    if (length(setdiff(sasColnames, rColnames)) > 0) {
      print(datasetName)
      stop("Error: The columns of the datasets do not match.")
    } else {
      # rawdataが空だとSAS側で変数が作成されないようなので不一致のすべての値が空白ならテスト通過とする
      diffColnames <- setdiff(rColnames, sasColnames)
      testTarget <- r_file |> select(all_of(diffColnames))
      checkNA <- testTarget |> map( ~ {
        test <- . |> map_if( ~ is.na(.), ~ NULL) |> discard( ~ is.null(.))
        if (length(test) == 0) {
          return(NULL)
        } else {
          return("test")
        }
      }) |> discard( ~ is.null(.))
      if (!all(is.na(testTarget)) | length(checkNA) > 0) {
        # rawdataが空だとSAS側で変数が作成されないようなので不一致のすべての値が空白ならテスト通過とする
        print(datasetName)
        checkNA <<- checkNA
        stop("Error: The columns of the datasets do not match.")
      }
    }
  }
  if (datasetName == "ptdata") {
    ptdataColname <<- sasColnames |> str_replace("^NA$", "NA.")
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
            test2[j] <- str_replace_all(test2[j], "−", "－")
            test1[j] <- str_remove(test1[j], "\t$")
            if (test2[j] == "100000" & test1[j] == "1e+05") {
              test2[j] <- "1e+05"
            }
            test2[j] <- test2[j] |> trimws()
            if (!identical(test1[j], test2[j])) {
              stop()
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
  outputFolder <- file.path(path, folderName)
  if (!dir.exists(outputFolder)) {
    dir.create(outputFolder)
  }
  return(outputFolder)
}
CreateDataSetForCompareBySas <- function(datasetName) {
  r_file <- GetRObject(datasetName)
  outputFolder <- CreateFolder(kInputRPath, kOutputFolderName)
  dummy <- CreateFolder(kInputSasPath, kOutputFolderName)
  df <- data.frame()
  for (i in 1:ncol(r_file)) {
    targetCol <- r_file[ , i]
    labels <- attr(targetCol, "labels")
    if (!is.null(labels)) {
      tempCol <- factor(targetCol, 
                        levels = labels, 
                        labels = names(labels))
    } else {
      tempCol <- targetCol
    }
    df[1:nrow(r_file) , i] <- tempCol
  }
  colnames(df) <- colnames(r_file)
  for (col in names(df)) {
    attr(df[[col]], "label") <- NULL
  }
  write_csv(df, file.path(outputFolder, str_c("r_", datasetName, ".csv")))
}
ExecCompareMain <- function(trialName) {
  if (trialName == "JSH-MM-15" | 
      trialName == "NHOC-PH" | 
      trialName == "JPLSG-B-NHL-14") {
    excludeColumns <<- list(
      list(datasetName=NULL, colname="VAR3")
    )
  } else if (trialName == "JPLSG-ALL-B12") {
    excludeColumns <<- list(
      list(datasetName=NULL, colname="VAR3"),
      list(datasetName=NULL, colname="VAR4"),
      list(datasetName=NULL, colname="VAR5"),
      list(datasetName=NULL, colname="VAR6"),
      list(datasetName=NULL, colname="VAR7")
    )
    
  } else {
    excludeColumns <<- NULL
  }
  
  kInputRPath <<- file.path(kInputPath, str_c("r_ads_", trialName))
  kInputSasPath <<- file.path(kInputPath, str_c("sas_ads_", trialName))
  rdaList <- kInputRPath |> list.files(pattern=kRExtention) |> 
    map_if( ~ . == "output_option_csv.Rda" | . == "output_sheet_csv.Rda", ~ NULL) |> discard( ~ is.null(.)) |> list_c()
  sas7bdatList <- kInputSasPath |> list.files(pattern=kSasExtention)
  datasetList <- str_remove(sas7bdatList, kSasExtention)
  if (!identical(tolower(str_remove(rdaList, kRExtention)), datasetList)) {
    # R側だけ存在するデータセットの場合、その値が全て空白ならOKとする
    if (length(setdiff(datasetList, tolower(str_remove(rdaList, kRExtention)))) > 0) {
      stop("Error: The datasets are not equal.")
    }
    temp <- setdiff(tolower(str_remove(rdaList, kRExtention)), datasetList)
    for (i in 1:length(temp)) {
      temp2 <- GetRObject(temp[i])
      if (nrow(temp2) > 0) {
        stop("Error: The datasets are not equal.")
      }
    }
  }
  res <- datasetList |> map( ~ CompareDataset(.))
  # ラベル適用後のデータセットを出力する
  dummy <- datasetList |> map( ~ CreateDataSetForCompareBySas(.))
  # フォーマット適用後のデータセット比較：ptdataのみCSVで比較
  r_csv_ptdata <- file.path(kInputRPath, kOutputFolderName, "r_ptdata.csv") |> read.csv(colClasses = "character", na.strings="")
  sas_csv_ptdata <- file.path(kInputSasPath, kOutputFolderName, "sas_ptdata.csv") |> 
    read.csv(fileEncoding="cp932", colClasses = "character") |> select(-all_of(kExcludeVar))
  if (!identical(sort(colnames(sas_csv_ptdata)), sort(colnames(r_csv_ptdata)))) {
    r_csv_ptdata <- r_csv_ptdata |> select(all_of(ptdataColname))
  }
  if (!identical(nrow(r_csv_ptdata), nrow(sas_csv_ptdata))) {
    stop("Error: Row Mismatch Detected")
  }
  for (col in 1:length(ptdataColname)) {
    targetColname <- ptdataColname[col]
    sas_target <- sas_csv_ptdata[[targetColname]]
    if ((trialName == "JPLSG-ALL-B12" & targetColname == "TP2_PCRMRD") |
        (trialName == "JPLSG-ALL-T11" & targetColname == "PCRMRD_TP2")) {
      r_target <- r_csv_ptdata[[targetColname]] |> 
        str_replace_all("≤", "　")
    } else {
      r_target <- r_csv_ptdata[[targetColname]]
    }
    r_target <- r_target |> 
      str_replace_all("^NA$", "")  |> 
      str_replace_all("\n", "") |>  
      trimws()
    if (!identical(sas_target, r_target)) {
      stop(str_c("Error: Value mismatch detected. column: ", targetColname, ": SAS:", sas_target[1], ": R:", r_target[1]))
      print(sas_target[1])
      print(r_target[1])
    }
  }
}
# ------ constant ------
kRExtention <- ".Rda"
kSasExtention <- ".sas7bdat"
kOutputFolderName <- "csv"
kExcludeVar <- "Var_Obs"
# ------ path setting ------
homeDir <- GetHomeDir()
targetTrials <- file.path(homeDir, "Box\\Datacenter\\Users\\ohtsuka\\ptosh_format_test") |> list.files()
issue7Negative <- c("issue7_1", "issue7_2", "issue7_3", "issue7_4", "issue7_5") # stopエラーになるのが正なので個別にテストを実行する必要がある
excludedTrials <- c("JRESG-RES-FCD", "JRESG-RESR-2023") # R側で出力0件のため比較対象外とする
targetTrials <- targetTrials |> setdiff(issue7Negative) |> setdiff(excludedTrials)
kInputPath <- "C:\\Users\\MarikoOhtsuka\\Documents\\GitHub\\ptosh-format\\ptosh-format\\"
# ------ processing ------
for (i in 1:length(targetTrials)) {
  print(targetTrials[i])
  ExecCompareMain(targetTrials[i])
}
