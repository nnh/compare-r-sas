**************************************************************************
Program Name : compare_R_SAS.sas
Purpose : 
Author : Kato Kiroku, Mariko Ohtsuka
Date : 2024-9-26
SAS version : 9.4
**************************************************************************;
proc datasets library=work kill nolist; quit;
options mprint mlogic symbolgen xsync noxwait;
%let r_path = C:\Users\MarikoOhtsuka\Documents\GitHub\ptosh-format\ptosh-format\r-ads\csv; 
%let sas_path = C:\Users\MarikoOhtsuka\Documents\GitHub\ptosh-format\ptosh-format\sas-ads; 
libname mylib "&sas_path.";
/* フォーマットカタログを設定 */
options fmtsearch=(mylib);
/* CSVファイルを取得するデータセットを作成 */
filename mydir "&r_path.";

data csv_files;
    rc = filename('mydir', "&r_path."); /* ディレクトリ名を指定 */
    did = dopen('mydir'); /* ディレクトリを開く */

    /* ファイルが存在する場合 */
    if did > 0 then do;
        /* ディレクトリ内のファイル数を取得 */
        num_files = dnum(did);

        /* 各ファイルの名前を取得 */
        do i = 1 to num_files;
            filename = dread(did, i); /* ファイル名を取得 */
            /* CSVファイルだけをフィルタリング */
            if scan(filename, -1, '.') = 'csv' then do;
                output; /* データセットに追加 */
                file_name = filename; /* ファイル名をデータセットに格納 */
            end;
        end;

        /* ディレクトリを閉じる */
        rc = dclose(did);
    end;

    /* フォルダが存在しない場合 */
    else put "ERROR: Directory does not exist.";
run;

/* CSVファイルをインポートするマクロ */
%macro import_csv(csv_name);
    /* CSVファイル名からデータセット名を作成 */
    %let ds_name = %sysfunc(scan(&csv_name, 1, .));  /* 拡張子を除いたファイル名 */
    %if %substr(&ds_name, 1, 2) = r_ %then %do;
    	%let sas_name = %substr(&ds_name, 3); /* 3文字目以降を取得 */
	%end;
	%else %do;
    	%let sas_name = &ds_name; /* 変更しない */
	%end;

    /* CSVファイルを読み込む */
    proc import datafile="&r_path\&csv_name" 
                out=&ds_name 
                dbms=csv 
                replace;
        getnames=yes;         /* 1行目を列名として使用 */
        guessingrows=MAX;     /* 型推測に使用する行数を指定 */
    run;
	data work.csv_data;
    	set work.r_ptdata;
    	array char_vars _all_;  /* すべての変数を対象にする */
    	do over char_vars;
        	char_vars = put(char_vars, $CHAR200.); /* 200文字の文字列としてフォーマット */
    	end;
	run;
	/* SAS データセット */
	data temp;
    	set mylib.&sas_name.;
	run;
	proc export data=temp
    	outfile="&sas_path.\temp.csv" /* 出力先のCSVファイル名 */
    	dbms=csv
    	replace; /* 同名のファイルがあった場合は上書き */
    	putnames=yes; /* 1行目に変数名を含める */
	run;
	proc import datafile="&sas_path.\temp.csv" 
                out=work.sas_&sas_name. 
                dbms=csv 
                replace;
        		getnames=yes;         /* 1行目を列名として使用 */
        		guessingrows=MAX;     /* 型推測に使用する行数を指定 */
    run;

%mend import_csv;

/* 取得したCSVファイルをインポート */
proc sql noprint;
    select filename into :csv_list separated by ', ' /* カンマで区切る */
    from csv_files
    where filename is not null; /* NULLを除外 */
quit;

/* 各CSVファイルをインポート */
%macro import_all_csvs;
    %do i = 1 %to %sysfunc(countw(&csv_list, %str(,))); /* カンマで区切り */
        %let csv_file = %scan(&csv_list, &i, %str(,)); /* カンマ区切りで取得 */
        %import_csv(&csv_file); /* インポートの実行 */
    %end;
%mend import_all_csvs;
%import_all_csvs;
