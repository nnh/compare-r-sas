# compare-r-sas
## 概要
ptosh-format.sasとptosh-format.Rで出力したCSVファイルの比較を行い、結果をoutputフォルダに出力する。
## 処理実行に必要なディレクトリ構造
```
.
├── input
│   ├── R
│   └── SAS
└── programs
    ├── compare-R-SAS.R
    ├── compare_R_SAS.sas
    └── replaceCrlf.vbs
```
## 実行手順
SASの場合は該当プログラムをSAS（日本語）で開きサブミットする。  
Rの場合はcompare-r-sas/でCreate Projectして該当のプログラムを開きSourceかRunで実行する。  
## License
compare-r-sas are licensed under the MIT license.  
Copyright © 2021, NHO Nagoya Medical Center and NPO-OSCR.  
