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
CompareDataset <- function(datasetName) {
  file.path(str_c(kInputRPath, datasetName, kRExtention)) |> load()
  r_file <- get(datasetName)
  rm(list = datasetName)
  sas_file  <- file.path(str_c(kInputSasPath, datasetName, kSasExtention)) |> haven::read_sas()  
  rColnames <- r_file |> colnames() |> sort()
  sasColnames <- sas_file |> colnames() |> sort() |> map_if( ~ . == "Var_Obs", ~ NULL) |> discard( ~ is.null(.)) |> list_c()
  if (!identical(rColnames, sasColnames)) {
    print(datasetName)
    stop("Error: The columns of the datasets do not match.")
  }
  for (i in 1:length(sasColnames)) {
    targetColname <- sasColnames[i]
    test1 <- sas_file[[targetColname]] |> as.character()
    test2 <- r_file[[targetColname]] |> as.character()
    if (!identical(test1, test2)) {
      for (j in 1:length(test1)) {
        if (!identical(test1[j], test2[j])) {
          if (test1[j] != "" | !is.na(test2[j])) {
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
# ------ constant ------
kRExtention <- ".Rda"
kSasExtention <- ".sas7bdat"
# ------ path setting ------
kInputRPath <- "C:\\Users\\MarikoOhtsuka\\Documents\\GitHub\\ptosh-format\\ptosh-format\\r-ads\\"
kInputSasPath <- "C:\\Users\\MarikoOhtsuka\\Documents\\GitHub\\ptosh-format\\ptosh-format\\sas-ads\\"
# ------ processing ------
rdaList <- kInputRPath |> list.files(pattern=kRExtention) |> 
  map_if( ~ . == "output_option_csv.Rda" | . == "output_sheet_csv.Rda", ~ NULL) |> discard( ~ is.null(.)) |> list_c()
sas7bdatList <- kInputSasPath |> list.files(pattern=kSasExtention)
datasetList <- str_remove(sas7bdatList, kSasExtention)
if (!identical(str_remove(rdaList, kRExtention), datasetList)) {
  stop("Error: The datasets are not equal.")
}
res <- datasetList |> map( ~ CompareDataset(.))

