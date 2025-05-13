/******************************************************************************\
* Name: multi_export.sas
*
* Purpose: This macro exports data into a number of datasets with equal observations. If a the number of splits does
*          not evenly divide, some output files will have one extra observation. This is useful in situations where you
*          need to chunk your dataset up either for sending in batches or otherwise.
*
* Author: Stu Sztukowski
*
* Parameters: data       | Input dataset
*             splits     | Number of even splits to produce
*             dir        | Output directory. Do not include ending / or \. Quotes optional 
*             name       | Base output file name. Split numbers will be appended. Quotes optional.
*             ext        | Output file extension. Quotes optional.
*             dbms       | Format to output (dbms option in PROC EXPORT. e.g. csv, xlsx, etc.)
*             replace    | Replace the output file. Default: NO
*             force      | Forces the file to output even if the file directory cannot be verified
*             procstmnt  | Add additional statements to PROC EXPORT. Separate with spaces. Recommended to use %bquote.
*             procbodystmnt | Add statements to the PROC body. Separate with semicolons. Recommended to use %bquote.
*
* Example: Split up sashelp.cars into 5 CSV files and replace it if it already exists

%multi_export(
    data=sashelp.cars, 
    splits=5, 
    dir='C:\Users\stsztu\OneDrive - SAS\Desktop',
    name='cars',
    ext='csv',
    dbms=csv,
    replace=yes
);

* Example: Split up sashelp.cars into 5 pipe-delimited files and replace it if it already exists

%multi_export(
    data=sashelp.cars, 
    splits=5, 
    dir='C:\Users\stsztu\OneDrive - SAS\Desktop',
    name='cars',
    ext='txt',
    dbms=dlm,
    procbodystmnt=%bquote(delimiter='|';)
);

\******************************************************************************/

%macro multi_export(
    data       /*Dataset to output in splits*/
  , splits     /*Total number of splits*/
  , dir        /*Output directory. Do not include ending / or \. Quotes optional.*/
  , name       /*Base output file name. Split numbers will be appended. Quotes optional.*/
  , ext        /*Output file extension. Quotes optional.*/
  , dbms       /*Format to output (dbms option in PROC EXPORT. e.g. csv, xlsx, etc.)*/
  , replace=no /*Replace the output file. Default: NO*/
  , force=no   /*Forces the file to output even if the file directory cannot be verified*/
  , procstmnt= /*Add additional statements to PROC EXPORT. Separate with spaces. Recommended to use %bquote.*/
  , procbodystmnt= /*Add statements to the PROC body. Separate with semicolons. Recommended to use %bquote.*/
);

    %local dsid n rc file filename basefilename ext;

    %if(NOT %symexist(data)) %then %do;
        %put ERROR: Must supply a dataset.;
        %abort;
    %end;

    %if(NOT %symexist(splits)) %then %do;
        %put ERROR: Must specify the number of splits;
        %abort;
    %end;

    %if(NOT %symexist(dir)) %then %do; 
        %put ERROR: Must specify an output directory;
        %abort;
    %end;

    %if(NOT %symexist(name)) %then %do; 
        %put ERROR: Must specify an output file name;
        %abort;
    %end;

    %if(NOT %symexist(ext)) %then %do; 
        %put ERROR: Must specify an output file extension;
        %abort;
    %end;

    %if(NOT %symexist(dbms)) %then %do; 
        %put ERROR: Must specify a file format for PROC EXPORT;
        %abort;
    %end;

    %if(&sysscp = WIN) %then %let _SLSH_ = \;
        %else %let _SLSH_ = /;

    %let dir  = %sysfunc(dequote(&dir));
    %let name = %sysfunc(dequote(&name));
    %let ext  = %sysfunc(dequote(&ext));
    %let dbms = %sysfunc(dequote(&dbms));

    %if(%upcase(&force = NO) AND NOT %sysfunc(fileexist(&dir))) %then %do;
        %put ERROR: &dir could not be found. Check the folder path and try again, or use force=YES to force an attempt to write.;
        %abort;
    %end;

    /* Get dataset obs */
    %let dsid = %sysfunc(open(&data));
    %let n    = %sysfunc(attrn(&dsid, nlobs));
    %let rc   = %sysfunc(close(&dsid));

    %do s = 1 %to &splits;

        %let firstobs = %sysevalf(&n-(&n/&splits.)*(&splits.-&s+1)+1, floor);
        %let obs      = %sysevalf(&n-(&n/&splits.)*(&splits.-&s.), floor);
    
        proc export
            data=&data(firstobs=&obs obs=&obs)
            file="&dir&_SLSH_&name&s..&ext"
            dbms=&dbms
            %if(%upcase(&replace) = YES) %then %do;
            replace
            %end;
            %unquote(&procstmnt)
            ;
            %unquote(&procbodystmnt)
            ;
        run;
    %end;
%mend;
%multi_export(sashelp.cars, 5, "C:\Users\stsztu\OneDrive - SAS\Desktop", foo, csv, dlm, 
    procstmnt=replace, procbodystmnt=%bquote(delimiter='|'));