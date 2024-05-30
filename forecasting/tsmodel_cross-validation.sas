/******************************************************************************\
*
* Name: tsmodel_cross-validation.sas
*
* Purpose: Performs cross-validation on the A10 R anti-diabetic sales dataset
*          using TSMODEL. The goal is to try and recreate Udo Sglavo's HPF cross-validation work 
*          from 2011 using TSMODEL in Viya. For more information, see his blog post:
*          https://blogs.sas.com/content/forecasting/2011/09/02/guest-blogger-udo-sglavo-on-cross-validation-using-sas-forecast-server-part-1-of-2/
*
* Author: Stu Sztukowski
*
* Parameters: folder    | Folder location where a10.csv lives
*             file      | File name of a10.csv
*             min_train | Minimum number of training periods
*             max_lead  | Maximum forecast length
*
* Dependencies/Assumptions: Viya 4 with Visual Forecasting is installed
*
* Usage: Experimental for performing cross-validation with TSMODEL. 
*
* History: 05MAY2024 stsztu | v0.1 - Initial test
*
\******************************************************************************/


/******* User parameters *******/
%let folder    = ...;
%let file      = a10.csv;
%let min_train = 60;
%let max_lead  = 12;

/******* Program Start *******/
cas;
caslib _ALL_ assign;

filename a10 filesrvc
    folderpath = "&folder"
    filename   = "&file"
;

/* Read in data and add trend + seasonal dummies */
data casuser.a10;
    format date monyy.;
    infile a10 dlm=',' firstobs=2;
    input rownames time sales;
    array season[11];

    date = mdy(round((time - int(time))*12+1), 1, int(time));
    
    do i = 1 to dim(season);
        season[i] = (i = month(date));
    end;

    trend+1;

    drop rownames i time;
run;

proc tsmodel data   = casuser.a10
             outobj = (outfor=casuser.outfor);
 
    id date interval=month;
    
    var sales season: trend;

    require tsm;

    submit;

        /* Model specs */
        dcl object arima_spec(arimaspec);
        dcl object loglin_spec(arimaspec);
        dcl object winters_spec(esmspec);
    
        /* Models */
        dcl object arima_model(tsm);
        dcl object loglin_model(tsm);
        dcl object winters_model(tsm);

        dcl object outfor(tsmfor ('modelname', 'yes') );

        /* ARIMA spec */
        rc = arima_spec.open();
            
            /* (3, 0, 1) (0, 1, 1)s */
            array diff[1]/nosymbols  (.S);
            array ar[3]/nosymbols    (1 2 3);
            array ma[1]/nosymbols    (1);
            array sma[1]/nosymbols   (.S);

            rc = arima_spec.setTransform('log');
            rc = arima_spec.setDiff(diff);
            rc = arima_spec.addARPoly(ar);
            rc = arima_spec.addMAPoly(ma);
            rc = arima_spec.addMAPoly(sma,1,1);
            rc = arima_spec.setOption('method', 'ML');
        rc = arima_spec.close();
    
        /* Log-linear spec */
        rc = loglin_spec.open();           
            rc = loglin_spec.setTransform('log');          
            rc = loglin_spec.addTF('trend');

            do i = 1 to 11;
                rc = loglin_spec.addTF(cats('season', i));
            end;
        rc = loglin_spec.close();

        /* Multiplicative Winters spec */
        rc = winters_spec.open();
            rc = winters_spec.setOption('Method', 'Winters');
        rc = winters_spec.close();
        
        /* Define ARIMA model */
        rc = arima_model.initialize(arima_spec);
            rc = arima_model.setY(sales);
   
        /* Define Log-linear model */
        rc = loglin_model.initialize(loglin_spec);
            rc = loglin_model.setY(sales);

            rc = loglin_model.addX(trend);

            %macro add_season;
                %do i = 1 %to 11;
                    rc = loglin_model.addX(season&i);
                %end;
            %mend;
            %add_season;

        /* Define Multiplicative Winters ESM */
        rc = winters_model.initialize(winters_spec);
            rc = winters_model.setY(sales);
        
        /* Forecast 1-max_lead periods out and collect error for each */
        do lead = 1 to &max_lead;
            do h = &min_train to _LENGTH_;

                /* Keeps from duplicating forecasts once the horizon exceeds the length */
                if(h+lead+1 > _LENGTH_) then leave;

                /* Add +lead to account for back=
                   Add +1 to account for horizon */
                horizon = date[h+lead+1];

                rc = arima_model.setOption('back', lead, 'lead', lead, 'horizon', horizon);
                rc = loglin_model.setOption('back', lead, 'lead', lead, 'horizon', horizon);
                rc = winters_model.setOption('back', lead, 'lead', lead, 'horizon', horizon);
    
                rc = arima_model.run();
                rc = loglin_model.run(); 
                rc = winters_model.run();
            
                /* Each model name consists of the horizon and number of training obs.
                   For example: ARIMA_1_60 means the ARIMA model with 1 lead and 60 training obs.
                   This makes it easy to grab the max date for each forecast later */
                rc = outfor.setOption('modelname', cats('ARIMA_', lead, '_', h) );
                rc = outfor.collect(arima_model, 'forecast');
    
                rc = outfor.setOption('modelname', cats('LOGLIN_', lead, '_', h) );
                rc = outfor.collect(loglin_model, 'forecast');
    
                rc = outfor.setOption('modelname', cats('Winters_', lead, '_', h) );
                rc = outfor.collect(winters_model, 'forecast');
            end;
        end;

    endsubmit;
run;

/* Grab the max date for each forecast and calculate MAE for each horizon */
proc sql;
    create table plot as
        select scan(_MODEL_, 1, '_') as Model
             , input(scan(_MODEL_, 2, '_'), 8.) as Horizon
             , mean(abs(error)) as MAE
        from (select _MODEL_, error
              from casuser.outfor
              group by _MODEL_
              having date = max(date)
             )
        group by calculated model, calculated horizon
    ;
quit;

/* Set colors for models and plot it */
data attrmap;
  input id$ value$ linecolor$;
datalines;
model ARIMA green
model LOGLIN red
model Winters blue
;
run;

proc sgplot data=plot dattrmap=attrmap;
    xaxis type=discrete;
    yaxis grid;
    series x=horizon y=mae / group=model attrid=model;
run;