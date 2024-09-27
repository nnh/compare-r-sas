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
/* �t�H�[�}�b�g�J�^���O��ݒ� */
options fmtsearch=(mylib);
/* �g�p���郉�C�u�������w�� */
%let libname = mylib; /* ���C�u��������ݒ� */
%let dataset_list=%str(PTDATA);
%macro create_csv_folder();
    /* �t�H���_�����݂��邩���m�F */
    %if %sysfunc(fileexist(&sas_path.\csv)) = 0 %then %do;
        /* �t�H���_�����݂��Ȃ��ꍇ�͍쐬 */
        systask command "mkdir &sas_path.\csv" shell;
    %end;
%mend create_csv_folder;
/* �}�N���ϐ� dataset_list �̓��e���J���}�ŋ�؂��ď�������}�N�� */
%macro export_all_csvs();
	%create_csv_folder;
	%DO i = 1 %TO %sysfunc(countw(&dataset_list.));
		%let ds = %scan(&dataset_list., &i, %str(,));
		data temp;
    		set mylib.&ds.;
		run;
		proc export data=temp
    		outfile="&sas_path.\csv\sas_&ds..csv" /* �o�͐��CSV�t�@�C���� */
    		dbms=csv
    		replace; /* �����̃t�@�C�����������ꍇ�͏㏑�� */
    		putnames=yes; /* 1�s�ڂɕϐ������܂߂� */
		run;
	%END;
%mend export_all_csvs;
%export_all_csvs;
