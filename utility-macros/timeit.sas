/******************************************************************************\
* Name: timeit.sas
*
* Purpose: Skeleton macro inspired by the %timeit magic function in Jupyter Notebooks to
*          help benchmark and compare different code. This is great for identifying how 
*          long code runs on average, or for testing if one method is faster than another method.
*          Supports as many code snippets as you want to add.
*
* Author: Stu Sztukowski
*         stu.sztukowski@sas.com
*
* Parameters: times | The number of times you want to run your code to calculate statistics.
*                     Default: 100      
*
* Usage: Use to test one or more code snippets to see how long it takes to run, on average
*        
* IMPORTANT: Be careful if testing macro functions. Make sure that you have local variables set for
*            common macro values like i, j, k, n, t, now, time1, time2, time3, desc1, desc2, desc3, etc. 
*            Failing to do so could cause the program to run in an infinite loop, end early, 
*            or have unexpected results.
\******************************************************************************/

%macro timeit(times=100);

    /* If testing macro functions, make sure these are local */
    %local i n t start now;
    %do i = 1 %to 10;
        %local time&i;
        %local desc&i;
    %end;

    %let now = %sysfunc(transtrn(%sysfunc(datetime()), ., %str()));

    %do t = 1 %to &times;

        %let n = 0; /* Do not change */

     /* Define your code snippets below 

        **** Important ****

        You must increment the variable n with each code snippet. To create 
        a testing block, copy and paste this code:

        %let n      = %eval(&n+1);
        %let desc&n = Short description here;
        %let start  = %sysfunc(datetime());
            <code snippet goes here>
        %let time&n = %sysevalf(%sysfunc(datetime())-&start); 
     */

        /*************************************************************/
        /********************* Code To Benchmark *********************/
        /*************************************************************/

        /**** Code 1 ****/
        %let n      = %eval(&n+1);
        %let desc&n = Snippet 1;
        %let start  = %sysfunc(datetime());
            /* Put Code Snippet To Test Here */
        %let time&n = %sysevalf(%sysfunc(datetime())-&start);

        /**** Code 2 ****/
        %let n      = %eval(&n+1);
        %let desc&n = Snippet 2;
        %let start  = %sysfunc(datetime());
            /* Put Code Snippet To Test Here */
        %let time&n = %sysevalf(%sysfunc(datetime())-&start);

        /**** ... ****/

        /*************************************************************/
        /******************* End Code To Benchmark *******************/
        /*************************************************************/

        data time_&now;
            %do i = 1 %to &n;
                time&i = &&time&i;
            %end;
        run;

        proc append base=all_times_&now data=time_&now;
        run;
    %end;

    title "Total runs: &times";
    title2 "Times are in seconds";

    proc sql;
        select mean(time1) as avg_time1 label="Avg (s): &desc1" format=8.3
             , std(time1)  as std_time1 label="Std (s): &desc1" format=8.3
             %do i = 2 %to &n;
             , mean(time&i) as avg_time&i label="Avg (s): &&desc&i" format=8.3
             , std(time&i)  as std_time&i label="Std (s): &&desc&i" format=8.3
             %end;

        from all_times_&now;
    quit;

    title; title2;

    proc datasets lib=work nolist;
        delete time_&now all_times_&now;
    quit;

%mend;