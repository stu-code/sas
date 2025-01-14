/******************************************************************************\
* Name: timeit.sas
*
* Purpose: Skeleton macro inspired by the %timeit magic function in Jupyter Notebooks to
*           help time and compare different code. This is great for identifying how 
*           long code runs on average, or for testing if one method is faster than another method.
*           Supports as many code chunks as you want to add.
*
* Author: Stu Sztukowski
*         stu.sztukowski@sas.com
*
* Parameters: trials | The number of times you want to run your code to calculate statistics.
*                      Default: 100      
*
* Usage: Use to test one or more code chunks to see how long it takes to run, on average
*        
* IMPORTANT: Be careful if testing macro functions. Make sure that you have local variables set for
*            common macro values like i, j, k, n, t, now, time1, time2, time3, desc1, desc2, desc3, etc. 
*            Failing to do so could cause the program to run in an infinite loop, end early, 
*            or have unexpected results.
\******************************************************************************/

%macro timeit(trials=100);

    /* If testing macro functions, make sure these are local */
    %local i n t start now;
    %do i = 1 %to 10;
        %local time&i;
        %local desc&i;
    %end;

    %let now = %sysfunc(transtrn(%sysfunc(datetime()), ., %str()));

    %do t = 1 %to &trials;

        %let n = 0; /* Do not change */

     /* Define your code chunks below 

        **** Important ****

        You must increment the variable n with each code chunk. To create 
        a code chunk to test, use this skeleton code:

        %let n      = %eval(&n+1);
        %let desc&n = Short description here;
        %let start  = %sysfunc(datetime());
            <code>
        %let time&n = %sysevalf(%sysfunc(datetime())-&start); 
     */

        /*************************************************************/
        /********************* Code Blocks Here **********************/
        /*************************************************************/

        /**** Code 1 ****/
        %let n      = %eval(&n+1);
        %let desc&n = Method 1;
        %let start  = %sysfunc(datetime());
            /* Put Code To Test here */
        %let time&n = %sysevalf(%sysfunc(datetime())-&start);

        /**** Code 2 ****/
        %let n      = %eval(&n+1);
        %let desc&n = Method 2;
        %let start  = %sysfunc(datetime());
            /* Put Code To Test here */
        %let time&n = %sysevalf(%sysfunc(datetime())-&start);

        /**** ... ****/

        /*************************************************************/
        /******************* End Code Blocks Here ********************/
        /*************************************************************/

        data trial_&now;
            %do i = 1 %to &n;
                time&i = &&time&i;
            %end;
        run;

        proc append base=times_&now data=trial_&now;
        run;
    %end;

    proc sql;
        select mean(time1) as avg_time1 label="Avg (s): &desc1" format=8.3
             , std(time1)  as std_time1 label="Std (s): &desc1" format=8.3
             %do i = 2 %to &n;
             , mean(time&i) as avg_time&i label="Avg (s): &&desc&i" format=8.3
             , std(time&i)  as std_time&i label="Std (s): &&desc&i" format=8.3
             %end;

        from times_&now;
    quit;

    proc datasets lib=work nolist;
        delete trial_&now times_&now;
    quit;

%mend;