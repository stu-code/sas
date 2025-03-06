/******************************************************************************\
* Name: get_folder_uri
*
* Purpose: Returns the URI of a folder in Viya in the log and gives you
*          a test URL to confirm.
*
* Author: Stu Sztukowski
*
* Parameters: path | Full folder path. For example: /foo/bar/baz
*					 IF USING WILDCARDS:
*					 Specify only the wildcard with an @ and no preceding /
*					 For example, to get the URI for My Folder, use @myFolder
*
* Usage: Use this to find the folder URI in Viya. For example, when using
*        the SAS Viya API to output content to a specific folder.
*        To confirm that the folder is as expected, use the test URL
*        output in the log.
*
*        
* Example: %get_folder_uri(/Public);
*          %get_folder_uri(/Products/SAS Visual Analytics);
*		   %get_folder_uri(@myFolder)
*
/******************************************************************************/

%macro get_folder_uri(path);
    %let url = %sysfunc(getoption(SERVICESBASEURL));
    %let uri=;

	%let path = %superq(path);

	/* Detect wildcard */
    %if(%qsubstr(&path,1,1) = @) %then %let wildcard = 1;
        %else %let wildcard = 0;

	/* If there is no wildcard, calculate the number of folders and
	   read from r.items. Otherwise, set it to 1 and read from r.root since
	   r.items doesn't exist when using a wildcard */
	%if(NOT &wildcard) %then %do;
		%let n_folders = %sysfunc(count(&path, /));
		%let readfrom  = r.items;
	%end;
		%else %do;
			%let n_folders = 1;
			%let readfrom  = r.root;
		%end;

    %do i = 1 %to &n_folders;
        %let name = %scan(&path, &i, /);

        /* Build a folder list as we go along: e.g. /foo/bar/... 
		   Except for wildcards */
        %if(&i = 1 AND NOT &wildcard) %then %let pathlist = /&name;
            %else %if(NOT &wildcard) %then %let pathlist = &pathlist/&name;
				%else %let pathlist = &name;

        /* 1. First iteration and not a wildcard: Must use rootFolders
		   2. If first iteration and a wildcard; Must go directly to the folder (e.g./folders/folders/@myFolder) 
		   3. Otherwise, get the members from the URI */
        %if(&i = 1 AND NOT &wildcard) %then %let endpoint = rootFolders; 
            %else %if(&i = 1 AND &wildcard) %then %let endpoint = folders/&path; 
                %else %let endpoint = folders/&uri/members;

        filename resp temp;

        proc http
            url="&url/folders/&endpoint?filter=eq(name, '&name')"
            method=GET
            out=resp
            oauth_bearer=sas_services;
            headers "Accept"="application/json";
        run;
        
        %if(&SYS_PROCHTTP_STATUS_CODE NE 200) %then %do;
            %put ERROR: Did not receive a 200 OK status code from the server. The status code is: &SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE..;
            %put Test URL: &url/folders/&endpoint;
            %abort;
        %end;

        libname r json fileref=resp;

        /* Error checking: If the folder does not exist, stop */
        proc sql noprint;
            select *
            from &readfrom

			/* Doesn't work with r.items */
			%if(NOT &wildcard) %then %do;
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

			/* Doesn't work with r.items */
			%if(NOT &wildcard) %then %do;
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

            call symputx('uri', folder_uri);
        run;
    %end;

    %put **************************************************;
    %put URI for &pathlist: &uri;
    %put Test URL: &url/folders/folders/&uri;
    %put **************************************************;
%mend;