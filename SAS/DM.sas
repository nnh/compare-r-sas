**************************************************************************
Program Name : DM.sas
Study Name : NMC-Cryo2
Author : Kato Kiroku
Date : 2019-03-18
SAS version : 9.4
**************************************************************************;


proc datasets library=work kill nolist; quit;

options mprint mlogic symbolgen minoperator;


*^^^^^^^^^^^^^^^^^^^^Current Working Directories^^^^^^^^^^^^^^^^^^^^;

*Find the current working directory;
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

%inc "&cwd.\program\macro\libname.sas";


proc import datafile="&raw.\è«ó·ìoò^ï[.csv"
                    out=baseline
                    dbms=csv replace;
run;
data baseline_2;
    set baseline;
    if _N_=1 then delete;
run;
proc sort data=baseline_2; by subjid; run;

proc import datafile="&raw.\é°ó√.csv"
                    out=treatment
                    dbms=csv replace;
run;
data treatment_2;
    set treatment;
    if _N_=1 then delete;
    keep subjid treat_date;
run;
proc sort data=treatment_2; by subjid; run;

data baseline_3;
    merge baseline_2(in=a) treatment_2;
    by subjid;
    if a;
    if treat_date='Ç†ÇË';
run;


%macro COUNT (name, var, title, raw);

    proc freq data=&raw noprint;
        tables &var / out=&name;
    run;

    proc sort data=&name; by &var; run;

    data &name._2;
        format Category $12. Count Percent best12.;
        set &name;
        Category=&var;
        if &var=' ' then Category='MISSING';
        percent=round(percent, 0.1);
        drop &var;
    run;

    data &name._2;
        format Item $60. Category $12. Count Percent best12.;
        set &name._2;
        if _N_=1 then do; item="&title"; end;
    run;

    proc summary data=&name._2;
        var count percent;
        output out=&name._total sum=;
    run;

    data &name._total_2;
        format Item $60. Category $12. Count Percent best12.;
        set &name._total;
        item=' ';
        category='çáåv';
        keep Item Category Count Percent;
    run;

    data x_&name;
        format Item $60. Category $12. Count Percent best12.;
        set &name._2 &name._total_2;
    run;

%mend COUNT;


%macro IQR (name, var, title, rdata);

    data &rdata._2;
        set &rdata;
        c=input(&var., best12.);
        if c=-1 then delete;
        keep c;
        rename c=&var.;
    run;

    proc means data=&rdata._2 noprint;
        var &var;
        output out=&name n=n mean=mean std=std median=median q1=q1 q3=q3 min=min max=max;
    run;

    data &name._frame;
        format Item $60. Category $12. Count Percent best12.;
        Item=' ';
        Category=' ';
        count=0;
        percent=0;
        output;
    run;

    proc transpose data=&name out=&name._2;
        var n mean std median q1 q3 min max;
    run;

    data x_&name;
        merge &name._frame &name._2;
        if _N_=1 then Item="&title.";
        Category=upcase(_NAME_);
        count=round(col1, 0.1);
        call missing(percent);
        keep Item Category Count Percent;
    run;

%mend IQR;


*îNóÓ;
    data age_baseline;
        set baseline_3;
        current=(input(ic_date, YYMMDD10.));
        birth=(input(birthday, YYMMDD10.));
        age=intck('YEAR', birth, current);
        if (month(current) < month(birth)) then age=age - 1;
        else if (month(current) = month(birth)) and day(current) < day(birth) then age=age - 1;
    run;
    %IQR (age, age, îNóÓ, age_baseline);

*ê´ï ;
    %COUNT (sex, sex, ê´ï , baseline_3);

*å¥ïa_å¥î≠ê´îxÇ™ÇÒ_ëBä‡;
    %COUNT (disease, disease, å¥ïa_å¥î≠ê´îxÇ™ÇÒ_ëBä‡, baseline_3);

*å¥ïa_å¥î≠ê´îxÇ™ÇÒ_ùGïΩè„îÁÇ™ÇÒ;
    %COUNT (VAR6, VAR6, å¥ïa_å¥î≠ê´îxÇ™ÇÒ_ùGïΩè„îÁÇ™ÇÒ, baseline_3);

*å¥ïa_å¥î≠ê´îxÇ™ÇÒ_è¨ç◊ñEÇ™ÇÒ;
    %COUNT (VAR7, VAR7, å¥ïa_å¥î≠ê´îxÇ™ÇÒ_è¨ç◊ñEÇ™ÇÒ, baseline_3);

*å¥ïa_å¥î≠ê´îxÇ™ÇÒ_ÇªÇÃëº;
    %COUNT (VAR8, VAR8, å¥ïa_å¥î≠ê´îxÇ™ÇÒ_ÇªÇÃëº, baseline_3);

*å¥î≠ê´îxÇ™ÇÒ_ÇªÇÃëºè⁄ç◊;
    data bb_baseline;
        set baseline_3;
        if VAR8='äYìñÇ∑ÇÈ';
        if disease_t1 NE ' ';
    run;
    data x_disease_t1;
        format Item $60. Category $12. Count Percent best12.;
        set bb_baseline;
        if _N_=1 then Item='å¥î≠ê´îxÇ™ÇÒ_ÇªÇÃëºè⁄ç◊';
        Category=disease_t1;
        count=.;
        percent=.;
        keep Item Category Count Percent;
    run;

*å¥ïa_ì]à⁄ê´îxÇ™ÇÒ;
    %COUNT (VAR9, VAR9, å¥ïa_ì]à⁄ê´îxÇ™ÇÒ, baseline_3);

*ì]à⁄ê´îxÇ™ÇÒÇÃå¥î≠ëÉ;
    data cc_baseline;
        set baseline_3;
        if VAR9='äYìñÇ∑ÇÈ';
        if disease_t3 NE ' ';
    run;
    data x_disease_t3;
        format Item $60. Category $12. Count Percent best12.;
        set cc_baseline;
        if _N_=1 then Item='ì]à⁄ê´îxÇ™ÇÒÇÃå¥î≠ëÉ';
        Category=disease_t3;
        count=.;
        percent=.;
        keep Item Category Count Percent;
    run;

*å¥ïa_ÉäÉìÉpéÓ;
    %COUNT (VAR10, VAR10, å¥ïa_ÉäÉìÉpéÓ, baseline_3);

*å¥ïa_ÇªÇÃëºÇÃà´ê´éÓ·á;
    %COUNT (VAR11, VAR11, å¥ïa_ÇªÇÃëºÇÃà´ê´éÓ·á, baseline_3);

*ÇªÇÃëºÇÃà´ê´éÓ·á_ÇªÇÃëºè⁄ç◊;
    data dd_baseline;
        set baseline_3;
        if VAR11='äYìñÇ∑ÇÈ';
        if disease_t2 NE ' ';
    run;
    data x_disease_t2;
        format Item $60. Category $12. Count Percent best12.;
        set dd_baseline;
        if _N_=1 then Item='ÇªÇÃëºÇÃà´ê´éÓ·á_ÇªÇÃëºè⁄ç◊';
        Category=disease_t2;
        count=.;
        percent=.;
        keep Item Category Count Percent;
    run;

*èoåååXå¸;
    %COUNT (bleeding, bleeding, èoåååXå¸, baseline_3);

*èoåååXå¸Ç†ÇËÇÃèÍçá_è⁄ç◊;
    data bleeding_baseline;
        set baseline_3;
        if bleeding='Ç†ÇË';
    run;
    data x_bleeding_t1;
        format Item $60. Category $12. Count Percent best12.;
        set bleeding_baseline;
        Item='èoåååXå¸Ç†ÇËÇÃèÍçá_è⁄ç◊';
        Category=bleeding_t1;
        count=.;
        percent=.;
        keep Item Category Count Percent;
    run;

*çRã√å≈ñÚÇÃìäó^;
    %COUNT (anticoagulation, anticoagulation, çRã√å≈ñÚÇÃìäó^, baseline_3);

*PS;
    %COUNT (PS, PS, PS (ECOG), baseline_3);

*ãÿíoä…ñÚégóp;
    %COUNT (muscle_relax, muscle_relax, ãÿíoä…ñÚégóp, baseline_3);

*é_ëfìäó^;
    %COUNT (oxygen, oxygen, é_ëfìäó^, baseline_3);

*èoåååXå¸Ç†ÇËÇÃèÍçá_è⁄ç◊;
    data oxy_baseline;
        set baseline_3;
        if oxygen='Ç†ÇË';
    run;
    %IQR (oxygen_L, oxygen_L, é_ëfìäó^Ç†ÇËÇÃèÍçá_é_ëfìäó^ó _L_ï™, oxy_baseline);

*SpO2;
    %IQR (Sp02, Sp02, SpO2, baseline_3);



data DM;
    set x_age x_sex x_disease x_VAR6 x_var7 x_var8 x_disease_t1 x_var9 x_disease_t3 x_var10 x_var11 x_disease_t2
    x_bleeding x_bleeding_t1 x_anticoagulation x_PS x_muscle_relax x_oxygen x_oxygen_L x_Sp02;
run;

%ds2csv (data=DM, runmode=b, csvfile=&out.\SAS\DM.csv, labels=N);
