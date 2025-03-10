/******************************************************************************\
* Name: va_api_etag.sas
*
* Purpose: Macro to get the etag of a SAS Visual Analytics report on SAS Viya.
*
* Author: Stu Sztukowski
*
* Parameters: report    | The report URI. You can get this from "Copy Link"
*             outmacvar | Output macro variable name. Default: etag.
*
* Output: Directly outputs the etag of a report.
*
* Usage: Use this to get the etag of a report. This is often needed for If-Match
*        in the header. Without this, some API calls won't work.
*
*        For information on an etag, see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match
*
*
* Example: Note that this example will not work directly on your system. You'll need to find
*          your own report URI.
*
           %get_etag(e17fecfc-1ab2-43a3-9b9e-560a2c4adeaf);
           %put etag: &etag;
*
/******************************************************************************/

%macro get_etag(report, outmacvar=etag);
    %local url _etag_;
    %global &outmacvar;

    %let url  = %sysfunc(getoption(SERVICESBASEURL));
    %let hout = h%substr(%sysfunc(datetime()), 1, 7);

    filename &hout temp;

    proc http
        url          = "&url/reports/reports/&report"
        method       = GET
        headerout    = &hout
        oauth_bearer = sas_services;
    run;

    %if(&SYS_PROCHTTP_STATUS_CODE NE 200) %then %do;
        %put ERROR: Did not receive a 200 OK status code from the server. The status code is: &SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE..;
        %put Test URL: &url/reports/reports/&report;
        %abort;
    %end;

    data _null_;
        infile &hout;
        input;
        put _INFILE_;
      
        if(_INFILE_ =: "ETag:") then call symputx('_etag_', scan(_INFILE_, 2, ':'));
    run;

    filename &hout clear;

    %let &outmacvar = &_etag_;
%mend;