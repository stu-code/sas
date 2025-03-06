/******************************************************************************\
* Name: get_folder_uri
*
* Purpose: Returns the URI of a folder in Viya in the log and gives you
*		   a test URL to confirm.
*
* Author: Stu Sztukowski
*		  stu.sztukowski@sas.com
*
* Parameters: path | Full folder path. For example: /foo/bar/baz
*
* Usage: Use this to find the folder URI. For example, when using
*		 the SAS Viya API to output content to a specific folder.
*		 To confirm that the folder is as expected, use the test URL
*		 output in the log.
*
*        
* Example: %get_folder_uri(/Public);
*		   %get_folder_uri(/Products/SAS Visual Analytics);
*
/******************************************************************************/

%macro get_folder_uri(path);
	%let url = %sysfunc(getoption(SERVICESBASEURL));
	%let n_items = %sysfunc(count(&path, /));
	%let uri=;

	%do i = 1 %to &n_items;
		%let name = %scan(&path, &i, /);

		/* Build a folder list as we go along: e.g. /foo/bar/... */
		%if(&i = 1) %then %let pathlist = /&name;
			%else %let pathlist = &pathlist/&name;

		/* For the first endpoint, use rootFolders.
		   Otherwise, get the members of the next folder. */
		%if(&i = 1) %then %let endpoint = rootFolders;
			%else %let endpoint = folders/&uri/members;
	
		filename resp temp;
		
		%put &name: &uri;

		proc http
			url="&url/folders/&endpoint"
			method=GET
			out=resp
			oauth_bearer=sas_services;
			headers "Accept"="application/json";
		run;
		
		libname r json fileref=resp;

		/* Error checking: If the folder does not exist, stop */
		proc sql noprint;
			select *
			from r.items
			where upcase(name) = upcase("&name");
		quit;

		%if(&sqlobs = 0) %then %do;
			%put ERROR: Folder &pathlist was not found. Check that the the folder &path exists or is spelled correctly and try again.;
			%abort;
		%end;

		/* Otherwise, get the URI */
		data _null_;
			set r.items;
			where upcase(name) = upcase("&name");

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
	%put Test URL: &url/folders/&endpoint;
	%put **************************************************;
%mend;