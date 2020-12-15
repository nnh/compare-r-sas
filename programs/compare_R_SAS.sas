**************************************************************************
Program Name : compare_R_SAS.sas
Purpose : 
Author : Kato Kiroku, Mariko Ohtsuka
Date : 2020-12-15
SAS version : 9.4
**************************************************************************;


proc datasets library=work kill nolist; quit;
options mprint mlogic symbolgen xsync noxwait;
options cmplib=work.funcdt;
*^^^^^^^^^^Filename check^^^^^^^^^^;

proc fcmp outlib=work.funcdt.filecheck;
    *If "filename" ends with "excluded_str", it returns 0. Otherwise, it returns 1.;
    function CHECK_FILE_NON_TARGET(filename $, excluded_str $);
        excluded_len = length(compress(excluded_str));
        target_len = length(compress(filename));
        check_start = target_len - excluded_len + 1;
        if check_start ne 0 then do;
          check_str = substr(filename, check_start, excluded_len);
        end;
        else do;
          check_str = filename;
        end;
        if check_str = excluded_str then do;
          res = 0;  
        end; 
        else do;
          res = 1;
        end;
        return (res);
    endsub;
run;

*^^^^^^^^^^Find the Current Working Directory^^^^^^^^^^;

%macro FIND_WD;

    %local _fullpath _path;
    %let _fullpath=;
    %let _path=;

    %if %length(%sysfunc(getoption(sysin)))=0 %then
      %let _fullpath=%sysget(sas_execfilepath);
    %else
      %let _fullpath=%sysfunc(getoption(sysin));

    %let _path=%substr(&_fullpath., 1, %length(&_fullpath.)
                       -%length(%scan(&_fullpath., -1, '\'))
                       -%length(%scan(&_fullpath., -2, '\')) -2);

    &_path.

%mend FIND_WD;
%let cwd=%FIND_WD;
%put &cwd.;

%let PATH2PRG=&cwd.\programs;
%let PATH2R=&cwd.\input\R;
%let PATH2SAS=&cwd.\input\SAS;

%let create_temp_dir=%sysfunc(dcreate(temp, &cwd.));
%let temp=&cwd.\temp;
%let create_out_dir=%sysfunc(dcreate(output, &cwd.));
%let out=&cwd.\output;
*^^^^^^^^^^Dataset for CSV filename list^^^^^^^^^^;

data ds_filename;
    attrib filename length=$100.;
    stop;
run;
*^^^^^^^^^^Removes the line feed code in a cell(for sae_report(R))^^^^^^^^^^;

data _NULL_;
    shell = 'C:\Windows\SysWOW64\cscript.exe';
    script = %unquote(%bquote('"&PATH2PRG.\replaceCrlf.vbs"'));
    args = %unquote(%bquote('"&PATH2R."'));
    call system(catx(' ', shell, script, args));
run;

*^^^^^^^^^^Import All Raw Data within the "RAW" Directory^^^^^^^^^^;

%macro READ_CSV (dir, ext, out);

    %global cnt memcnt i;
    %local filrf rc did name;
    %let cnt=0;

    %let filrf=mydir;
    %let rc=%sysfunc(filename(filrf, &dir.));
    %let did=%sysfunc(dopen(&filrf));
    *If the directory exists, the process continues;
    %if &did ne 0 %then %do;
      *Counting the number of files in a directory;
      %let memcnt=%sysfunc(dnum(&did));

      %do i=1 %to &memcnt;
        *Get the file extension;
        %let name=%qscan(%qsysfunc(dread(&did, &i)), -1, .);
        *Process only "*.csv".;
        %if %qupcase(%qsysfunc(dread(&did, &i))) ne %qupcase(&name) %then %do;
          %if %superq(ext) = %superq(name) %then %do;
            %let cnt=%eval(&cnt+1);
            %put %qsysfunc(dread(&did, &i));
            *Get the name of the file. e.g."test.csv";
            %let csvfile_&cnt=%qsysfunc(dread(&did, &i));
            data &out._filename_&i;
                length title $60;
                title=compress(tranwrd("&&csvfile_&cnt", '.csv', '*'), '*'); output;
                call symputx("csvname_&cnt", title, "G");
            run;
            %put &&csvname_&cnt;
            *Do not import files without observations;
            proc import datafile="&dir.\%qsysfunc(dread(&did, &i))"
                out=obsCountCheck
                dbms=csv replace;
                getnames=NO;
            run;
            proc sql noprint;
              select count(*) into : obsCount trimmed
              from obsCountCheck;
            quit;
            %if &obsCount.>1 %then %do;
              *Import a csv file;
              proc import datafile="&dir.\%qsysfunc(dread(&did, &i))"
                 out=&out._&&csvname_&cnt
                 dbms=csv replace;
                 guessingrows=MAX;
              run;
              *List of imported files; 
              proc sql noprint;
                insert into ds_filename set filename="&&csvname_&cnt.";
              quit;
            %end;
          %end;
        %end;
      %end;
    %end;
    %else %put &dir. cannot be open.;
    %let rc=%sysfunc(dclose(&did));

%mend READ_CSV;

%READ_CSV (&PATH2R., csv, r);
%READ_CSV (&PATH2SAS., csv, sas);

*^^^^^^^^^^Removing duplicate filenames^^^^^^^^^^;

proc sort data=ds_filename out=ds_filename nodupkey; 
    by filename; 
run;

*^^^^^^^^^^Exclude files not to be compared^^^^^^^^^^;
data ds_targetfile;
    set ds_filename;
    array str{3} $30 e1 e2 e3;
    str{1}='output_option_csv';
    str{2}='output_sheet_csv';
    str{3}='_contents';
    res=1;
    do i= 1 to 3;
      res=CHECK_FILE_NON_TARGET(filename, str{i});
      if res=0 then leave;
    end;
    if res ne 0 then output;
run;

data _NULL_;
    set ds_targetfile;
    call symput('cnt', _N_);
run;

%macro COMPARE;
    %do i= 1 %to &cnt.;
      data _NULL_;
          set ds_targetfile;
          if _N_=&i. then do;
            call symput('targetfile', filename);
          end;
      run;
      *Delete the variable "Var_Obs" if it exists.;
      data sas_comp;
          set sas_&targetfile.;
          if vnamex("Var_Obs") ne '' then do;
            drop Var_obs;
          end;
      run;
      *num => char;
      proc printto print="&out.\Result_%sysfunc(strip(&targetfile.)).txt" new; run;
          proc compare base=r_&targetfile. compare=sas_comp out=Result_&targetfile.; run;
      proc printto; run;
    %end; 
%mend COMPARE;
%COMPARE;
