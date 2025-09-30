/*************** Setup  ***************/
%let shapefile = North_Carolina_State_and_County_Boundary_Polygons.shp;
%let out       = shape_nc_counties;
%let id        = GlobalID; /* Set your polygon ID column here */
%let reduce    = True;     /* Set to False if you do not want to reduce the vertices */
%let density   = 3;        /* 1-5. The smaller the density, the smaller the dataset. 3 is a good start */
/************* End Setup  *************/

/* Import the map */
proc mapimport infile="/mnt/viya-share/data/sda/shapefiles/&shapefile" out=map_imported;
run;

/* Optionally reduce the size */
%if(%upcase(&reduce) = TRUE) %then %do;
    %put NOTE: Reducing size of map with density = &density;

    proc greduce data=map_imported out=map_imported(where=(density LE &density));
        id &id;
    run;
%end;

/* Load to CAS */
cas;
caslib _ALL_ assign;

/* Remove the promoted table if it exists */
proc datasets lib=public nolist;
    delete &out;
quit;

data public.&out;
    set map_imported;
    seq+1;
    drop density;
run;

/* Permanently save it */
proc casutil;
    save casdata="&out" incaslib='public' outcaslib='public' replace;
quit;