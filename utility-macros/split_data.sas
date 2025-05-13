/******************************************************************************\
* Name: split_data.sas
*
* Purpose: This macro splits data into a number of datasets with equal observations. If a the number of splits does
*          not evenly divide, some datasets will have one extra observation. This is useful in situations where you
*          need to chunk your dataset up either for sending in batches or otherwise.
*
* Author: Stu Sztukowski
*
* Parameters: data       | Input dataset
*             splits     | Number of even splits to produce
*             out        | Base output dataset name. Will be converted into out1, out2, etc.
*             outoptions | Output dataset options. May need to enclose in bquote.
*
*
* Example: Split up sashelp.cars into 5 datasets and add a dataset option

%split_data(
    data=sashelp.cars, 
    splits=5, 
    out=cars, 
    outoptions=compress=yes
);

\******************************************************************************/

%macro split_data(
    data /*Dataset to split*/
  , splits /*Total number of splits*/
  , out /*Base output dataset name. Split numbers will be appended.*/
  , outoptions= /*Optional. Output dataset options*/
);

    %local dsid n rc outlib outdsn;

    %if(NOT %symexist(data)) %then %do;
        %put ERROR: Must supply a dataset.;
        %abort;
    %end;

    %if(NOT %symexist(splits)) %then %do;
        %put ERROR: Must specify the number of splits;
        %abort;
    %end;

    %if(NOT %symexist(out)) %then %do; 
        %put ERROR: Must specify an output dataset name;
        %abort;
    %end;

    /* Get the library and output dataset name */
    %if(%scan(&out, 2, .) =) %then %do;
        %let outlib = WORK;
        %let outdsn = &out;
    %end;
        %else %do;
            %let outlib = %scan(&out, 1, .);
            %let outdsn = %scan(&out, 2, .);
        %end;

    /* Output dataset name cannot be > 32 characters */
    %if(%length(&outdsn&splits) > 32) %then %do;
        %put ERROR: Output dataset name will be > 32 characters after splitting. Name + number of splits must be <= 32 characters.;
        %abort;
    %end;
            
    /* Get dataset obs */
    %let dsid = %sysfunc(open(&data));
    %let n    = %sysfunc(attrn(&dsid, nlobs));
    %let rc   = %sysfunc(close(&dsid));

    %do s = 1 %to &splits;

        %let firstobs = %sysevalf(&n-(&n/&splits.)*(&splits.-&s+1)+1, floor);
        %let obs      = %sysevalf(&n-(&n/&splits.)*(&splits.-&s.), floor);

        data &outlib..&outdsn&s(%unquote(&outoptions));
            set &data(firstobs=&firstobs obs=&obs);
        run;
    %end;
%mend;