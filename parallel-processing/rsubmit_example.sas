/******************************************************************************\
* Name: rsubmit_example.sas
*
* Purpose: Gives an example of running PROC MEANS in parallel on two different datasets using RSUBMIT.
*
* Author: Stu Sztukowski
*
* Parameters: N/A
*
* Dependencies/Assumptions: SAS/STAT is licensed
*							SAS/CONNECT is licensed
\******************************************************************************/

options autosignon=yes 		/* Automatically handle sign on to RSUBMIT sessions */
		noconnectwait		/* Run all RSUBMIT sessions in parallel */
		noconnectpersist	/* Sign off after each RSUBMIT session ends */
		sascmd='!sascmd'	/* Sign on to each RSUBMIT session with the same SAS command used to start this session */
		;

/* Create a library for the WORK directory that can be inherited by RSUBMIT workers */
libname workdir "%sysfunc(getoption(work))";

/* Run PROC MEANS on sashelp.class in one worker session and output the results 
   into the main session's WORK directory
*/
rsubmit inheritlib=(workdir) remote=worker1;
	proc means data=sashelp.class noprint;
		output out=workdir.means_class;
	run;	
endrsubmit;

/* Run PROC MEANS on sashelp.heart in another worker session and output the results 
   into the main session's WORK directory
*/
rsubmit inheritlib=(workdir) remote=worker2;
	proc means data=sashelp.heart noprint;
		output out=workdir.means_heart;
	run;	
endrsubmit;

/* Wait for both to complete */
waitfor _ALL_;

title 'Output from worker1';
proc print data=means_class;
run;

title 'Output from worker2';
proc print data=means_heart;
run;


