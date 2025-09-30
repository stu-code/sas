/*************** Setup  ***************/
%let shapefile = North_Carolina_State_and_County_Boundary_Polygons.shp;
%let outtable  = shape_nc_counties;
%let id        = GlobalID; /* Set your polygon ID column here */
%let reduce    = 1         /* Set to 0 if you have issues displaying data */
/************* End Setup  *************/

cas;
caslib _ALL_ assign;


/* Remove the promoted table if it exists */
proc datasets lib=public nolist;
    delete &outtable;
quit;

%shpimprt(
    shapefilepath="/mnt/viya-share/data/sda/shapefiles/&shapefile",
    outtable=&outtable,
    id=&id,
    caslib='public',
    cashost='sas-cas-server-default-client',
    casport=5570,
    reduce=&reduce 
);

/* Check the output - shpimport stops the CAS session when it's done */
cas;
caslib _ALL_ assign;

/* OPTIONAL: Run this code to see the dataset SAS uses */

/* 
proc mapimport datafile="/mnt/viya-share/data/sda/shapefiles/&shapefile" out=&outtable;
run;
*/