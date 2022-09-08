/******************************************************************************\
* Name: parallel.sas
*
* Purpose: This macro is an example of how to parallel-process a single dataset. This macro will allow multiple SAS sessions
*		   to analyze a single dataset split into parts. Each worker will have its own reader/PDV, greatly increasing
*		   overall throughput. PROCS, DATA steps, and more can be used.
*
*		   This program is not thread-safe. Row-dependent operations and by-groups must be accounted for first before
*		   running.
*
*		   To add your own code, place it between the rsubmit block.
*
* Author: Stu Sztukowski
*
* Parameters: data	  | Input dataset
*			  workers | Number of workers (threads) to analyze the data. Recommended not to go higher than system CPU count.
*
*
* Example: Split up sashelp.cars, add a "worker" variable, and bring it back together.
*
* %parallel(data=sashelp.cars, workers=3);
*	
*
* Dependencies/Assumptions: SAS/CONNECT is licensed
\******************************************************************************/

options autosignon=yes 		/* Automatically handle sign on to RSUBMIT sessions */
		noconnectwait		/* Run all RSUBMIT sessions in parallel */
		noconnectpersist	/* Sign off after each RSUBMIT session ends */
		sascmd='!sascmd'	/* Sign on to each RSUBMIT session with the same SAS command used to start this session */
		;

%macro parallel(data=, workers=);
	%let dsid	= %sysfunc(open(&data.));
	%let n	= %sysfunc(attrn(&dsid., nlobs));
	%let rc 	= %sysfunc(close(&dsid.));

    libname workdir "%sysfunc(getoption(work))";

    %do w = 1 %to &workers.;

		/* Determine the starting and end observation for each worker */
		%let firstobs = %sysevalf(&n-(&n/&workers.)*(&workers.-&w+1)+1, floor);
		%let obs 	= %sysevalf(&n-(&n/&workers.)*(&workers.-&w.), floor);

		/* Keep track of the total for each worker */
		%let total&w. = %sysevalf( &obs. - &firstobs. + 1);

	/* Give each worker all user-generated macro variables in this session. This ensures they have:
		   &data
	       &firstobs
		   &obs
		   &w
	*/
	%syslput _USER_ / remote=worker&w.;

		/* Split the data evenly among all workers and read the data in parallel sessions */
		rsubmit remote=worker&w. inheritlib=(workdir);

			/*********************************************************/
			/********************* Put code here *********************/
			/*********************************************************/

			/* cnttlev=rec option ensures that the dataset is locked with record-level control */
		    data workdir._out_&w.;
				length worker 8.;

		        set &data.(firstobs=&firstobs. obs=&obs. cntllev=rec);

				worker = &w.;
		    run;

		endrsubmit;

    %end;


	%let total = 0;

	%put;
	%put Worker Observation Count;
	%put ________________________;

	/* Print each worker obs. count to the log and keep a running sum 
	   %sysfunc(compress()) used because %cmpres will produce compile notes*/
	%do i = 1 %to &workers.;
		%put &i.: %sysfunc(compress(%qsysfunc(putn(&&total&i., comma24.) ) ) );
		%let total = %eval(&total. + &&total&i.);
	%end;

	%put ________________________;
	%put TOTAL: %sysfunc(compress(%qsysfunc(putn(&total., comma24.) ) ) );
	
	%put;
	%put NOTE: Waiting for workers to finish...;

	/* Wait for all workers to complete their tasks */
    waitfor _ALL_;

	/* Put the results together */
    data output;
        set _out:;
    run;
%mend;
