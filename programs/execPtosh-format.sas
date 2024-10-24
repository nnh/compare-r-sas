**************************************************************************
Program Name : execPtosh-format.sas
Purpose : 
Author : Mariko Ohtsuka
Date : 2024-10-23
SAS version : 9.4
**************************************************************************;
/* ptosh-format\ptosh-format\program
   にこのプログラムをコピーして実行してください */
%macro process_files(trial_name);
	%let parent_dir=C:\Users\MarikoOhtsuka\Documents\GitHub\ptosh-format;
	%let target_dir=&parent_dir.\input;
	%let ptosh_format_dir=&parent_dir.\ptosh-format;
	%let input_dir=C:\Users\MarikoOhtsuka\Box\Datacenter\Users\ohtsuka\ptosh_format_test\;
    systask command "rmdir /S /Q &target_dir." taskname=rmdir_task cleanup;
    x "xcopy &input_dir.&trial_name.\input &target_dir. /E /I /Y";
	sleep(10, 1);
    %inc "&ptosh_format_dir.\program\ptosh-format.sas" / SOURCE2;
	%let ads_path=&ptosh_format_dir.\sas_ads_&trial_name.;
    systask command "rmdir /S /Q &ads_path." taskname=rmdir_task cleanup;
    systask command "move &ptosh_format_dir.\ads &ads_path." taskname=move_ads cleanup;
    systask command "move &ptosh_format_dir.\log\ptosh-format.log &ptosh_format_dir.\log\sas_&trial_name..log" taskname=move_log cleanup;
	%let sas_path=&ads_path.; 
    %inc "C:\Users\MarikoOhtsuka\Documents\GitHub\compare-r-sas\programs\compare_R_SAS.sas" / SOURCE2;
%mend process_files;
/* issue7 異常系 abortするので別個で実行する
%process_files(issue7_1);
%process_files(issue7_2);
%process_files(issue7_3);
%process_files(issue7_4);
%process_files(issue7_5);
*/
%process_files(issue21);
%process_files(issue7_6);
%process_files(issue7_7);
%process_files(issue7_8);
%process_files(issue7_9);
%process_files(CAPITAL);
%process_files(CJLSG1901);
%process_files(CJLSG1902);
%process_files(FCDS-01);
%process_files(JACLS-SN17);
%process_files(J-CRITICAL);
%process_files(JFGE-Asthma2);
%process_files(JSH-MM-15);
%process_files(Lymphoma-CSeq);
*%process_files(NHON-Tranilast-MD);
%process_files(Oshimertinib-NSCLC);
%process_files(Riociguat-CTEPH);
%process_files(TNH-Azma);
%process_files(NMC-RocStent);
%process_files(NHOC-PCPS);
%process_files(JALSG-CS-17-CSeq_knonc);
%process_files(JALSG-CS-17-CSeq);
%process_files(JPLSG-CSeq-17);
%process_files(JPLSG-B-NHL-14);
%process_files(JPLSG-ALL-T11);
%process_files(JPLSG-ALL-R14);
%process_files(JPLSG-ALL-Ph13);
%process_files(JPLSG-ALL-B12);
*%process_files(JRESG-RESR-2023);
*%process_files(JRESG-RES-FCD);
%process_files(JSH-MPN-R18);
%process_files(NHOC-PH);
%process_files(NHOD-SBC);
%process_files(NHOG-eCT-DivBleed);
%process_files(NHOG-MDZ-GFCF);
%process_files(NHOH-EDL-GDP);
%process_files(NHOH-MARBLE);
%process_files(NHOH-NHOMM);
%process_files(NHOH-R-miniCHP);
%process_files(NHOR-iREC-MAC);

/* move_logタスクを強制終了 */
*systask kill taskname=move_log;
