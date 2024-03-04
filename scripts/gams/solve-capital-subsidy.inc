* NOTES:
* This script uses the GAMS's "Grid and Multi-Threading Solve Facility" to solve the different support levels in parallel.
* https://www.gams.com/latest/docs/UG_GridComputing.html

SETS
I                       'Number of iterations'
/I00*I10/
RSET                    'Report set'
/'Support', 'NPV', 'Heat capacity', 'Heat recovered' , 'DH cost'/
;   

SCALARS
MinSupport              'Minimum support level - fraction of investment'    /0/
MaxSupport              'Maximum support level - fraction of investment'    /1/
WallTime                'Wall time limit (s)'                               /300/
;

PARAMETERS
SupportLevel(I)         'Support level'
HeatRecovered(T,G,I)    'Waste heat recovery'
summary(I,RSET)         'Summary report'
handle_wh(I)            'Handle for the WH model'
handle_dh(I)            'Handle for the DH model'
;


SupportLevel(I) = MinSupport + (MaxSupport - MinSupport)/(card(I)-1)*(ord(I)-1);

* ----- Submission of the integrated WH model ----- *
mdl_WH_int.solvelink = 3;
loop(I,
    P_inv       = SupportLevel(I);
    solve mdl_WH_int using LP maximizing NPV;
    handle_wh(I)   = mdl_WH_int.handle;
);

* ----- Retrieving results from the integrated WH model -----
repeat
   loop(I$handle_wh(I),
      if(handleStatus(handle_wh(I)) = 2,
         mdl_WH_int.handle = handle_wh(I);
         execute_loadhandle mdl_WH_int;
         HeatRecovered(T,G_HR,I)       = x_hr.l(T,G_HR);
         
         summary(I,'Support')          = SupportLevel(I);
         summary(I,'NPV')              = NPV.l;
         summary(I,'Heat capacity')    = sum(G_HR,Y_hr.l(G_HR));
         summary(I,'Heat recovered')   = sum((T,G_HR), HeatRecovered(T,G_HR,I));
         
         if(summary(I,'Heat capacity') > 0,
            put_utility 'gdxout' / '%OutDir%/WH_' I.tl;
            execute_unload NPV, OPX_WH_int, x_f_wh, x_c, x_hr, Y_hr, w_q_wh;
         );

         display$handleDelete(handle_wh(I)) 'trouble deleting handles' ;
         handle_wh(I) = 0; 
      ); 
   ) ;
   display$readyCollect(handle_wh, WallTime) 'Problem waiting for next instance to complete';
until card(handle_wh) = 0 or timeelapsed > WallTime;

* ----- Submission of the integrated DH model ----- *
* Note: DH models are submitted only if investments in heat recovery capacity are positive.
*       Otherwise, DH operations do not change compared to the reference case.
mdl_DH_int.solvelink = 3;
loop(I$(summary(I,'Heat capacity') > 0),
    x_hr.fx(T,G_HR)        = HeatRecovered(T,G_HR,I);
    solve mdl_DH_int using LP minimizing OPX_DH_int;
    handle_dh(I) = mdl_DH_int.handle;
);

* ----- Retrieving results from the integrated DH model -----
repeat
   loop(I$handle_dh(I),
      if(handleStatus(handle_dh(I)) = 2,
         mdl_DH_int.handle = handle_dh(I);
         execute_loadhandle mdl_DH_int;

         summary(I,'DH cost')           = OPX_DH_int.l;

         put_utility 'gdxin' / '%OutDir%/WH_' I.tl;
         execute_load NPV, OPX_WH_int, x_f_wh, x_c, x_hr, Y_hr, w_q_wh;

*         put_utility 'gdxout' / '%OutDir%/DH_' I.tl;
*         execute_unload OPX_DH_int, x_f_dh, x_h, x_e, x_hr, w_q_dh;

         put_utility 'gdxout' / '%OutDir%/output_' I.tl;
         execute_unload NPV, OPX_WH_int, x_f_wh, x_c, x_hr, Y_hr, w_q_wh, OPX_DH_int, x_f_dh, x_h, x_e, x_hr, w_q_dh;

         display$handleDelete(handle_dh(I)) 'trouble deleting handles' ;
         handle_dh(I) = 0; 
      ); 
   ) ;
   display$readyCollect(handle_dh, WallTime) 'Problem waiting for next instance to complete';
until card(handle_dh) = 0 or timeelapsed > WallTime;

* ----- Unload summary results -----
execute_unload '%OutDir%/summary.gdx' summary;

execute 'rm -f %OutDir%/WH_*.gdx';



* $include './scripts/gams/paybacktime.inc'
