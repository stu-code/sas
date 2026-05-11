/* From stu-code/sas powerset/powerset.sas
   Generates the power set of a small list using ARRAY + allcomb().
   For n items there are 2^n subsets. allcomb arranges variables in-place,
   so we copy each combination to a parallel powerset[] array before output. */

%let values = 'ant' 'bee' 'cat' 'dog' 'ewe';
%let n = %sysfunc(countw(&values.));

data foo;
   array x[&n.] $ (&values.);
   array powerset[&n.] $;

   /* Empty subset */
   output;

   do items = 1 to dim(x);
       nCombos = comb(dim(x), items);

       do c = 1 to nCombos;
          rc = allcomb(c, items, of x[*]);

          do i = 1 to items;
              powerset[i] = x[i];
          end;

          output;
       end;
    end;

    keep powerset:;
run;

proc print data=foo;
    title "Power set of {ant, bee, cat, dog, ewe} - 32 subsets";
run;
