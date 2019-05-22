# ' libname.R
# ' Created date: 2019/5/21
# ' author: mariko ohtsuka
# %macro REFER2WD;
#
#     %local _fullpath _path;
#     %let _fullpath=;
#     %let _path=;
#
#     %if %length(%sysfunc(getoption(sysin)))=0 %then
#       %let _fullpath=%sysget(sas_execfilepath);
#     %else
#       %let _fullpath=%sysfunc(getoption(sysin));
#
#     %let _path=%substr(&_fullpath., 1, %length(&_fullpath.)
#                        -%length(%scan(&_fullpath., -1, '\'))
#                        -%length(%scan(&_fullpath., -2, '\')) -2);
#     &_path.
#
# %mend REFER2WD;
#
# %let ref=%REFER2WD;
# %put &ref.;
#
# /*libname libads "&ref.\ptosh-format\ads" access=readonly;*/
# libname libout "&ref.\output";
# /*libname library "&ref.\ptosh-format\ads";*/
#
# /*%let ads=&ref.\ptosh-format\ads;*/
# %let out=&ref.\output;
# %let raw=&ref.\input\rawdata;
#' @title
#' Refer2Wd
#' @description
#' Find the current working directory
#' @param
#' None
#' @return
#' Current working directory path
#' @example
#' ref <- Refer2Wd()
Refer2Wd <- function(){
  return(here())
}
ref_path <- Refer2Wd()
out_path <- file.path(ref_path, "output")
raw_path <- file.path(ref_path, "input")
#' @title
#' Round2
#' @description
#' Customize round function
#' Reference URL
#' r - Round up from .5 - Stack Overflow
#' https://stackoverflow.com/questions/12688717/round-up-from-5
#' @param
#' x : Number to be rounded
#' digits : Number of decimal places
#' @return
#' Rounded number
#' @example
#' Round2(3.1415, 2)
Round2 <- function(x, digits) {
  posneg = sign(x)
  z = abs(x) * 10^digits
  z = z + 0.5
  z = trunc(z)
  z = z / 10^digits
  return(z * posneg)
}
#' @title
#' SummaryValue
#' @description
#' Return summary and standard deviation of the column of arguments
#' @param
#' input_column : Column to be summarized
#' @return
#' List of length 3
#' [[1]] number of not NA in number of samples
#' [[2]] number of NA in number of samples
#' [[3]] Summary and standard deviation vector
#'       : "Mean", "Sd.", "Median", "1st Qu.", "3rd Qu.", "Min.", "Max."
#' @example
#' SummaryValue(df$col2)
SummaryValue <- function(input_column){
  target_na <- subset(input_column, is.na(input_column))
  target_column <- subset(input_column, !is.na(input_column))
  temp_mean <- format(Round2(mean(target_column), digits=1), nsmall=1)
  temp_summary <- summary(target_column)
  temp_median <- median(target_column)
  temp_quantile <- quantile(target_column, type=2)
  temp_min <- min(target_column)
  temp_max <- max(target_column)
  temp_sd <- format(Round2(sd(target_column), digits=1), nsmall=1)
  return_list <- c(temp_mean, temp_sd, temp_median, temp_quantile[2], temp_quantile[4], temp_min, temp_max)
  names(return_list) <- c("MEAN", "STD", "MEDIAN", "Q1", "Q3", "MIN", "MAX")
  return(list(length(target_column), length(target_na), return_list))
}
#' @title
#' ConstAssignenvironment
#' @description
#' Define an unmodifiable variable
#' @param
#' x : Variable name to define
#' value : The value to define
#' e : environment
#' @return
#' Variable to define
#' @examples
#' ConstAssign("FOO", 1)
ConstAssign <- function(x, value, e=.GlobalEnv){
  if (!exists(x)) {
    assign(x, value, envir=e)
    lockBinding(x, e)
  }
}

