/* From stu-code/sas examples/fcmp_examples.sas - Example 1: Numeric Functions
   Demonstrates PROC FCMP creating a custom fiscal-year function.
   A company whose Fiscal Year ends in July reports July 2020 as FY 2021.
   This wraps the year(intnx('year.7', date, 1, 'B')) logic into fy(). */

proc fcmp outlib=work.funcs.time;
    function fy(date);
        fy = year(intnx('year.7', date, 1, 'B'));
        return(fy);
    endsub;
run;

options cmplib=(work.funcs);

data fy;
    format date date9.;

    date = '01JUL2020'd;
    fiscal_year = fy(date);
    output;

    date = '30JUN2020'd;
    fiscal_year = fy(date);
    output;

    date = '15JAN2021'd;
    fiscal_year = fy(date);
    output;
run;

proc print data=fy;
    title "Fiscal year (July start) for sample dates";
run;
