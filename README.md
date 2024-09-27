# compare-r-sas

## 概要

ptosh-format.sas で出力した sas7bdat ファイルと ptosh-format.R で出力した rda ファイルの比較を行う。

## 実行手順

1. execPtosh-format.sas を ptosh-format\ptosh-format\program にコピーして実行する。`試験名_sas-ads` フォルダの下に`csv`フォルダが作成され、その中に`sas_PTDATA.csv`が作成される。
1. R Studio を開き、compare-r-sas/で Create Project する。
1. compare-R-SAS.r を Source か Run で実行する。r-ads フォルダの下に`csv`フォルダが作成され、その中に各 rda ファイルが CSV に変換されたファイルが作成される。
1. 比較結果はコンソールに出力される。差分があった場合は R Studio で rda ファイルを開き、SAS で sas7bdat ファイルを開き、内容を比較する。

## License

compare-r-sas are licensed under the MIT license.  
Copyright © 2024, NHO Nagoya Medical Center and NPO-OSCR.
