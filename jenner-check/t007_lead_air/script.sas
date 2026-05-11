/* Adapted from stu-code/sas utility-macros/lead.sas
   The %lead macro adds future-value columns to a time-series dataset
   (the dual of LAG, which only gives past values). The macro is built
   around dataset functions (open/fetchobs/getvarn) for performance;
   the same effect can be expressed as a row-indexed self-join in SQL,
   which is what this bundle shows on sashelp.air. */

data air_shifted;
    set sashelp.air(rename=(air=lead1_air));
    retain row 0;
    row + 1;
    keep row lead1_air;
run;

data air_indexed;
    set sashelp.air;
    retain row 0;
    row + 1;
    format date date9.;
run;

proc sql;
    create table air_lead as
        select a.date
             , a.air
             , b.lead1_air
          from air_indexed a
          left join air_shifted b on b.row = a.row + 1
          order by a.row;
quit;

title "sashelp.air with a 1-step lead column (rows 1-12)";
proc print data=air_lead(obs=12);
    format date date9.;
run;

/* Quick self-check: in the printout above, lead1_air at row N
   should equal air at row N+1. */
