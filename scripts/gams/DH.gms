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
$setglobal  name            DH
$setglobal  heat_price      37
$setglobal  path_output     ../../results/%name%_%heat_price%.gdx

display "Name: %name%"
display "Output path: %path_output%"

* ======================================================================
*  Global scalars
* ======================================================================
$setGlobal EHR            YES

* ======================================================================
*  SETS
* ======================================================================
* ----- Set declaration -----
SET
T                       'Timesteps'
G                       'Generators' 
S                       'Storages'
F                       'Fuels'
GF(G,F)                 'Generator-fuel mapping'
SS                      'Storage states (SOS1 set)'  
;

* ----- Set definition -----
SET T                   'Timesteps' 
/T0001*T8760/
;

SET G                   'Generators'
/
$onDelim
$ifi NOT %EHR% == YES $include    '../../data/dh-generator-data/dh-generator-names.csv'
$ifi     %EHR% == YES $include    '../../data/dh-generator-data/dh_HR-generator-names.csv'
$offDelim
/;


SET S(*)                'Storages'
/
$onDelim
$include    '../../data/dh-storage-data/dh-storage-names.csv'
$offDelim
/
;

SET F                   'Fuels'
/
$onDelim
$include    '../../data/fuel-data/fuel-names.csv'
$offDelim
/;

SET GF(G,F)             'Generator-fuel mapping'
/
$onDelim
$ifi NOT %EHR% == YES $include    '../../data/dh-generator-data/dh-generator-fuels.csv'
$ifi     %EHR% == YES $include    '../../data/dh-generator-data/dh_HR-generator-fuels.csv'
$offDelim
/;

SET SS                   'Storage states (SOS1 set)'
/'charge', 'discharge'/
;

* ======================================================================
*  Auxiliary data loading (required after definition of sets, but before subsets)
* ======================================================================
ACRONYMS EX 'Extraction', BP 'Backpressure', HO 'Heat-only', HR 'Heat recovery';
ACRONYMS timeVar 'time-variable data'

SET GnrtAttrs(*)         'Auxiliary set to load generator data'
/
$onDelim
$include    '../../data/dh-generator-data/dh-generator-attributes.csv'
$offDelim
/;

SET FuelAttrs(*)        'Auxiliary set to load fuel data'
/
$onDelim
$include    '../../data/fuel-data/fuel-attributes.csv'
$offDelim
/;

SET StrgAttrs(*)        'Auxiliary set to load storage data'
/
$onDelim
$include    '../../data/dh-storage-data/dh-storage-attributes.csv'
$offDelim
/;

TABLE GNRT_DATA(G,GnrtAttrs)
$onDelim
$ifi NOT %EHR% == YES $include    '../../data/dh-generator-data/dh-generator-data.csv'
$ifi     %EHR% == YES $include    '../../data/dh-generator-data/dh_HR-generator-data.csv'
$offDelim
;

TABLE FUEL_DATA(F,FuelAttrs)
$onDelim
$include    '../../data/fuel-data/fuel-data.csv'
$offDelim
;

TABLE STRG_DATA(S,StrgAttrs)
$onDelim
$include    '../../data/dh-storage-data/dh-storage-data.csv'
$offDelim
;

* ======================================================================
* SUBSETS
* ======================================================================
* ----- Subset declaration -----
SETS
G_HO(G)                 'Heat-only generators'
G_HR(G)                 'Heat-recovery generators'
G_BP(G)                 'Backpressure generators'
G_EX(G)                 'Extraction generators'  
G_CHP(G)                'CHP generators'
G_DH(G)                 'DH generator'
;

* --- Subset definition ---
G_HO(G)    = YES$(GNRT_DATA(G,'TYPE') EQ HO);
G_HR(G)    = YES$(GNRT_DATA(G,'TYPE') EQ HR);
G_BP(G)    = YES$(GNRT_DATA(G,'TYPE') EQ BP);
G_EX(G)    = YES$(GNRT_DATA(G,'TYPE') EQ EX);

* ----- Subset operations -----
G_CHP(G)    = G_BP(G) + G_EX(G);
G_DH(G)     = G(G) - G_HR(G);


* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_e(G)                  'Cost of electricity production (EUR/MWh)'
C_f(T,G)                'Cost of fuel consumption (EUR/MWh)'

D(T)                    'Demand (MW)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_h(T)                 'Price of heat (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_co2(F)               'Price of carbon quota (EUR/kg)'
lambda_h(T)             ''
ehr_prod(T)            'EHR production (MWh)'

q_f(T,F)                'Carbon content of fuel (kg/MWh)'
q_e(T)                  'Carbon content of electricity (kg/MWh)'

Y_f(G)                  'Input capacity (MWh)'
R_f(G)                  'Input ramping rate (-)'
F_a(T,G)                'Availabity factor (-)'
eta(T,G)                'Generator efficiency (-)'
beta_b(G)               'Cb coefficient of CHPs (-)'
beta_v(G)               'Cv coefficient of CHPs (-)'

Y_s(S)                  'Storage capacity (MWh)'
F_s(S)                  'Storage throughput capacity factor (-)'  
F_SOC_end(S)            'Final storage state-of-charge factor (-)'
F_SOC_min(S)            'Minimum storage state-of-charge factor (-)'
F_SOC_max(S)            'Maximum storage state-of-charge factor (-)'
rho_s(S)                'Storage self-discharge factor (-)'
eta_s(S)                'Storage throughput efficiency (-)'
C_s(S)                  'Storage variable cost (EUR/MWh)'
;

* ----- Parameter definition -----
* - One-dimensional parameters -
PARAMETERS
D(T)
/
$onDelim
$include    '../../data/timeseries/ts-heat-demand.csv'
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

$ifi     %EHR% == YES ehr_prod(T)
$ifi     %EHR% == YES /
$ifi     %EHR% == YES $onDelim
$ifi     %EHR% == YES $include    '../../data/timeseries/ehr_output/ts-ehr_output-%heat_price%.csv'
$ifi     %EHR% == YES $offDelim
$ifi     %EHR% == YES /

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
$include    '../../data/timeseries/ts-availability.csv'
$offDelim
;

TABLE eta(T,G)
$onDelim
$include    '../../data/timeseries/ts-efficiency.csv'
$offDelim
;

* - Assigned parameters -
Y_f(G)                          = GNRT_DATA(G,'fuel capacity');
R_f(G)                          = GNRT_DATA(G,'ramping rate');
beta_b(G)$G_CHP(G)              = GNRT_DATA(G,'Cb');
beta_v(G)$G_EX(G)               = GNRT_DATA(G,'Cv');
C_h(G)$(G_HO(G))                = GNRT_DATA(G,'VOM_h');
C_e(G)$(G_CHP(G))               = GNRT_DATA(G,'VOM_e');

q_f(T,F)                        = FUEL_DATA(F,'carbon content');
pi_f(T,F)                       = FUEL_DATA(F,'fuel price');
pi_co2(F)                       = FUEL_DATA(F,'carbon price');

C_s(S)                          = STRG_DATA(S,'OMV');
Y_s(S)                          = STRG_DATA(S,'SOC capacity');
F_s(S)                          = STRG_DATA(S,'throughput ratio');
eta_s(S)                        = STRG_DATA(S,'throughput efficiency');
rho_s(S)                        = STRG_DATA(S,'self-discharge factor');
F_SOC_end(S)                    = STRG_DATA(S,'SOC ratio end');
F_SOC_min(S)                    = STRG_DATA(S,'SOC ratio min');
F_SOC_max(S)                    = STRG_DATA(S,'SOC ratio max');

* ----- Parameter operations -----
pi_f(T,'electricity')           = pi_e(T);
q_f(T,'electricity')            = q_e(T);
C_f(T,G)                        = sum(F$GF(G,F), pi_f(T,F) + q_f(T,F)*pi_co2(F));

*$ifi %EHR% == YES   pi_h(T)                         = lambda_h(T);
$ifi %EHR% == YES   pi_h(T)                         = %heat_price%;
* $ifi %EHR% == YES   F_a(T,'HP_EHR')$(pi_h(T) <= lambda_h(T)) = 1;
* $ifi %EHR% == YES   F_a(T,'HP_EHR')$(pi_h(T) > lambda_h(T)) = 0;
$ifi %EHR% == YES   eta(T,'HP_EHR')                  = 1;

* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
obj                     'Cost of DH system (EUR)'
;

POSITIVE VARIABLES
x_f(T,G)                'Consumption of fuel (MWh)'
x_h(T,G)                'Production of heat (MWh)'
x_e(T,G)                'Production of electricity (MWh)'
SOC(T,S)                'State-of-charge of storage (MWh)'
;

SOS1 VARIABLES
x_s(T,S,SS)             'Storage charge/discharge (MWh)'    
;

* ----- Variable attributes -----
$ifi %EHR% == YES   x_f.fx(T,'HP_EHR') = ehr_prod(T);
* ======================================================================
* EQUATIONS
* ======================================================================
* ----- Equation declaration -----
EQUATIONS
eq_obj                      'Objective function - Cost of DH system'
eq_heat_balance(T)          'Heat balance'

eq_fuel_maximum(T,G)        'Maximum fuel consumption'
eq_conversion_HO(T,G)       'Energy conversion for heat-only generators'
eq_conversion_HR(T,G)       'Energy conversion for heat-recovery generators'
eq_conversion_EX(T,G)       'Energy conversion for CHP generators'
eq_conversion_BP(T,G)       'Energy conversion for CHP generators'
eq_ramping_up(T,G)          'Ramping-up limit'
eq_ramping_down(T,G)        'Ramping-down limit'
eq_ratio_BP(T,G)            'Electricity-to-heat ratio for backpressure generators'
eq_ratio_EX(T,G)            'Electricity-to-heat ratio for extraction generators'

eq_storage_balance(T,S)     'Storage balance'
eq_storage_SOC_end(T,S)     'Storage initial state of charge'
eq_storage_SOC_min(T,S)     'Storage minimum state of charge'
eq_storage_SOC_max(T,S)     'Storage maximum state of charge'
eq_storage_flow_max(T,S,SS) 'Storage throughput limit'
;

* ----- Equation definition -----

* check this below
eq_obj..                                    obj                     =e= + sum((T,G_DH),  C_f(T,G_DH)    *x_f(T,G_DH)) 
                                                                        + sum((T,G_HO),  C_h(G_HO)      *x_h(T,G_HO))
                                                                        + sum((T,G_HR),  C_h(G_HR)      *x_h(T,G_HR))
                                                                        + sum((T,G_CHP), C_e(G_CHP)     *x_e(T,G_CHP))
                                                                        - sum((T,G_CHP), pi_e(T)        *x_e(T,G_CHP))
;

eq_heat_balance(T)..                        sum(G, x_h(T,G)) + sum(S, x_s(T,S,'discharge') - x_s(T,S,'charge')) =e= D(t);

eq_fuel_maximum(T,G)$(G_DH(G))..            x_f(T,G)                =l= F_a(T,G)*Y_f(G);
eq_conversion_HO(T,G)$(G_HO(G))..           eta(T,G)*x_f(T,G)       =e= x_h(T,G);
eq_conversion_HR(T,G)$(G_HR(G))..           eta(T,G)*x_f(T,G)       =e= x_h(T,G);
eq_conversion_EX(T,G)$(G_EX(G))..           eta(T,G)*x_f(T,G)       =e= x_e(T,G) + beta_v(G)*x_h(T,G);
eq_conversion_BP(T,G)$(G_BP(G))..           eta(T,G)*x_f(T,G)       =e= x_e(T,G) + x_h(T,G);
eq_ramping_up(T,G)$(G_DH(G))..              x_f(T++1,G) - x_f(T,G)  =l= R_f(G)*Y_f(G);
eq_ramping_down(T,G)$(G_DH(G))..            x_f(T,G) - x_f(T++1,G)  =l= R_f(G)*Y_f(G);
eq_ratio_BP(T,G)$G_BP(G)..                  x_e(T,G)                =e= beta_b(G)*x_h(T,G);
eq_ratio_EX(T,G)$G_EX(G)..                  x_e(T,G)                =g= beta_b(G)*x_h(T,G);

eq_storage_balance(T,S)..                   SOC(T,S)                =e= (1-rho_s(S))*SOC(T--1,S) + eta_s(S)*x_s(T,S,'charge') - x_s(T,S,'discharge')/eta_s(S);
eq_storage_SOC_end(T,S)$(ord(T)=card(T))..  SOC(T,S)                =e= F_SOC_end(S)*Y_s(S);
eq_storage_SOC_min(T,S)..                   SOC(T,S)                =g= F_SOC_min(S)*Y_s(S);
eq_storage_SOC_max(T,S)..                   SOC(T,S)                =l= F_SOC_max(S)*Y_s(S);
eq_storage_flow_max(T,S,SS)..               x_s(T,S,SS)             =l= F_s(S)*Y_s(S);

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
solve all_eqs using MIP minimizing obj;

* ======================================================================
* POST-PROCESSING
* ======================================================================
* PARAMETERS
* fuel_use(T,F)
* heat_share(G)       'Heat share (-)'
* fuel_share(F)
* ;

* heat_share(G) = sum(T, x_h.l(T,G))/sum(T, D(T));
* fuel_use(T,F) = sum(G$GF(G,F), x_f.l(T,G));
* fuel_sharE(F) = sum(T, fuel_use(T,F))/sum((T,G), x_f.l(T,G));

* ======================================================================
* REPORTING
* ======================================================================
display "Variable levels"
display obj.l;

* ======================================================================
* OUTPUT
* ======================================================================
* execute             'mkdir ..\..\results\%name%'
execute_unload      '%path_output%'

* ======================================================================
* END OF FILE
