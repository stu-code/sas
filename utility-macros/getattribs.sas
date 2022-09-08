/******************************************************************************\
* Name: getattribs.sas
*
* Purpose: Gets variable attributes from a dataset and stores the data step & ds2 attrib code into a single macro variable.
*
*
* Author: Stu Sztukowski
*		  stu.sztukowski@sas.com
*
* Parameters: data	    | dataset to get attribs from
*			  outmacvar | Macro variable to save attrib statements. Default: &attribs
*			  drop	    | Variables to drop when getting attribs
*			  keep	    | Variables to keep when getting attribs
*			  type	    | When DS2, changes the attrib statements to be compatible with ds2
*			  format    | When NO, suppresses formats in the attrib statements
*			  informat  | When NO, suppresses informats in the attrib statements
*			  label  	| When NO, suppresses labels in the attrib statements
*
*
* Usage: Use when variable attributes need to be obtained from a dataset and saved into a data step/ds2 step.
*		 This is helpful for maintaining variable length and order, or for bringing in variables for a hash table.
*
* Example:

(1) Get variable attributes from sashelp.air for a data step;

%getattribs(data=sashelp.iris);

%put %bquote(&attribs.);

 data iris;
	&attribs.;
	set sashelp.iris;
 run;

(2) Get variable attributes from sashelp.air for a ds2 step;

*DS2 does not like concatenated libraries;
proc copy in=sashelp out=work;
	select iris;
quit;

%getattribs(data=sashelp.iris, type=ds2);

%put %bquote(&attribs.);

proc ds2;

	data iris2 / overwrite=yes;

		&attribs.;

		method run();
			set iris;
		end;

	enddata;
	run;

 quit;

(3) Bring in variables for a hash table without needing to use a double set statement. This
	prevents non-matching hash variables from carrying forward.

	%getattribs(data=sashelp.cars, keep=make model horsepower);

	data cars;
		&attribs.;

		set sashelp.cars(keep=make model);

		if(_N_ = 1) then do;
			dcl hash cars_h(dataset:'sashelp.cars');
				cars_h.defineKey('make', 'model');
				cars_h.defineData('horsepower');
			cars_h.defineDone();
		end;
	
		rc = cars_h.Find();
	run;
*
\******************************************************************************/

%macro getattribs(
  data= 			/* Dataset to get var attributes */
, outmacvar=attribs /* Output macro variable to save attrib statements. Default: &attribs. */
, drop= 			/* Drop variables */
, keep= 			/* Keep variables */
, type=DATA			/* When DS2, changes the attrib statements to be compatible with ds2*/
, format=YES 		/* When NO, suppresses formats in attrib statements*/
, informat=YES		/* When NO, suppresses informats in attrib statements */
, label=YES			/* When NO, suppresses labels in attrib statements */
) / minoperator
;

	%global &outmacvar.;

	/* Remove case-sensitivity */
	%let data 	  = %upcase(&data.);
	%let type  	  = %upcase(&type.);
	%let drop 	  = %upcase(&drop.);
	%let keep     = %upcase(&keep.);
	%let format   = %upcase(&format.);
	%let informat = %upcase(&informat.);
	%let label	  = %upcase(&label.);

	/****** Dependent Macros ******/

	/* Parses libraries and dataset names from a one or two-level dataset name */
	%macro util_parse_lib_dsn(data=, outlib=lib, outdsn=dsn);
		%global &outlib &outdsn;

		%if(%scan(%bquote(&data.), 2, .) = %str() ) %then %do;
			%let &outlib = WORK;
			%let &outdsn = %qcmpres(&data.);
		%end;
			%else %do;
				%let &outlib = %qcmpres(%scan(%bquote(&data.), 1, .) );
				%let &outdsn = %qcmpres(%scan(%bquote(&data.), 2, .) );
			%end;
	%mend util_parse_lib_dsn;

	/* Checks if a macro variable is null or exists. Keeps errors from occurring in
	   conditional statements if the macro variable does not exist.
	*/
	%macro isnull(macvar);
		%if %symexist(&macvar.) %then %do;
			%sysevalf(%superq(%superq(macvar)) =, boolean)
		%end;
			%else 1
	%mend isnull;

	/****** End Dependent Macros ******/

	%util_parse_lib_dsn(data=&data.);

	/* Error checking */
	%if(%isnull(data) ) %then %do;
		%put ERROR: Must provide a dataset;
		%abort;
	%end;

	%if(%sysfunc(exist(&data.)) = 0) %then %do;
		%put ERROR: &lib..&dsn. does not exist.;
		%abort;
	%end;

	%if(%eval(&type. IN(DATA DS2) ) = 0) %then %do;
		%put ERROR: Type must be either DATA or DS2.;
		%abort;
	%end;

	%if(%isnull(keep) = 0 AND %isnull(drop) = 0) %then %do;
		%put ERROR: Cannot have both drop and keep arguments at the same time.;
		%abort;
	%end;

	/* Create a list of variable names to keep or drop  */
	%if(%isnull(keep) = 0 OR %isnull(drop) = 0) %then %do;

		proc transpose data=&data.(obs=0 

								   %if(%isnull(keep) = 0) %then %do;
								      keep=&keep.
								   %end;

								   %else %if(%isnull(drop) = 0) %then %do;
								      drop=&drop.
								   %end;

								  )
					   out=_getattribvars_ 
					   name=name;
			var _ALL_;
		run;
	%end;
					 
	/* Create the attrib statements of each variable for a data step/ds2 step */
	proc sql noprint;
		select 

		%if(&type. = DATA) %then %do;
			compbl(cat('attrib '
					  , cats("'", name, "'n")
					  , ' length=' /* v0.2 added space */
					  , CASE(type) when('char') then '$' else '' END
					  , length
					  , '.'

					  %if(&format.=YES) %then %do;
					 	 , CASE when(NOT missing(format) ) then cat(' format=',format)
								else '' 
						   END
					  %end;

					  %if(&informat.=YES) %then %do;
							, CASE when(NOT missing(informat) ) then cat(' informat=', informat) 
							  	   else '' 
							  END
					  %end;

					  %if(&label.=YES) %then %do;
							, CASE when(NOT missing(label) ) then cat(' label=', quote(strip(label) ) ) 
							  	   else '' 
							  END
					  %end;

					  , ';'
					  )
				   )
		%end;

		%else %do;
			compbl(cat( 'dcl '
					  , CASE(type) when('char') then 'char' else 'double' END
		   	    	  , CASE(type) when('char') then cat( '(', length, ') ' ) else ' ' END
					  , cats('"', name, '"')

					  /* Format */
					  , CASE
							when("&format." = "YES" AND NOT missing(format) ) then cat(' having format ', format)
							else ''
						END

					  /* Informat */
					  , CASE

						  	/* If the prior format was missing or the format was no, add 'having' here */
							when( 	  ("&format." = "NO" OR missing(format) )
								  AND ("&informat." = 'YES' AND NOT missing(informat) )
							    ) 
							then cat(' having informat ', informat)
							
							/* Otherwise, add the informat */
							when(	  ("&format." = "YES" AND NOT missing(format) )
								  AND ("&informat." = 'YES' AND NOT missing(informat) )
								)
							then cat(' informat ', informat)

							else ''
						END

					  /* Label */
					  , CASE

					  		/* If both prior formats were missing, add "having"*/
							when( 	  ("&format."   = "NO"  OR missing(format) )
								  AND ("&informat." = "NO"  OR missing(informat) )
								  AND ("&label." 	= 'YES' AND NOT missing(label) )
							    )
							then cat(' having label ', cats("'", label, "'" ) )
							
							/* Otherwise, add the label */
							when( 	  ("&format." 	= "YES" AND NOT missing(format) )
								  AND ("&informat." = "YES" AND NOT missing(informat) )
								  AND ("&label." 	= 'YES' AND NOT missing(label) )
							    )
							then cat(' label ', cats("'", label, "'" ) )

							else ''
					  END

					  , ';'
					  )
				  )
		%end;
		length=32767
		into :&outmacvar. separated by ' '
		from dictionary.columns
		where 	  libname = "&lib."
			  AND memname = "&dsn."

			  /* Filter to only the list of variables to keep or drop */
			  %if(%isnull(keep) = 0 OR %isnull(drop) = 0) %then %do;
			  		AND name IN(select name from _getattribvars_)
			  %end;
		;
	quit;

	/* Remove the temporary var dataset */
	%if(%isnull(keep) = 0 OR %isnull(drop) = 0) %then %do;

		proc datasets lib=work nolist nowarn;
			delete _getattribvars_;
		quit;

	%end;

%mend getattribs;