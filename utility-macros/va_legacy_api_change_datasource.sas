/******************************************************************************\
* Name: va_legacy_api_change_datasource.sas
*
* Purpose: Skeleton code to change the data source of a Visual Analytics report using the legacy
*          reportTransforms API
*
* Author: Stu Sztukowski
*
* Parameters: report | The report URI. You can get this from "Copy Link"
*
* Dependencies: %get_etag: https://raw.githubusercontent.com/stu-code/sas/refs/heads/master/utility-macros/va_api_get_etag.sas
*
* Usage: Use this to change a data source in Visual Analytics from SAS Studio in Viya 3.5.
*        The areas you need to change in the JSON payload are prefixed with CHANGEME.
*        For more information on how to change a data source in Visual Analytics, see
*        the changeData operation in updateReport in the REST API documentation:
*
*        https://your-viya-server.com/reportTransforms/dataMappedReports
*
/******************************************************************************/

%let report = CHANGEME: REPORT URI HERE;              * URI of the report. Not the name. Get this from Copy Link in VA;
%let url    = %sysfunc(getoption(SERVICESBASEURL));   * Automaticaly get the URL from the SAS server;

/***** Get etag *****/
filename etagmac url "https://raw.githubusercontent.com/stu-code/sas/refs/heads/master/utility-macros/va_api_get_etag.sas";
%include etagmac;
%get_etag(&report);

proc http
    url    = "&url/reportTransforms/dataMappedReports/&report"
    method = PUT
    out    = resp
    oauth_bearer=sas_services
    in='

{
  "dataSources": [
   {
      "purpose": "original",
      "namePattern": "serverLibraryTable",
      "server": "cas-shared-default",
      "library": "***** CHANGEME: ORIGINAL LIBRARY *****",
      "table": "***** CHANGEME: ORIGINAL TABLE *****"
    },
    {
      "purpose": "replacement",
      "namePattern": "serverLibraryTable",
      "server": "cas-shared-default",
      "library": "***** CHANGEME: NEW LIBRARY *****",
      "table": "***** CHANGEME: NEW TABLE *****",
      "replacementLabel": "***** CHANGEME: THE SAME NAME AS NEW TABLE *****"
    }
  ]
}

';
    headers
        "If-Match"=%tslit(&etag)
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
