/* From stu-code/sas examples/fcmp_examples.sas - Example 2: String Functions
   PROC FCMP can create custom char functions. cquote() converts a
   space-separated string into a double-quoted, comma-separated list -
   useful for building IN() lists from space-separated macro vars. */

proc fcmp outlib=work.funcs.string;
    function cquote(strin$) $ 200;
        length strout    $32767
               token     $1
        ;

        strclean = compbl(strin);
        strout   = '"';

        do i = 1 to length(strclean);
            token = substr(strclean, i, 1);

            if(i < length(strclean) ) then do;
                if(token = ' ') then strout = catt(strout, '","');
                    else strout = catt(strout, token);
            end;
                else strout = catt(strout, token, '"');
        end;

        return(strout);
    endsub;
run;

options cmplib=(work.funcs);

data demo;
    length input_list $40 quoted_list $80;
    input_list = 'cars class air';
    quoted_list = cquote(input_list);
    output;

    input_list = 'BMW Mercedes Audi';
    quoted_list = cquote(input_list);
    output;

    keep input_list quoted_list;
run;

proc print data=demo;
    title "Space-separated lists turned into IN()-compatible quoted lists";
run;
