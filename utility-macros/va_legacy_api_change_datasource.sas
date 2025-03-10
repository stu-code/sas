/******************************************************************************\
* Name: va_legacy_api_change_datasource.sas
*
* Purpose: Skeleton code to change the data source of a Visual Analytics report using the legacy
*       reportTransforms API
*
* Author: Stu Sztukowski
*
* Parameters: report | The report URI. You can get this from "Copy Link"
*
* Usage: Use this to change a data source in Visual Analytics from SAS Studio in Viya 3.5.
*        The areas you need to change in the JSON payload are prefixed with CHANGEME.
*        For more information on how to change a data source in Visual Analytics, see
*        the changeData operation in updateReport in the REST API documentation:
*
*        https://your-viya-server.com/reportTransforms/dataMappedReports
*
/******************************************************************************/

%let report = REPORT URI HERE;                        * URI of the report. Not the name. Get this from Copy Link in VA;
%let url    = %sysfunc(getoption(SERVICESBASEURL));   * Automaticaly get the URL from the SAS server;

filename resp temp;
filename hout temp;

/***** Get etag *****/
proc http
    url       = "&url/reports/reports/&report"
    method    = GET
    out       = resp
    headerout = hout
    oauth_bearer=sas_services;
run;

data _null_;
    infile hout;
    input;
    put _INFILE_;
  
    if(_INFILE_ =: "ETag:") then call symputx('etag', scan(_INFILE_, 2, ':'));
run;

/* Send a JSON payload using the changeData operation from the Report Transforms API.
   The VA API is located at:
   https://your-viya-server.com/reportTransforms/dataMappedReports/{report ID}

   This changes the table CARS in PUBLIC to CARSSASHELP in Public
*/
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
      "library": "Public",
      "table": "CARS"
    },
    {
      "purpose": "replacement",
      "namePattern": "serverLibraryTable",
      "server": "cas-shared-default",
      "library": "Public",
      "table": "CARSSASHELP",
      "replacementLabel": "CARSSASHELP"
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
