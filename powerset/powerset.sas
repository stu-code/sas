/* Set values here */
%let values = 'ant' 'bee' 'cat' 'dog' 'ewe';

%let n = %sysfunc(countw(&values.));

data foo;
   array x[&n.] $ (&values.);
   array powerset[&n.] $;

   /* Empty value */
   output;

   do items = 1 to dim(x);
       nCombos=comb(dim(x), items);

       /* allcomb arranges variables in-place. Only save the variables that
          are being arranged.
       */ 
       do c=1 to nCombos;
          rc=allcomb(c, items, of x[*]);

          do i = 1 to items;            
              powerset[i] = x[i];
          end;

          output;
       end;
    end;

    keep powerset:;
run;
