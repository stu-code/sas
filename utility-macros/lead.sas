/******************************************************************************\
*
* Name: lead.sas
*
* Purpose: Calculates leads for a variable
*
* Parameters: data 		 | Input dataset name
*			  out  		 | Output dataset name
*			  var  		 | Variables to calculate leads separated by spaces
*             rename     | Rename original variable names to a new name specified in order of variables. 
*                          Default: leadn_var1, leadn_var2, etc.
*			  by   		 | Optional by-groups separated by spaces
*			  lead 	  	 | Leads to calculate. 
*                          Default: 1
*			  setmissing | Applies only to by-groups. Sets missing lead values to a specific value by the user. 
*                          Default: MISSING
*
* Dependencies/Assumptions: N/A
*
* Examples: 

*Calculate one lead ahead for one variables
%lead(data=sashelp.air, out=air_lead, var=air);

*Calculate two leads ahead for one variable
%lead(data=sashelp.air, out=air_lead2, var=air, lead=2);

*Calculate one lead ahead for two variables and rename them
%lead(data=sashelp.cars, out=cars_lead, var=horsepower msrp, rename=horsepower_lead msrp_lead);

*Calculate two leads ahead with a by-group
%lead(data=sashelp.bmimen(obs=50), var=bmi, out=bmi_lead, by=age, lead=2);

* History: 15AUG2019 Stu | v0.1 - Initial coding
		   10OCT2019 Stu | v0.2 - Greatly improved performance by converting from
*						   		  PROC EXPAND to a data step. Thank you, Andrew Gannon!
*								  https://www.sas.com/content/dam/SAS/support/en/sas-global-forum-proceedings/2019/3699-2019.pdf
*								  SGF: 3699-2019
*          11MAR2023 Stu | v0.3 - Fixed a bug where by-groups would not calculate correctly for characters.
*                               - Added support for character leads
\******************************************************************************/

%macro lead(data=     /*Input dataset. Supports dataset options.*/
		  , out=      /*Output dataset. Supports dataset options.*/
		  , var=      /*Variables to lead. Space-separated.*/
		  , rename=   /*Optional. New names for variables in order of variables specified in var*/
		  , by=       /*Optional. Add by group processing for leads.*/
		  , lead=1    /*Optional. Set lead amount. Default: 1*/
		  , setmissing=MISSING /*Optional. Set the value of missing leads. Default: MISSING.*/
		   ) / minoperator mindelimiter=' ';

	%local i;
	%let setmissing = %upcase(&setmissing.);

	%let var_count  = %sysfunc(countw(&var,,QS));
    %let last_byvar = %scan(&by., -1, %str( ), Q);

	%let lead_varlist  = ;
	%let lead_varlistc = ;

    /* Separate out lib and dsn and account for options */
    %if(%qscan(%superq(data), 2, ., Q) =) %then %do;
        %let lib = WORK;
        %let dsn = %scan(%qupcase(%superq(data)), 1, %str(%(), Q));
    %end;
        %else %do;
            %let lib = %qupcase(%qscan(%superq(data), 1, ., Q));
            %let dsn = %scan(%qupcase(%qscan(%superq(data), 2, ., Q)), 1, %str(%(), Q);
        %end;

	%if(&rename. NE ) %then %do;
		
		%let n_rename_total = %sysfunc(countw(&rename., %str( ), Q));
		%let n_var = %sysfunc(countw(&var., %str( ), Q));

		%if(&n_rename_total. NE &n_var.) %then
			%put Warning: Total number of output variable names differs from the variables specified.;

		%let n_rename = %sysfunc(min(&n_rename_total., &n_var.));
	%end;
		%else %let n_rename = 0;
    
    /* Convert var list to comma-separated and quoted-comma-separated list */
    %let varlistcq = %unquote(%str(%")%qsysfunc(tranwrd(%qsysfunc(compbl(%upcase(&var))),%str( ),%str(",")))%str(%"));

    /* Identify if each lead var is numeric or character */
    proc sql noprint;
        select type
        into :var_types separated by ' '
        from dictionary.columns
        where     libname = "&lib"
              AND memname = "&dsn"
              AND upcase(name) IN (&varlistcq)
        ;
    quit;

    /* Identify if the byvar is num or char */
    %if(&by. NE) %then %do;
        proc sql noprint;
            select type
            into :byvar_type
            from dictionary.columns
            where     libname = "&lib"
                  AND memname = "&dsn"
                  AND upcase(name) = upcase("&last_byvar")
            ;
        quit;
    %end;

	data &out.;
		set &data.;

		%if(&by. NE) %then %do;
			by &by.;
		%end;
		
		retain _lead_dsid_;

		if(_N_ = 1) then _lead_dsid_ = open("&data.");

	    _lead_rc_ = fetchobs(_lead_dsid_, _N_+&lead.);

		%do i = 1 %to &var_count.;
			%let orig_var = %scan(&var., &i., %str( ), Q);
            %let var_type = %scan(&var_types., &i., %str( ), Q);

			/* If the user specified to rename variables, do so here */
			%if(&rename. NE AND &i. LE &n_rename.) %then %do;
				%let rename_len  = %length(%scan(&rename., &i., %str( ), Q));

				/* Truncate to 32 characters */
				%if(&rename_len. > 32) %then %do;
					%put WARNING: %length(%scan(&rename., &i., %str( ), Q)) has a length > 32 characters and will be truncated.;
					%let rename_len = 32;
				%end;

				/* Renamed lead variable */
				%let lead_var = %substr(%scan(&rename., &i., %str( ), Q), 1, &rename_len.);
			%end;
				%else %do;

					%if(%index(&orig_var., %str(%'))) %then 
						%let orig_varname = %sysfunc(dequote(%qsysfunc(transtrn(&orig_var., %str(%'n), %str()))));
							%else %let orig_varname = %sysfunc(dequote(%qsysfunc(transtrn(&orig_var., %str(%"n), %str()))));

					%let orig_varlen  = %length(&orig_varname.);

					%if(&orig_varlen. > %eval(32-%length(lead&lead._) ) ) %then %let substrlen = %eval(32-%length(lead&lead._));
						%else %let substrlen = &orig_varlen;

					%let lead_var = "lead&lead._%substr(&orig_varname., 1, &substrlen.)"n;

					%let lead_varlist  = &lead_varlist. &lead_var.;

                     /* Create comma-separated list of lead vars */
					 %if(&i. = 1) %then %let lead_varlistc = &lead_var.;
						%else %let lead_varlistc = &lead_varlistc., &lead_var.;
				%end;

            /* Calculate leads for numbers or characters */
            %if(&var_type. = num) %then %do;
			    &lead_var. = getvarn(_lead_dsid_, varnum(_lead_dsid_, "&orig_var."));
            %end;
                %else %do;
			        &lead_var. = getvarc(_lead_dsid_, varnum(_lead_dsid_, "&orig_var."));
                %end;
		%end;

		/* Set last value to missing for by-groups or a user-specific value */
		%if(&by. NE) %then %do;

            /* Check the future value of the by group */
            %if(&byvar_type = num) %then %do;
                _leadby_ = getvarn(_lead_dsid_, varnum(_lead_dsid_, "&last_byvar"));
            %end;
                %else %do;
                    _leadby_ = getvarc(_lead_dsid_, varnum(_lead_dsid_, "&last_byvar"));
                %end;
 
            if(_leadby_ NE &last_byvar.) then do;

				/* Set missing values based on user input */
				%if(%upcase(&setmissing. = MISSING) OR &setmissing. = . OR %cmpres(&setmissing.) IN ('' "")) %then %do;
					call missing(&lead_varlistc.);
				%end;
					%else %do;
						%do i = 1 %to &var_count.;
							%scan(&lead_varlist., &i., %str( ), Q) = &setmissing.;
						%end;
					%end;
			end;

            drop _leadby_;
		%end;

		drop _lead_rc_ _lead_dsid_;
	run;
%mend;