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
* History: 29MAY2024 stsztu | v0.1 - Initial test
*          30MAY2024 stsztu | v0.2 - Significantly improved performance
\******************************************************************************/

/******* User parameters *******/
%let folder = ...;
%let file   = a10.csv;

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

    call symputx('_LENGTH_', _N_);

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
                   
        /* Max lead periods and minimum number of training obs */
        lead = &lead;
        min_train = &min_train;
        
        /* Forecast one step ahead until we reach the end of the series*/
        do step = min_train to _LENGTH_;

            /* Add +lead to account for back=
               Add +1 to account for horizon */
            horizon = date[step+lead+1];

            /* Prevent lead from going too far (i.e. "collision detection" with the end of time series "wall")
               If this is not done then forecasts will repeat at the end of the series */
            if(step+lead > _LENGTH_) then lead = lead-1;

            rc = arima_model.setOption('back', lead, 'lead', lead, 'horizon', horizon);
            rc = loglin_model.setOption('back', lead, 'lead', lead, 'horizon', horizon);
            rc = winters_model.setOption('back', lead, 'lead', lead, 'horizon', horizon);
    
            rc = arima_model.run();
            rc = loglin_model.run(); 
            rc = winters_model.run();
            
            rc = outfor.setOption('modelname', cats('ARIMA_', step) );
            rc = outfor.collect(arima_model, 'forecast');
        
            rc = outfor.setOption('modelname', cats('LOGLIN_', step) );
            rc = outfor.collect(loglin_model, 'forecast');
    
            rc = outfor.setOption('modelname', cats('Winters_', step) );
            rc = outfor.collect(winters_model, 'forecast');
        end;

    endsubmit;
run;

/* Add horizon */
data casuser.outfor2;
    set casuser.outfor;
    by _MODEL_ date;

    if(first._MODEL_) then horizon = 0;
    horizon+1;

    step  = input(scan(_MODEL_, -1, '_'), 8.);
    model = scan(_MODEL_, 1, '_');
run;

/* Grab the max date for each forecast and calculate MAE for each horizon */
proc sql;
    create table plot as
        select scan(_MODEL_, 1, '_') as Model
             , Horizon
             , mean(abs(error)) as MAE
        from (select _MODEL_, horizon, error
              from casuser.outfor2
              group by _MODEL_, horizon
              having date = max(date)
             )
        group by calculated model, horizon
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