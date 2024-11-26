/* Runs code 100 times and calculates the avg and std of it */

%macro timeit;
    %do i = 1 %to 100;

        %let start=%sysfunc(datetime());
            /* Code here */
        %let time1 = %sysevalf(%sysfunc(datetime())-&start);

        %let start=%sysfunc(datetime());
            /* Code here */
        %let time2 = %sysevalf(%sysfunc(datetime())-&start);

        data time;
            time1 = &time1;
            time2 = &time2;
            time3 = &time3;
        run;

        proc append base=times data=time;
        run;
    %end;

    proc sql;
        select mean(time1) as avg_time1 label='Avg: '
             , std(time1)  as std_time1 label='Std: '
             , mean(time2) as avg_time2 label='Avg: '
             , std(time2)  as std_time2 label='Std: '
        from times;
    quit;

    proc datasets lib=work nolist;
        delete times;
    quit;

%mend;

%timeit;