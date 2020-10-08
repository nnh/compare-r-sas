**************************************************************************
Program Name : compare_R_SAS.sas
Purpose : 
Author : Kato Kiroku
Date : 2019-03-29
SAS version : 9.4
**************************************************************************;


proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen;


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
                       -%length(%scan(&_fullpath., -2, '\'))
                       -%length(%scan(&_fullpath., -3, '\')) -3);

    &_path.

%mend FIND_WD;

%let cwd=%FIND_WD;
%put &cwd.;

%let PATH2R=&cwd.\R_output\output;
%let PATH2SAS=&cwd.\SAS_output\output;

%let temp=&cwd.\compare\pgm\temp;
%let out=&cwd.\compare\output;

*^^^^^^^^^^Import All Raw Data within the "RAW" Directory^^^^^^^^^^;

%macro READ_CSV (dir, ext, out);

    %global cnt memcnt i;
    %local filrf rc did name;
    %let cnt=0;

    %let filrf=mydir;
    %let rc=%sysfunc(filename(filrf, &dir.));
    %let did=%sysfunc(dopen(&filrf));
    %if &did ne 0 %then %do;
      %let memcnt=%sysfunc(dnum(&did));

      %do i=1 %to &memcnt;
 
        %let name=%qscan(%qsysfunc(dread(&did, &i)), -1, .);

        %if %qupcase(%qsysfunc(dread(&did, &i))) ne %qupcase(&name) %then %do;
          %if %superq(ext) = %superq(name) %then %do;
            %let cnt=%eval(&cnt+1);
            %put %qsysfunc(dread(&did, &i));

            %let csvfile_&cnt=%qsysfunc(dread(&did, &i));
            data &out._filename_&i;
                length title $60;
                title=compress(tranwrd("&&csvfile_&cnt", '.csv', '*'), '*'); output;
                call symputx("csvname_&cnt", title, "G");
            run;
            %put &&csvname_&cnt;

              *Find and remove carriage returns or line breaks in (rawdata).csv;
/*              data _NULL_;*/
/*                  infile "&dir.\%qsysfunc(dread(&did, &i))" recfm=n;*/
/*                  file "&tmp.\t&cnt..csv" recfm=n;*/
/*                    retain Flag 0;*/
/*                    input a $char1.;*/
/*                    if a='"' then */
/*                      if Flag=0 then Flag=1;*/
/*                                       else Flag=0;*/
/*                    if Flag=1 then do;*/
/*                      if a='0D'x then do;*/
/*                        goto EXIT;*/
/*                      end;*/
/*                      if a='0A'x then do;*/
/*                        goto EXIT;*/
/*                      end;*/
/*                    end;*/
/*                    if a='"' then do;*/
/*                      goto EXIT;*/
/*                    end;*/
/*                    put a $char1.;*/
/*                  EXIT:*/
/*              run;*/

              proc import datafile="&dir.\%qsysfunc(dread(&did, &i))"
                  out=temp_&out._&&csvname_&cnt
                  dbms=csv replace;
                  guessingrows=32767;
              run;

              %ds2csv (data=temp_&out._&&csvname_&cnt, runmode=b, csvfile=&temp.\&out._&&csvname_&cnt...csv, labels=N);

              proc import datafile="&temp.\&out._&&csvname_&cnt...csv"
                  out=&out._&&csvname_&cnt
                  dbms=csv replace;
                  guessingrows=32767;
              run;

          %end;
        %end;

      %end;

    %end;
    %else %put &dir. cannot be open.;
    %let rc=%sysfunc(dclose(&did));

%mend READ_CSV;

%macro COMPARE;

    %do cnt=1 %to &cnt;
      proc printto print="&out.\Result_&&csvname_&cnt...txt" new; run;
          proc compare base=r_&&csvname_&cnt compare=sas_&&csvname_&cnt out=Result_&&csvname_&cnt; run;
      proc printto; run;
    %end;

%mend COMPARE;


%READ_CSV (&PATH2R., csv, r);
%READ_CSV (&PATH2SAS., csv, sas);
%COMPARE;

