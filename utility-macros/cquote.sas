/******************************************************************************\
* Name: cquote.sas
*
* Purpose: Converts a list of space-separated strings into a quoted, comma-separated list.         
*
* Author: Original code by Tom - StackOverflow: https://stackoverflow.com/a/65863926
*         Converted to functions by Stu Sztukowski
*         stu.sztukowski@sas.com
*
*             MACRO
* Parameters: strlist   | Space-separated string list
*
*             FUNCTION
*             strlist   | Space-separated string list. Returns a length of 200 if none is assigned.
*
* Usage: Ideally useful for creating quoted lists of macro variables. Exists in both an FCMP and a macro
*        form.
*        
* Example:

  (1) Convert a space-separated list into a quoted, comma-separated list
      %let list = a b c;
      %put %cquote(&list);
      
  (2) Use a space-separted list in an IN operator:
      %let list = BMW Mercedes Audi;

      data foo;
          set sashelp.cars;
          where make IN(%cquote(&list));
      run;

  (3) Convert a DATA Step string into a quoted list

      options cmplib=work.funcs;

      data bar;
          list  = 'a b c';
          qlist = cquote(list);
      run;
   
*
\******************************************************************************/

%macro cquote(strlist);
    "%sysfunc(tranwrd(%qsysfunc(compbl(%superq(strlist))),%bquote( ),%bquote(",")))"
%mend;

proc fcmp outlib=work.funcs.str;
    function cquote(str$) $200;
        return (cats('"', tranwrd(compbl(str),' ','","'), '"'));
    endfunc;
run;