**************************************************************************
Program Name : execPtosh-format.sas
Purpose : 
Author : Mariko Ohtsuka
Date : 2024-9-27
SAS version : 9.4
**************************************************************************;
/* ptosh-format\ptosh-format\program
   にこのプログラムをコピーして実行してください */
%let parent_dir=C:\Users\MarikoOhtsuka\Documents\GitHub\ptosh-format;
%let target_dir=&parent_dir.\input;
%let ptosh_format_dir=&parent_dir.\ptosh-format;
%let input_dir=C:\Users\MarikoOhtsuka\Box\Datacenter\Users\ohtsuka\ptosh_format_test\;
%macro process_files(trial_name);
    systask command "rmdir /S /Q &target_dir." taskname=rmdir_task cleanup;
    x "xcopy &input_dir.&trial_name.\input &target_dir. /E /I /Y";
    %inc "&ptosh_format_dir.\program\ptosh-format.sas" / SOURCE2;
	%let ads_path=&ptosh_format_dir.\sas_ads_&trial_name.;
    systask command "rmdir /S /Q &ads_path." taskname=rmdir_task cleanup;
    systask command "move &ptosh_format_dir.\ads &ads_path." taskname=move_ads cleanup;
    systask command "move &ptosh_format_dir.\log\ptosh-format.log &ptosh_format_dir.\log\sas_&trial_name..log" taskname=move_log cleanup;
	%let sas_path=&ads_path.; 
    %inc "C:\Users\MarikoOhtsuka\Documents\GitHub\compare-r-sas\programs\compare_R_SAS.sas" / SOURCE2;
%mend process_files;
%process_files(CJLSG1901);
%process_files(CJLSG1902);
%process_files(NHON-Tranilast-MD);
%process_files(Oshimertinib-NSCLC);
%process_files(Riociguat-CTEPH);
%process_files(TNH-Azma);


/* move_logタスクを強制終了 */
*systask kill taskname=move_log;
