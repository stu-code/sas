/* From stu-code/sas examples/fcmp_examples.sas - Example 3: Subroutines
   PROC FCMP can also create CALL routines (subroutines).
   outargs marks parameters that the subroutine modifies in place. */

proc fcmp outlib=work.funcs.subs;
    subroutine inverse(in, inv);
        outargs inv;

        if(in = 0) then do;
            put 'WARNING: Inverse of 0 is undefined.';
            inv = .;
        end;
            else inv = 1/in;
    endsub;
run;

options cmplib=(work.funcs);

data inverse;
    call inverse(10, inv);
    output;
    call inverse(2, inv);
    output;
    call inverse(0.5, inv);
    output;
    call inverse(0, inv);
    output;
run;

proc print data=inverse;
    title "Multiplicative inverse via PROC FCMP CALL routine";
run;
