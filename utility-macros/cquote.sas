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
*             quote     | Optional. Specify SINGLE or DOUBLE quotes. 
*                         Default: DOUBLE
*
*             FUNCTION
*             strlist   | Space-separated string list. Returns a length of 200 if none is assigned.
*
* Usage: Ideally useful for creating quoted lists of macro variables. Exists in both an FCMP and a macro
*        form.
*        
* Example:

  (1) Convert a space-separated list into a double-quoted, comma-separated list
      %let list = a b c;
      %put %cquote(&list);
      
  (2) Convert a space-separated list into a single-quoted, comma-separated listed
      %let list = a b c;
      %put %cquote(&list, single);

  (3) Use a space-separted list in an IN operator:
      %let list = BMW Mercedes Audi;

      data foo;
          set sashelp.cars;
          where make IN(%cquote(&list));
      run;

  (4) Convert a DATA Step string into a quoted list

      options cmplib=work.funcs;

      data bar;
          list  = 'a b c';
          qlist = cquote(list);
      run;
   
*
\******************************************************************************/

%macro cquote(strlist, quote);
    %if(%upcase(&quote) = SINGLE) %then %let q = %str(%');
        %else %let q = %str(%");

    %unquote(%bquote(&q)%qsysfunc(tranwrd(%qsysfunc(compbl(%superq(strlist))),%bquote( ),%bquote(&q,&q)))%bquote(&q))
%mend;

proc fcmp outlib=work.funcs.str;

    /* Double quote version */
    function cquote(str$) $200;
        return (cats('"', tranwrd(compbl(str),' ','","'), '"'));
    endfunc;

    /* Single quote version */ 
    function scquote(str$) $200;
        return (cats("'", tranwrd(compbl(str),' ',"','"), "'"));
    endfunc;
run;