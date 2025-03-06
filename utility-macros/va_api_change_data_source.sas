/******************************************************************************\
* Name: va_api_change_data_source.sas
*
* Purpose: Skeleton code to change the data source of a Visual Analytics report
*
* Author: Stu Sztukowski
*
* Parameters: report | The report URI. You can get this from "Copy Link"
*             folder | The output folder URI. You can get this easily from get_folder_uri.sas 
*                      https://github.com/stu-code/sas/blob/master/utility-macros/get_folder_uri.sas
*
* Usage: Use this to change a data source in Visual Analytics from SAS Studio.
*        The areas you need to change in the JSON payload are marked with stars (*).
*        For more information on how to change a data source in Visual Analytics, see
*        the changeData operation in updateReport in the REST API documentation:
*
*        https://developer.sas.com/rest-apis/visualAnalytics/updateReport
*
/******************************************************************************/

%let report = REPORT URI HERE;          * URI of the report. Not the name. Get this from Copy Link in VA;
%let folder = OUTPUT FOLDER URI HERE;   * URI of the folder. Not the name. Get this from the /folders/folders endpoint;
%let url    = %sysfunc(getoption(SERVICESBASEURL)); *Automaticaly get the URL from the SAS server;

filename resp temp;

/* Send a JSON payload using the changeData operation from the Visual Analytics API.
   The VA API is located at:
   https://your-viya-server.com/visualAnalytics/reports/{report-uri-here} 

   The parts you need to change are surrounded by stars * and start with "CHANGEME:"
*/
proc http
    url    = "&url/visualAnalytics/reports/&report"
    method = PUT
    out    = resp
    oauth_bearer=sas_services /* Easy OAuth authentication */
    in='
{
    "version": 1,
    "resultFolder": "/folders/folders/&folder",
    "resultReportName": "**** CHANGEME: REPORT NAME GOES HERE ****",
    "resultNameConflict": "replace",
    "operations": [
      {
        "changeData": {
          "originalData": {
            "cas": {
        "server":  "cas-shared-default",
        "library": "**** CHANGEME: OLD LIBRARY NAME GOES HERE **** ",
              "table":   "**** CHANGEME: OLD TABLE NAME GOES HERE ****"
            }
          },
          "replacementData": {
            "cas": {
        "server":  "cas-shared-default",
        "library": "**** CHANGEME: NEW LIBRARY NAME GOES HERE **** ",
              "table":   "**** CHANGEME: NEW TABLE NAME GOES HERE ****"
            }
          }
        }
      }
    ]
}
'
    ;
    headers
        "If-Unmodified-Since"="Fri, 01 Jan 9999 00:00:00 GMT"
        "Content-Type"="application/json"
        "Accept"="application/json"
    ;
run;

/* Print the result to the log */
data _null_;
    infile resp;
    input;
    put _INFILE_;
run;