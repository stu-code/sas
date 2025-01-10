/* TODO: Make a header
   Author: Stu Sztukowski

   This macro is inspired by the %%timeit magic command in Jupyter notebooks.

   Runs code a defined number of times and calculates the avg and std of 
   how long it took across all runs. 

   Default: 100 trials */

%macro timeit(trials=100);
    %local i n t;

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