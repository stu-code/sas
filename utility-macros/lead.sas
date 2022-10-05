/******************************************************************************\
* $Id: lead.sas 4903 2019-10-10 21:05:47Z stsztu $
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

*Calculate one lead ahead with a by-group
%lead(data=sashelp.bmimen(obs=50), var=bmi, out=bmi_lead, by=age);

* History: 15AUG2019 Stu | v0.1 - Initial coding
		   10OCT2019 Stu | v0.2 - Greatly improved performance by converting from
*						   		  PROC EXPAND to a data step. Thank you, Andrew Gannon!
*								  https://www.sas.com/content/dam/SAS/support/en/sas-global-forum-proceedings/2019/3699-2019.pdf
*								  SGF: 3699-2019
\******************************************************************************/

%macro lead(data=
		  , out=
		  , var=
		  , rename=
		  , by=
		  , lead=1
		  , setmissing=MISSING
		   );

	%local i;
	%let setmissing = %upcase(&setmissing.);

	%let var_count = %sysfunc(countw(&var,,QS));;
	%let lead_varlist = ;
	%let lead_varlistc = ;

	%if(&rename. NE ) %then %do;
		
		%let n_rename_total = %sysfunc(countw(&rename., %str( ), Q));
		%let n_var	  = %sysfunc(countw(&var., %str( ), Q));

		%if(&n_rename_total. NE &n_var.) %then
			%put Warning: Total number of output variable names differs from the variables specified.;

		%let n_rename = %sysfunc(min(&n_rename_total., &n_var.));
	%end;
		%else %let n_rename = 0;

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

					%let lead_varlist = &lead_varlist. &lead_var.;

					/* Create comma-separated list of lead vars */
					%if(&i. = 1) %then %let lead_varlistc = &lead_var.;
						%else %let lead_varlistc = &lead_varlistc., &lead_var.;
				%end;

			&lead_var. = getvarn(_lead_dsid_, varnum(_lead_dsid_, "&orig_var."));

		%end;

		/* Set last value to missing for by-groups or a user-specific value */
		%if(&by. NE) %then %do;

			if(last.%scan(&by., -1, %str( ), Q) ) then do;

				/* Set missing values based on user input */
				%if(%upcase(&setmissing. = MISSING) OR &setmissing. = .) %then %do;
					call missing(&lead_varlistc.);
				%end;
					%else %do;
						%do i = 1 %to &var_count.;
							%scan(&lead_varlist., &i., %str( ), Q) = &setmissing.;
						%end;
					%end;
			end;
		%end;

		drop _lead_rc_ _lead_dsid_;
	run;
%mend;
