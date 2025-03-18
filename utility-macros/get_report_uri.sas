/******************************************************************************\
* Name: get_report_uri
*
* Purpose: Returns the URI of a Visual Analytics report in Viya in the log and a macro variable
*          and optionally gives you a test URL to confirm.
*
* Author: Stu Sztukowski
*
* Parameters: path | Full path to the Visual Analytics report. For example: /foo/bar/baz
*                    where the report's name is "baz"
*             IF USING WILDCARDS:
*             Specify only the wildcard with an @ and no preceding /
*             For example, to get the URI for My Folder, use @myFolder
*             
*             Common wildcards:
*             @myFolder      | Your home folder
*             @myHistory     | History of files you've looked at
*             @myFavorites   | Your favorites
*             @appDataFolder | Your application data folder
*             @myRecycleBin  | Your recycle bin when you delete things
*             @public        | The Public folder
*             @products      | The Products folder
*
*             For a list of all wildcards on your system,
*             go to the /folders?limit=100 endpoint.
*           
*             outmacvar | The output macro variable for the URI. 
*                         Default: uri
*             debug     | If Yes, outputs URL test information to the log and does
*                         not clear the JSON libname.
*                         Default: No
*
* Dependencies: Requires the %get_folder_uri macro:
*               https://github.com/stu-code/sas/blob/master/utility-macros/get_folder_uri.sas
(
* Usage: Use this to find the report URI in Viya. For example, when using
*        the SAS Viya API to work with a Visual Analytics report.
*  
* Example: %get_report_uri(/Products/SAS Visual Analytics/Samples/Retail Insights); %put URI: &uri;
*           
/******************************************************************************/

%macro get_report_uri(path, outmacvar=report_uri, debug=no);

    %local url path report folder_path wildcard n_folders i t;
    %global &outmacvar;

    %let path = %qsysfunc(dequote(%superq(path)));

    %let debug = %upcase(&debug);
    %let t     = %substr(%sysfunc(datetime()), 1, 7); /* Used for filename/libname randomization */

    %let url  = %sysfunc(getoption(SERVICESBASEURL));
    %let resp = r&t;

    %let report_name = %qscan(&path, -1, /);
    %let folder_path = %qsubstr(&path, 1, %eval(%length(&path)-%length(&report_name)-1));

    /* Get the URI of the folder the report is in */
    %get_folder_uri(&folder_path, outmacvar=_folder_uri_, debug=&debug);

    filename &resp temp;
       
    /* Get the members of the folder with this name and type is report*/
    proc http
        url="&url/folders/folders/&_folder_uri_/members?filter=and(eq(name, '&report_name'), eq(contentType, 'report'))"
        method=GET
        out=&resp
        oauth_bearer=sas_services;
        headers "Accept"="application/json";
    run;
       
    %if(&SYS_PROCHTTP_STATUS_CODE NE 200) %then %do;
        %put ERROR: Did not receive a 200 OK status code from the server. The status code is: &SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE..;
        %put Test URL: &url/folders/folders/&_folder_uri_/members?filter=and(eq(name, %tslit(&report_name)), eq(contenttype, 'report'));
        %abort;
    %end;

    libname j&t json fileref=&resp;
    filename &resp clear;

    /* Error checking: If the folder does not exist, stop */
    proc sql noprint;
        select *
        from j&t..items
        where upcase(name) = upcase("&report_name")
        ;
    quit;

    %if(&sqlobs = 0) %then %do;
        %put ERROR: Report &path was not found. Check that the the report &report_name exists, has the correct path, and is spelled correctly, then try again.;
        %put Test URL: &url/folders/folders/&_folder_uri_/members;
        libname j&t clear;
        %abort;
    %end;

    data _null_;
        set j&t..items;
        where name = "&report_name"; 
        call symputx("&outmacvar", scan(uri, -1, '/'));
    run;

    %if(&debug = YES) %then %do;
        %put **************************************************;
        %put URI for &report_name: &&&outmacvar;
        %put Test URL: &url/reports/reports/&&&outmacvar;
        %put **************************************************;
    %end;
        %else %do;
            libname j&t clear;
        %end;
%mend;

%get_report_uri(@public/Reports/SAS Data Advisor);