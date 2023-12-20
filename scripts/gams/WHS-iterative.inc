* NOTES:
* - This file solves the WHS model for an array of values for the heat price (pi_h)

* ======================================================================
* MODEL
* ======================================================================
* ----- Model definition -----
model
all_eqs             'All equations'
/all/
;

all_eqs.optfile = 1;

* ======================================================================
* SOLVE
* ======================================================================
ACRONYMS MC_HR      'Marginal cost of heat recovery';
SETS
KPI                 'Output indicator'
/'pi_h', 'obj', 'CAPEX', 'OPEX', 'Cap: HP', 'Cap: PCM', 'Cap: WT', 'cold_share', 'NPV', 'PBT'/
IDX                 'Iteration number'
/00*30/
;

PARAMETERS
logResults(IDX, KPI)    'Log of results'
lambda_HR(T)            'Marginal cost of heat recovery'   
;

lambda_HR(T)            = C_h('HP_EHR') + C_f(T,'HP_EHR')/(eta(T,'HP_EHR')+1);

loop(IDX,
    pi_h(T)                                 = (ord(IDX)-1)$(ord(IDX)<>1) + lambda_HR(T)$(ord(IDX)=1);
    F_a(T,G)$(G_HR(G))                      = 0 + 1$(pi_h(T) <= lambda_h(T));

    solve all_eqs using mip minimizing obj;

    logResults(IDX, 'pi_h')$(ord(IDX)=1)    = MC_HR;
    logResults(IDX, 'pi_h')$(ord(IDX)<>1)   = EPS + ord(IDX)-1;
    logResults(IDX, 'obj')                  = EPS + obj.l;
    logResults(IDX, 'CAPEX')                = EPS + CAPEX.l;
    logResults(IDX, 'OPEX')                 = EPS + OPEX.l;
    logResults(IDX, 'Cap: HP')              = EPS + Y_h.l('HP_EHR');
* put switch to storage hee, or include an all encompasing set to all techs
*    logResults(IDX, 'Cap: PCM')             = EPS + Y_s.l('PCM');
*    logResults(IDX, 'Cap: WT')              = EPS + Y_s.l('WT');
    logResults(IDX, 'cold_share')           = EPS + sum((G_HR(G),T), x_c.l(T, G_HR)) / sum((G,T), x_c.l(T, G));
    logResults(IDX, 'NPV')                  = EPS - CAPEX.l + (logResults('00','OPEX') - OPEX.l)/AF_g('HP_EHR');
    logResults(IDX, 'PBT')                  = EPS + CAPEX.l/((logResults('00','OPEX') - OPEX.l) + 0.000001)
* fix this AF_g above!!
);

* ======================================================================
* REPORTING
* ======================================================================
display logResults;

* ======================================================================
* OUTPUT
* ======================================================================
execute             'mkdir %dir_out%'
execute_unload      '%dir_out%\logResults.gdx' logResults

* ======================================================================
* END OF FILE