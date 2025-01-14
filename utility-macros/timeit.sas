/******************************************************************************\
* Name: timeit.sas
*
* Purpose: Skeleton macro inspired by the %%timeit magic function in Jupyter Notebooks to
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
*            common looping values like i, j, k, n, t, time1, time2, time3, etc. 
*            Failing to do so could cause the program to run in an infinite loop, end early, 
*            or have unexpected results.
\******************************************************************************/


%macro timeit(trials=100);
    %local i n t start;
    %do i = 1 %to 10;
        %local time&i;
    %end;

    %do t = 1 %to &trials;

        %let n = 0; /* Do not change */

     /* Define your code chunks below 

        **** Important ****

        You must increment the variable n with each code chunk. To create 
        a code chunk to test, use this skeleton code:

        %let n = %eval(&n+1);
        %let start=%sysfunc(datetime());
            <code>
        %let time&n = %sysevalf(%sysfunc(datetime())-&start); 
     */

        /* Code 1 */
        %let n = %eval(&n+1);
        %let start=%sysfunc(datetime());
            /* Code here */
        %let time&n = %sysevalf(%sysfunc(datetime())-&start);

        /* Code 2 */
        %let n = %eval(&n+1);
        %let start=%sysfunc(datetime());
            /* Code here */
        %let time&n = %sysevalf(%sysfunc(datetime())-&start);

        /* ... */

        data time;
            %do i = 1 %to &n;
                time&i = &&time&i;
            %end;
        run;

        proc append base=times data=time;
        run;
    %end;

    proc sql;
        select mean(time1) as avg_time1 label="Avg: Method 1"
             , std(time1)  as std_time1 label="Std: Method 1"
             %do i = 1 %to &n;
             , mean(time&i) as avg_time&i label="Avg: Method &i"
             , std(time&i)  as std_time&i label="Std: Method &i"
             %end;

        from times;
    quit;

    proc datasets lib=work nolist;
        delete times;
    quit;

%mend;