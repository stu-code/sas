/******************************************************************************\
* Name: get_folder_uri
*
* Purpose: Returns the URI of a folder in Viya in the log or a macro variable
*          and optionally gives you a test URL to confirm.
*
* Author: Stu Sztukowski
*
* Parameters: path | Full folder path. For example: /foo/bar/baz
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
*             debug     | If Yes, outputs URL test information to the log and
*                         does not clear the JSON libname.
*                         Default: No
* Usage: Use this to find the folder URI in Viya. For example, when using
*        the SAS Viya API to output content to a specific folder.
*        To confirm that the folder is as expected, use the test URL
*        output in the log.
*
*        
* Example: %get_folder_uri(/Public); %put URI: &uri;
*          %get_folder_uri(/Products/SAS Visual Analytics); %put URI: &uri;
*          %get_folder_uri(@myFolder, debug=yes); %put URI: &uri;
*
/******************************************************************************/
%macro get_folder_uri(path, outmacvar=uri, debug=no);
    %local  url _uri_ folder_uri wildcard n_folders readfrom name endpoint i t;
    %global &outmacvar;

    %let debug = %upcase(&debug);
    %let t     = %substr(%sysfunc(datetime()), 1, 7); /* Used for filename/libname randomization */

    %let url  = %sysfunc(getoption(SERVICESBASEURL));
    %let path = %qsysfunc(dequote(%superq(path)));

    /* Detect wildcard */
    %if(%qsubstr(&path,1,1) = @) %then %let wildcard = 1;
        %else %let wildcard = 0;

    /* If there is no wildcard, read from r.items. 
       Otherwise, read from r.root since r.items doesn't 
       exist when using a wildcard */
    %let n_folders = %sysfunc(countw(&path, /@));

    %do i = 1 %to &n_folders;
        %let name = %scan(&path, &i, /@);

        /* If you read from multiple folders or just one folder, 
           read from items. Otherwise, read from root. */
        %if(NOT &wildcard OR (&wildcard AND &i > 1))
            %then %let readfrom = j&t..items;
        %else %let readfrom  = j&t..root;

        /* Build a folder list as we go along: e.g. 
          /foo/bar/... 
          @/foo/bar... */
           
        %if(&wildcard AND &i = 1) %then %let pathlist = @&name;
            %else %if(&i = 1) %then %let pathlist = /&name;
                %else %let pathlist = &pathlist/&name;

    /* 1. First iteration and not a wildcard: Must use rootFolders
       2. If first iteration and a wildcard; Must go directly to the folder (e.g./folders/folders/@myFolder) 
       3. Otherwise, get the members from the URI */
        %if(&i = 1 AND NOT &wildcard) %then %let endpoint = rootFolders; 
            %else %if(&i = 1 AND &wildcard) %then %let endpoint = folders/@&name; 
                %else %let endpoint = folders/&_uri_/members;

        %let resp = r&t;

        filename &resp temp;

        proc http
            url="&url/folders/&endpoint?filter=eq(name, '&name')"
            method=GET
            out=&resp
            oauth_bearer=sas_services;
            headers "Accept"="application/json";
        run;
        
        %if(&SYS_PROCHTTP_STATUS_CODE NE 200) %then %do;
            %put ERROR: Did not receive a 200 OK status code from the server. The status code is: &SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE..;
            %put Test URL: &url/folders/&endpoint;
            %abort;
        %end;

        libname j&t json fileref=&resp;
        filename &resp clear;

        /* Error checking: If the folder does not exist, stop */
        proc sql noprint;
            select *
            from &readfrom

            /* Doesn't work with j.root */
            %if(NOT &wildcard OR (&wildcard AND &i > 1)) %then %do;
                where upcase(name) = upcase("&name") 
            %end;
            ;
        quit;

        %if(&sqlobs = 0) %then %do;
            %put ERROR: Folder &pathlist was not found. Check that the the folder &path exists,  is spelled correctly, or has correct casing and try again.;
            %abort;
        %end;

        /* Otherwise, get the URI */
        data _null_;
            set &readfrom;

            /* Doesn't work with j.root */
            %if(NOT &wildcard OR (&wildcard AND &i > 1)) %then %do;
                where upcase(name) = upcase("&name"); 
            %end;

            /* For the first URI, you must use the ID variable */
            %if(&i = 1) %then %do;
                folder_uri = id;
            %end;

            /* Otherwise, you must get it from the URI variable */
            %else %do;
                folder_uri = scan(uri, -1, '/');
            %end;

            call symputx("_uri_", folder_uri);
        run;
    %end;

    %let &outmacvar = &_uri_;

    %if(&debug = YES) %then %do;

        %put **************************************************;
        %put URI for &pathlist: &&&outmacvar;
        %put Test URL: &url/folders/folders/&&&outmacvar;
        %put **************************************************;
    %end;
        %else %do;
            libname j&t clear;
        %end;
%mend;