* NOTES:

* ======================================================================
*  Options
* ======================================================================
$onEmpty
* option limrow = 50
* option limcol = 50

* ======================================================================
* Control flags
* ======================================================================
$setglobal  name            DC
$setglobal heat_price 37

* EHR not implemented yet
$setglobal EHR YES

$setglobal  path_output     ../../results/%name%_%heat_price%.gdx
$setglobal  path_put        ../../data/timeseries/ehr_output/ts-ehr_output-%heat_price%.csv

display "Name: %name%"
display "Output path: %path_output%"

* ======================================================================
*  Global scalars
* ======================================================================
* THIS IS NOT IMPLEMENTED YET


* ======================================================================
*  SETS
* ======================================================================
* ----- Set declaration -----
SET
T                       'Timesteps'
G                       'Generators' 
F                       'Fuels'
GF(G,F)                 'Generator-fuel mapping'
;

* ----- Set definition -----
SET T                   'Timesteps' 
/T0001*T8760/
;

SET G                   'Generators'
/
$onDelim
$include    '../../data/dc-generator-data/dc-generator-names.csv'
$offDelim
/;

SET F                   'Fuels'
/
$onDelim
$include    '../../data/fuel-data/fuel-names.csv'
$offDelim
/;

SET GF(G,F)             'Gnerator-fuel mapping'
/
$onDelim
$include    '../../data/dc-generator-data/dc-generator-fuels.csv'
$offDelim
/;

* ======================================================================
*  Auxiliary data loading (required after definition of sets, but before subsets)
* ======================================================================
ACRONYMS CO 'Cold-only', HR 'Heat recovery';
ACRONYMS timeVar 'time-variable data'

SET GnrtAttrs(*)         'Auxiliary set to load generator data'
/
$onDelim
$include    '../../data/dc-generator-data/dc-generator-attributes.csv'
$offDelim
/;

SET FuelAttrs(*)        'Auxiliary set to load fuel data'
/
$onDelim
$include    '../../data/fuel-data/fuel-attributes.csv'
$offDelim
/;

TABLE GNRT_DATA(G,GnrtAttrs)
$onDelim
$include    '../../data/dc-generator-data/dc-generator-data.csv'
$offDelim
;

TABLE FUEL_DATA(F,FuelAttrs)
$onDelim
$include    '../../data/fuel-data/fuel-data.csv'
$offDelim
;

* ======================================================================
* SUBSETS
* ======================================================================
* ----- Subset declaration -----
SETS
G_CO(G)                 'Cold-only generators'
G_HR(G)                 'Heat-recovery generators'
;

* --- Subset definition ---
G_CO(G)    = YES$(GNRT_DATA(G,'TYPE') EQ CO);
G_HR(G)    = YES$(GNRT_DATA(G,'TYPE') EQ HR);

* ----- Subset operations -----


* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_c(G)                  'Cost of cold production (EUR/MWh)'
C_f(T,G)                'Cost of fuel consumption (EUR/MWh)'

D(T)                    'Demand (MW)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_h(T)                 'Price of heat (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_co2(F)               'Price of carbon quota (EUR/kg)'
lambda_h(T)             'Marginal cost of heat (EUR/MWh)'    

q_f(T,F)                'Carbon content of fuel (kg/MWh)'
q_e(T)                  'Carbon content of electricity (kg/MWh)'

Y_c(G)                  'Cold capacity (MWh)'
R_f(G)                  'Input ramping rate (-)'
F_a(T,G)                'Availabity factor (-)'
eta(T,G)                'Generator efficiency (-)'
;

* ----- Parameter definition -----
* - One-dimensional parameters -
PARAMETERS
D(T)
/
$onDelim
$include    '../../data/timeseries/ts-cold-demand.csv'
$offDelim
/

pi_e(T)
/
$onDelim
$include    '../../data/timeseries/ts-electricity-price.csv'
$offDelim
/

lambda_h(T)
/
$onDelim
$include    '../../data/timeseries/ts-heat-marginal-cost.csv'
$offDelim
/

q_e(T)
/
$onDelim
$include    '../../data/timeseries/ts-electricity-carbon.csv'
$offDelim
/
;

* - Multi-dimensional parameters -
TABLE F_a(T,G)
$onDelim
$include    '../../data/timeseries/ts-availability-cold.csv'
$offDelim
;

TABLE eta(T,G)
$onDelim
$include    '../../data/timeseries/ts-efficiency-cold.csv'
$offDelim
;

* - Assigned parameters -
Y_c(G)$(G_CO(G))                = GNRT_DATA(G,'cold capacity');
C_h(G)$(G_HR(G))                = GNRT_DATA(G,'VOM_h');
C_c(G)$(G_CO(G))                = GNRT_DATA(G,'VOM_c');

q_f(T,F)                        = FUEL_DATA(F,'carbon content');
pi_f(T,F)                       = FUEL_DATA(F,'fuel price');
pi_co2(F)                       = FUEL_DATA(F,'carbon price');

pi_h(T)                         = %heat_price%;
*pi_h(T)                         = lambda_h(T);

* ----- Parameter operations -----
pi_f(T,'electricity')           = pi_e(T);
q_f(T,'electricity')            = q_e(T);
C_f(T,G)                        = sum(F$GF(G,F), pi_f(T,F) + q_f(T,F)*pi_co2(F));

F_a(T,'HP_EHR')$(pi_h(T) <= lambda_h(T)) = 1;
F_a(T,'HP_EHR')$(pi_h(T) > lambda_h(T)) = 0;

PARAMETER 
AF(G)                           'Annuity factor (-)'
C_capex(G)                      'Capital cost (EUR/MW)'   
C_opex(G)
C_capacity(G)
;

* i=4%, n=25
AF('HP_EHR')    = 0.064;
C_capex('HP_EHR') = 0.71245972106*1000000;
C_opex('HP_EHR') = 2126.745436;
C_capacity(G) = C_capex(G)*AF(G) + C_opex(G);

* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
obj                     'Cost of DH system (EUR)'
;

POSITIVE VARIABLES
Y_h(G)                  'Heat capacity (MWh)'
x_f(T,G)                'Consumption of fuel (MWh)'
x_h(T,G)                'Production of heat (MWh)'
x_c(T,G)                'Production of cold (MWh)'
;

* ----- Variable attributes -----

* ======================================================================
* EQUATIONS
* ======================================================================
* ----- Equation declaration -----
EQUATIONS
eq_obj                      'Objective function - Cost of DH system'
eq_cold_balance(T)          'Cold balance'

eq_cold_maximum(T,G)        'Maximum cold production'
eq_heat_maximum(T,G)        'Maximum heat production'
eq_conversion_CO(T,G)       'Energy conversion for heat-only generators'
eq_conversion_HR(T,G)       'Energy conversion for heat-recovery generators'
;

* ----- Equation definition -----

* check this below
eq_obj..                                    obj                     =e= + sum((T,G),     C_f(T,G)   *x_f(T,G)) 
                                                                        + sum((T,G_CO),  C_c(G_CO)  *x_c(T,G_CO))
                                                                        + sum((T,G_HR),  C_h(G_HR)  *x_h(T,G_HR))
                                                                        - sum((T,G_HR),  pi_h(T)    *x_h(T,G_HR))
                                                                        + sum((G_HR),    C_capacity(G_HR)    *Y_h(G_HR))

;

eq_cold_balance(T)..                        sum(G, x_c(T,G))        =e= D(t);

eq_cold_maximum(T,G)$(G_CO(G))..            x_c(T,G)                =l= F_a(T,G)*Y_c(G);
eq_heat_maximum(T,G)$(G_HR(G))..            x_h(T,G)                =l= F_a(T,G)*Y_h(G);
eq_conversion_CO(T,G)..                     eta(T,G)*x_f(T,G)       =e= x_c(T,G);
eq_conversion_HR(T,G)$(G_HR(G))..           (eta(T,G)+1)*x_f(T,G)   =e= x_h(T,G);

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
SET VARS /'pi_h', 'obj', 'Y_h', 'HP_cold_share'/;
SET ITER /I00*I38/;

PARAMETERS
logResults(ITER,VARS) 'Log results'
;



loop(ITER,

    pi_h(T) = (ord(ITER)-1)$(ord(ITER)<>1) + lambda_h(T)$(ord(ITER)=1);
    F_a(T,'HP_EHR')$(pi_h(T) <= lambda_h(T)) = 1;
    F_a(T,'HP_EHR')$(pi_h(T) > lambda_h(T)) = 0;

    solve all_eqs using LP minimizing obj;

    logResults(ITER,'pi_h') = ord(ITER)-1;
    logResults(ITER,'obj') = obj.l;
    logResults(ITER,'Y_h') = Y_h.l('HP_EHR');
    logResults(ITER,'HP_cold_share') = sum(T, x_c.l(T,'HP_EHR'))/sum(T, D(T));
);

execute_unload      '../../results/%name%_logResults.gdx'

* ======================================================================
* POST-PROCESSING
* ======================================================================
$ontext
* ======================================================================
* REPORTING
* ======================================================================
display "Variable levels"
display obj.l;
display Y_h.l;

* ======================================================================
* OUTPUT
* ======================================================================
* execute             'mkdir ..\..\results\%name%'
execute_unload      '%path_output%'
file fx / '%path_put%' /; 
put fx;

loop(T,
    put T.tl:0, ",", x_h.l(T,'HP_EHR'):0:6 /;  
);
putclose fx;

* ======================================================================
* END OF FILE
$offtext