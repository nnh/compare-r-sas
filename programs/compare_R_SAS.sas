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
/* �t�H�[�}�b�g�J�^���O��ݒ� */
options fmtsearch=(mylib);
/* CSV�t�@�C�����擾����f�[�^�Z�b�g���쐬 */
filename mydir "&r_path.";

data csv_files;
    rc = filename('mydir', "&r_path."); /* �f�B���N�g�������w�� */
    did = dopen('mydir'); /* �f�B���N�g�����J�� */

    /* �t�@�C�������݂���ꍇ */
    if did > 0 then do;
        /* �f�B���N�g�����̃t�@�C�������擾 */
        num_files = dnum(did);

        /* �e�t�@�C���̖��O���擾 */
        do i = 1 to num_files;
            filename = dread(did, i); /* �t�@�C�������擾 */
            /* CSV�t�@�C���������t�B���^�����O */
            if scan(filename, -1, '.') = 'csv' then do;
                output; /* �f�[�^�Z�b�g�ɒǉ� */
                file_name = filename; /* �t�@�C�������f�[�^�Z�b�g�Ɋi�[ */
            end;
        end;

        /* �f�B���N�g������� */
        rc = dclose(did);
    end;

    /* �t�H���_�����݂��Ȃ��ꍇ */
    else put "ERROR: Directory does not exist.";
run;

/* CSV�t�@�C�����C���|�[�g����}�N�� */
%macro import_csv(csv_name);
    /* CSV�t�@�C��������f�[�^�Z�b�g�����쐬 */
    %let ds_name = %sysfunc(scan(&csv_name, 1, .));  /* �g���q���������t�@�C���� */
    %if %substr(&ds_name, 1, 2) = r_ %then %do;
    	%let sas_name = %substr(&ds_name, 3); /* 3�����ڈȍ~���擾 */
	%end;
	%else %do;
    	%let sas_name = &ds_name; /* �ύX���Ȃ� */
	%end;

    /* CSV�t�@�C����ǂݍ��� */
    proc import datafile="&r_path\&csv_name" 
                out=&ds_name 
                dbms=csv 
                replace;
        getnames=yes;         /* 1�s�ڂ�񖼂Ƃ��Ďg�p */
        guessingrows=MAX;     /* �^�����Ɏg�p����s�����w�� */
    run;
	data work.csv_data;
    	set work.r_ptdata;
    	array char_vars _all_;  /* ���ׂĂ̕ϐ���Ώۂɂ��� */
    	do over char_vars;
        	char_vars = put(char_vars, $CHAR200.); /* 200�����̕�����Ƃ��ăt�H�[�}�b�g */
    	end;
	run;
	/* SAS �f�[�^�Z�b�g */
	data temp;
    	set mylib.&sas_name.;
	run;
	proc export data=temp
    	outfile="&sas_path.\temp.csv" /* �o�͐��CSV�t�@�C���� */
    	dbms=csv
    	replace; /* �����̃t�@�C�����������ꍇ�͏㏑�� */
    	putnames=yes; /* 1�s�ڂɕϐ������܂߂� */
	run;
	proc import datafile="&sas_path.\temp.csv" 
                out=work.sas_&sas_name. 
                dbms=csv 
                replace;
        		getnames=yes;         /* 1�s�ڂ�񖼂Ƃ��Ďg�p */
        		guessingrows=MAX;     /* �^�����Ɏg�p����s�����w�� */
    run;

%mend import_csv;

/* �擾����CSV�t�@�C�����C���|�[�g */
proc sql noprint;
    select filename into :csv_list separated by ', ' /* �J���}�ŋ�؂� */
    from csv_files
    where filename is not null; /* NULL�����O */
quit;

/* �eCSV�t�@�C�����C���|�[�g */
%macro import_all_csvs;
    %do i = 1 %to %sysfunc(countw(&csv_list, %str(,))); /* �J���}�ŋ�؂� */
        %let csv_file = %scan(&csv_list, &i, %str(,)); /* �J���}��؂�Ŏ擾 */
        %import_csv(&csv_file); /* �C���|�[�g�̎��s */
    %end;
%mend import_all_csvs;
%import_all_csvs;
