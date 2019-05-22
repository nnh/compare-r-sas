# ' dm.R
# ' Created date: 2019/5/21
# ' author: mariko ohtsuka
# Initial processing ------
# オブジェクトの削除
# proc datasets library=work kill nolist; quit;
rm(list=ls())
# hereライブラリの読み込み
# hereパッケージが未インストールならインストールする
if (!require("here")) {
  install.packages("here")
  library("here")
}
# タイムゾーンの設定
Sys.setenv("TZ"="Asia/Tokyo")
# カレントディレクトリの取得
# %let cwd=%FIND_WD;
cwd <- here()
# %put &cwd.;
print(cwd)
# %inc "&cwd.\program\macro\libname.sas";
source(file.path(cwd, "R", "macro", "libname.R"))
# Declare function ------
# 関数定義
# %macro COUNT (name, var, title, raw);
#' @title
#' CountFunction
#' @description
#' Create a summary table
#' @param
#' variable : Variable name to be aggregated
#' freq_title : Item name
#' raw_df : Data frame to be aggregated
#' @return
#' Data frame
#' @example
#' x_sex <- CountFunction("sex", "性別", baseline_3)
CountFunction <- function(variable, freq_title, raw_df){
  # 度数を集計
  temp_df <- aggregate(raw_df[ , variable], by=list(raw_df[ , variable]), length, drop=F)
  temp_df[is.na(temp_df)] <- 0
  if (nrow(temp_df) > 0) {
    temp_df[ , kOutputColumnName[3]] <- Round2(prop.table(temp_df[2]) * 100, digits=1)
  } else {
    temp_df <- data.frame(matrix(rep(NA), ncol=length(kOutputColumnName[2:4]), nrow=1))
  }
  # 合計
  colnames(temp_df) <- kOutputColumnName[2:4]
  temp_total <- data.frame(t(c("合計", apply(temp_df[ , kOutputColumnName[3:4]], 2, sum))))
  # 集計結果と合計を結合
  colnames(temp_total) <- kOutputColumnName[2:4]
  temp_df <- rbind(temp_df, temp_total)
  # 一列目の一行目に項目名をセット
  # temp_dfと同じ行数で一列のデータフレームを作成
  temp_item <- data.frame(matrix(rep(NA), ncol=1, nrow=nrow(temp_df)))
  # 項目名の列と集計を結合
  temp_df <- cbind(temp_item, temp_df)
  colnames(temp_df) <- kOutputColumnName
  # 項目名をセット
  temp_df[1, kOutputColumnName[1]] <- freq_title
  return(temp_df)
}
#' @title
#' IqrFunction
#' @description
#' Create a IQR table
#' @param
#' variable : Variable name to be aggregated
#' iqr_title : Item name
#' raw_df : Data frame to be aggregated
#' @return
#' Data frame
#' @example
#' x_spo2 <- IqrFunction("Sp02", "Sp02", baseline_3)
IqrFunction <- function(variable, iqr_title, raw_df){
  # 数値型に変換
  temp_df <- raw_df
  temp_df[ , variable] <- as.numeric(temp_df[ , variable])
  # 欠測(-1)の行を削除
  temp_df <- subset(temp_df, temp_df[ , variable] != -1)
  # 基本統計量
  temp_summary <- SummaryValue(temp_df[ , variable])
  # 結果格納用に4列8行のデータフレームを作成
  output_df <- data.frame(matrix(rep(NA), ncol=4, nrow=8))
  colnames(output_df) <- kOutputColumnName
  output_df[1, kOutputColumnName[1]] <- iqr_title
  output_df[ , kOutputColumnName[2]] <- c("N", names(temp_summary[[3]]))
  output_df[ , kOutputColumnName[3]] <- c(temp_summary[[1]], temp_summary[[3]])
  return(output_df)
}
#' @title
#' CalcAge
#' @description
#' Calculate age
#' @param
#' base_date : Base date of age calculation(date)
#' birth_date : Birthday(date)
#' @return
#' age(numeric)
#' @example
#' registration[i, "age"] <- Calc_age(registration[i, kRegist_date_colname], registration[i, kBirth_date_colname])
CalcAge <- function(base_date, birth_date){
  if (!is.na(base_date)) {
    temp_res <- length(seq(birth_date, base_date, "year")) - 1
  } else {
    temp_res <- NA
  }
  return(temp_res)
}
#' @title
#' EditDfFreetext
#' variable : Variable name
#' iqr_title : Item name
#' input_df : Data frame
#' @return
#' Data frame
#' @example
#' x_disease_t1 <- EditDfFreetext("disease_t1", "原発性肺がん_その他詳細", Round2)
EditDfFreetext <- function(variable, freetext_title, input_df){
  temp_df <- data.frame(rep(NA, nrow(input_df)),
                        input_df[ , variable],
                        rep(NA, nrow(input_df)),
                        rep(NA, nrow(input_df)))
  colnames(temp_df) <- kOutputColumnName
  temp_df[1, kOutputColumnName[1]] <- freetext_title
  return(temp_df)
}
# Declare constant ------
# 定数定義
ConstAssign("kOutputColumnName", c("item", "category", "count", "percent"))
# Main processing ------
# proc import datafile="&raw.\症例登録票.csv"
# out=baseline
# dbms=csv replace;
# run;
baseline <- read.csv(file.path(raw_path, "症例登録票.csv"), as.is=T, fileEncoding="cp932",
                     stringsAsFactors=F, na.strings="")
# data baseline_2;
#     set baseline;
#     if _N_=1 then delete;
# run;
baseline_2 <- baseline[-1, ]
# proc sort data=baseline_2; by subjid; run;
sortlist <- order(baseline_2$subjid)
baseline_2 <- baseline_2[sortlist, ]
# proc import datafile="&raw.\治療.csv"
#                     out=treatment
#                     dbms=csv replace;
# run;
treatment <- read.csv(file.path(raw_path, "治療.csv"), as.is=T, fileEncoding="cp932",
                      stringsAsFactors=F, na.strings="")
# data treatment_2;
#     set treatment;
#     if _N_=1 then delete;
#     keep subjid treat_date;
# run;
treatment_2 <- treatment[-1, c("subjid", "treat_date")]
# proc sort data=treatment_2; by subjid; run;
sortlist <- order(treatment_2$subjid)
treatment_2 <- treatment_2[sortlist, ]
# data baseline_3;
#     merge baseline_2(in=a) treatment_2;
#     by subjid;
#     if a;
#     if treat_date='あり';
# run;
baseline_3 <- merge(baseline_2, treatment_2, by="subjid", all.x=T)
baseline_3 <- subset(baseline_3, treat_date == "あり")
# *年齢;
# data age_baseline;
#     set baseline_3;
#     current=(input(ic_date, YYMMDD10.));
#     birth=(input(birthday, YYMMDD10.));
#     age=intck('YEAR', birth, current);
#     if (month(current) < month(birth)) then age=age - 1;
#     else if (month(current) = month(birth)) and day(current) < day(birth) then age=age - 1;
# run;
# %IQR (age, age, 年齢, age_baseline);
baseline_3[ , "birthday"] <- as.Date(baseline_3[ , "birthday"], origin="1899-12-30")
baseline_3[ , "ic_date"] <- as.Date(baseline_3[ , "ic_date"], origin="1899-12-30")
for (i in 1:nrow(baseline_3)) {
  baseline_3[i, "age"] <- CalcAge(baseline_3[i, "ic_date"], baseline_3[i, "birthday"])
}
x_age <- IqrFunction("age", "年齢", baseline_3)
# *性別;
# %COUNT (sex, sex, 性別, baseline_3);
x_sex <- CountFunction("sex", "性別", baseline_3)
# *原病_原発性肺がん_腺癌;
# %COUNT (disease, disease, 原病_原発性肺がん_腺癌, baseline_3);
x_disease <- CountFunction("disease", "原病_原発性肺がん_腺癌", baseline_3)
# *原病_原発性肺がん_扁平上皮がん;
# %COUNT (VAR6, VAR6, 原病_原発性肺がん_扁平上皮がん, baseline_3);
x_var6 <- CountFunction("disease.1", "原病_原発性肺がん_扁平上皮がん", baseline_3)
# *原病_原発性肺がん_小細胞がん;
# %COUNT (VAR7, VAR7, 原病_原発性肺がん_小細胞がん, baseline_3);
x_var7 <- CountFunction("disease.2", "原病_原発性肺がん_小細胞がん", baseline_3)
# *原病_原発性肺がん_その他;
# %COUNT (VAR8, VAR8, 原病_原発性肺がん_その他, baseline_3);
x_var8 <- CountFunction("disease.3", "原病_原発性肺がん_その他", baseline_3)
# *原発性肺がん_その他詳細;
# data bb_baseline;
#     set baseline_3;
#     if VAR8='該当する';
#     if disease_t1 NE ' ';
# run;
disease_t1_baseline <- subset(baseline_3, disease.3 == "該当する")
disease_t1_baseline <- subset(disease_t1_baseline, !is.na(disease_t1))
# data x_disease_t1;
#     format Item $60. Category $12. Count Percent best12.;
#     set bb_baseline;
#     if _N_=1 then Item='原発性肺がん_その他詳細';
#     Category=disease_t1;
#     count=.;
#     percent=.;
#     keep Item Category Count Percent;
# run;
x_disease_t1 <- EditDfFreetext("disease_t1", "原発性肺がん_その他詳細", disease_t1_baseline)
# *原病_転移性肺がん;
# %COUNT (VAR9, VAR9, 原病_転移性肺がん, baseline_3);
x_var9 <- CountFunction("disease.4", "原病_転移性肺がん", baseline_3)
# *転移性肺がんの原発巣;
# data cc_baseline;
#     set baseline_3;
#     if VAR9='該当する';
#     if disease_t3 NE ' ';
# run;
disease_t3_baseline <- subset(baseline_3, disease.4 == "該当する")
disease_t3_baseline <- subset(disease_t3_baseline, !is.na(disease_t3))
# data x_disease_t3;
#     format Item $60. Category $12. Count Percent best12.;
#     set cc_baseline;
#     if _N_=1 then Item='転移性肺がんの原発巣';
#     Category=disease_t3;
#     count=.;
#     percent=.;
#     keep Item Category Count Percent;
# run;
x_disease_t3 <- EditDfFreetext("disease_t3", "転移性肺がんの原発巣", disease_t3_baseline)
# *原病_リンパ腫;
# %COUNT (VAR10, VAR10, 原病_リンパ腫, baseline_3);
x_var10 <- CountFunction("disease.5", "原病_リンパ腫", baseline_3)
# *原病_その他の悪性腫瘍;
# %COUNT (VAR11, VAR11, 原病_その他の悪性腫瘍, baseline_3);
x_var11 <- CountFunction("disease.6", "原病_その他の悪性腫瘍", baseline_3)
# *その他の悪性腫瘍_その他詳細;
# data dd_baseline;
#     set baseline_3;
#     if VAR11='該当する';
#     if disease_t2 NE ' ';
# run;
disease_t2_baseline <- subset(baseline_3, disease.6 == "該当する")
disease_t2_baseline <- subset(disease_t2_baseline, !is.na(disease_t2))
# data x_disease_t2;
#     format Item $60. Category $12. Count Percent best12.;
#     set dd_baseline;
#     if _N_=1 then Item='その他の悪性腫瘍_その他詳細';
#     Category=disease_t2;
#     count=.;
#     percent=.;
#     keep Item Category Count Percent;
# run;
x_disease_t2 <- EditDfFreetext("disease_t2", "その他の悪性腫瘍_その他詳細", disease_t2_baseline)
# *出血傾向;
# %COUNT (bleeding, bleeding, 出血傾向, baseline_3);
x_bleeding <- CountFunction("bleeding", "出血傾向", baseline_3)
# *出血傾向ありの場合_詳細;
# data bleeding_baseline;
#     set baseline_3;
#     if bleeding='あり';
# run;
bleeding_baseline <- subset(baseline_3, bleeding == "あり")
# data x_bleeding_t1;
#     format Item $60. Category $12. Count Percent best12.;
#     set bleeding_baseline;
#     Item='出血傾向ありの場合_詳細';
#     Category=bleeding_t1;
#     count=.;
#     percent=.;
#     keep Item Category Count Percent;
# run;
x_bleeding_t1 <- EditDfFreetext("bleeding_t1", "出血傾向ありの場合_詳細", bleeding_baseline)
# *抗凝固薬の投与;
# %COUNT (anticoagulation, anticoagulation, 抗凝固薬の投与, baseline_3);
x_anticoagulation <- CountFunction("anticoagulation", "抗凝固薬の投与", baseline_3)
# *PS;
#     %COUNT (PS, PS, PS (ECOG), baseline_3);
x_ps <- CountFunction("PS", "PS (ECOG)", baseline_3)
# *筋弛緩薬使用;
# %COUNT (muscle_relax, muscle_relax, 筋弛緩薬使用, baseline_3);
x_muscle_relax <- CountFunction("muscle_relax", "筋弛緩薬使用", baseline_3)
# *酸素投与;
# %COUNT (oxygen, oxygen, 酸素投与, baseline_3);
x_oxygen <- CountFunction("oxygen", "酸素投与", baseline_3)
# *出血傾向ありの場合_詳細;
# data oxy_baseline;
#     set baseline_3;
#     if oxygen='あり';
# run;
oxy_baseline <- subset(baseline_3, oxygen == "あり")
# %IQR (oxygen_L, oxygen_L, 酸素投与ありの場合_酸素投与量_L_分, oxy_baseline);
x_oxygen_l <- IqrFunction("oxygen_L", "酸素投与ありの場合_酸素投与量_L_分", oxy_baseline)
# *SpO2;
# %IQR (Sp02, Sp02, SpO2, baseline_3);
x_spo2 <- IqrFunction("Sp02", "Sp02", baseline_3)
# data DM;
#     set x_age x_sex x_disease x_VAR6 x_var7 x_var8 x_disease_t1 x_var9 x_disease_t3 x_var10 x_var11 x_disease_t2
#     x_bleeding x_bleeding_t1 x_anticoagulation x_PS x_muscle_relax x_oxygen x_oxygen_l x_Sp02;
# run;
dm <- rbind(x_age, x_sex, x_disease, x_var6, x_var7, x_var8, x_disease_t1, x_var9, x_disease_t3, x_var10, x_var11,
            x_disease_t2, x_bleeding, x_bleeding_t1, x_anticoagulation, x_ps, x_muscle_relax, x_oxygen, x_oxygen_l,
            x_spo2)
# %ds2csv (data=DM, runmode=b, csvfile=&out.\SAS\DM.csv, labels=N);
write.csv(dm, paste0(out_path, "/DM.csv"), row.names=F, fileEncoding="cp932", na="")
