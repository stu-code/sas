/* Adapted from stu-code/sas utility-macros/cquote.sas
   The repo provides two cquote forms: one macro (for symbol-time use in
   IN() lists) and one PROC FCMP function (for run-time use in data steps).
   Here we exercise the FCMP form against sashelp.cars - cleaner compile
   target than the macro form and works in DATA / SQL just the same. */

proc fcmp outlib=work.funcs.str;
    function cquote(str$) $200;
        return (cats('"', tranwrd(compbl(str),' ','","'), '"'));
    endfunc;
run;

options cmplib=(work.funcs);

data lists;
    length raw $40 dq $80;
    raw = 'BMW Audi Volvo';   dq = cquote(raw); output;
    raw = 'cars class air';   dq = cquote(raw); output;
    raw = 'a b c';            dq = cquote(raw); output;
    keep raw dq;
run;

proc print data=lists;
    title "Space-separated -> double-quoted, comma-separated (FCMP cquote)";
run;
