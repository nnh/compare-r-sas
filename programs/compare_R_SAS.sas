**************************************************************************
Program Name : compare_R_SAS.sas
Purpose : 
Author : Kato Kiroku, Mariko Ohtsuka
Date : 2024-9-26
SAS version : 9.4
**************************************************************************;
/*proc datasets library=work kill nolist; quit;*/
options mprint mlogic symbolgen xsync noxwait;
*%let sas_path = C:\Users\MarikoOhtsuka\Documents\GitHub\ptosh-format\ptosh-format\sas-ads; 
libname mylib "&sas_path.";
/* フォーマットカタログを設定 */
options fmtsearch=(mylib);
/* 使用するライブラリを指定 */
%let libname = mylib; /* ライブラリ名を設定 */
%let dataset_list=%str(PTDATA);
%macro create_csv_folder();
    /* フォルダが存在するかを確認 */
    %if %sysfunc(fileexist(&sas_path.\csv)) = 0 %then %do;
        /* フォルダが存在しない場合は作成 */
        systask command "mkdir &sas_path.\csv" shell;
    %end;
%mend create_csv_folder;
/* マクロ変数 dataset_list の内容をカンマで区切って処理するマクロ */
%macro export_all_csvs();
	%create_csv_folder;
	%DO i = 1 %TO %sysfunc(countw(&dataset_list.));
		%let ds = %scan(&dataset_list., &i, %str(,));
		data temp;
    		set mylib.&ds.;
		run;
		proc export data=temp
    		outfile="&sas_path.\csv\sas_&ds..csv" /* 出力先のCSVファイル名 */
    		dbms=csv
    		replace; /* 同名のファイルがあった場合は上書き */
    		putnames=yes; /* 1行目に変数名を含める */
		run;
	%END;
%mend export_all_csvs;
%export_all_csvs;
