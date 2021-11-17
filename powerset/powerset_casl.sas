/* Comparison to Python powerset program:
   https://www.delftstack.com/howto/python/powerset-python/
*/

cas;

proc cas;
	set     = {1, 2, 3, 4, 5};
	subsets = {};

	do i = 1 to 2**dim(set);
		subset = {};
		
		do k = 1 to dim(set);
			if(band(i-1, blshift(1, k-1)) ) then subset = subset + set[k];
		end;

		subsets = subsets + {subset};
	end;

	print subsets;
run;
