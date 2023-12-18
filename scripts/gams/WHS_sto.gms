* NOTES:

* ======================================================================
*  Options
* ======================================================================
$onEmpty
option optcr = 0.0001
* option limrow = 50
* option limcol = 50

* ======================================================================
* Control flags
* ======================================================================
$setglobal  WH_name         DC_S
$setglobal  DH_name         CPH
* $setglobal  solve_mode      ITERATIVE
$setglobal  solve_mode      UNIQUE
$setglobal  heat_price      25

$setglobal  dir_out         ..\..\results\%DH_name%\%WH_name%

display "WH name: %WH_name%"
display "Output path: %path_output%"

* ======================================================================
*  Global scalars
* ======================================================================


* ======================================================================
*  SETS
* ======================================================================
* ----- Set declaration -----
SET
T                       'Timesteps'
G                       'Generators' 
S                       'Storages'
F                       'Fuels'
SS                      'Storage state (SOS1 set)'  
GF(G,F)                 'Generator-fuel mapping'
;

* ----- Set definition -----
SET T                   'Timesteps' 
/T0001*T8760/
;

SET G                   'Generators'
/
$onDelim
$include    '../../data/wh-%WH_name%/generator-names.csv'
$offDelim
/;

SET S(*)                'Storages'
/
$onDelim
$include    '../../data/wh-%WH_name%/storage-names.csv'
$offDelim
/;

SET F                   'Fuels'
/
$onDelim
$include    '../../data/common-data/fuel-names.csv'
$offDelim
/;

SET SS                   'Storage states (SOS1 set)'
/'charge', 'discharge'/
;

SET GF(G,F)             'Gnerator-fuel mapping'
/
$onDelim
$include    '../../data/wh-%WH_name%/generator-fuels.csv'
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
$include    '../../data/common-data/attributes-dc-generator.csv'
$offDelim
/;

SET StrgAttrs(*)        'Auxiliary set to load storage data'
/
$onDelim
$include    '../../data/common-data/attributes-dh-storage.csv'
$offDelim
/;

SET FuelAttrs(*)        'Auxiliary set to load fuel data'
/
$onDelim
$include    '../../data/common-data/attributes-fuel.csv'
$offDelim
/;

TABLE GNRT_DATA(G,GnrtAttrs)
$onDelim
$include    '../../data/wh-%WH_name%/generator-data.csv'
$offDelim
;

TABLE STRG_DATA(S,StrgAttrs)
$onDelim
$include    '../../data/wh-%WH_name%/storage-data.csv'
$offDelim
;

TABLE FUEL_DATA(F,FuelAttrs)
$onDelim
$include    '../../data/common-data/fuel-data.csv'
$offDelim
;

* ======================================================================
* SUBSETS
* ======================================================================
* ----- Subset declaration -----
SETS
G_CO(G)                 'Cold-only generators'
G_HR(G)                 'Heat-recovery generators'
F_EL(F)                 'Electricity fuel'
;

* --- Subset definition ---
G_CO(G)     = YES$(GNRT_DATA(G,'TYPE') EQ CO);
G_HR(G)     = YES$(GNRT_DATA(G,'TYPE') EQ HR);
F_EL(F)     = YES$(sameas(F,'electricity'));

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
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_q(F)                 'Price of carbon quota (EUR/kg)'

pi_h(T)                 'Price of heat (EUR/MWh)'
lambda_h(T)             'Marginal cost of heat (EUR/MWh)'    

qc_f(T,F)               'Carbon content of fuel (kg/MWh)'
qc_e(T)                 'Carbon content of electricity (kg/MWh)'

Y_c(G)                  'Cold capacity (MWh)'
R_f(G)                  'Input ramping rate (-)'
F_a(T,G)                'Availabity factor (-)'
eta(T,G)                'Generator efficiency (-)'

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
$include    '../../data/wh-%WH_name%/ts-demand-cold.csv'
$offDelim
/

pi_e(T)
/
$onDelim
$include    '../../data/wh-%WH_name%/ts-electricity-price.csv'
$offDelim
/

lambda_h(T)
/
$onDelim
$include    '../../results/%DH_name%/ts-MC_DH-%DH_name%.csv'
$offDelim
/

qc_e(T)
/
$onDelim
$include    '../../data/wh-%WH_name%/ts-electricity-carbon.csv'
$offDelim
/
;

* - Multi-dimensional parameters -
TABLE F_a(T,G)
$onDelim
$include    '../../data/wh-%WH_name%/ts-generator-availability.csv'
$offDelim
;

TABLE eta(T,G)
$onDelim
$include    '../../data/wh-%WH_name%/ts-generator-efficiency.csv'
$offDelim
;

* - Assigned parameters -
Y_c(G)$(G_CO(G))                = GNRT_DATA(G,'cold capacity');
C_h(G)$(G_HR(G))                = GNRT_DATA(G,'VOM_h');
C_c(G)$(G_CO(G))                = GNRT_DATA(G,'VOM_c');

pi_h(T)                         = %heat_price%;
pi_q(F)                         = FUEL_DATA(F,'carbon price');
pi_f(T,F)                       = FUEL_DATA(F,'fuel price')$(NOT F_EL(F))       + pi_e(T)$(F_EL(F));
qc_f(T,F)                       = FUEL_DATA(F,'carbon content')$(NOT F_EL(F))   + qc_e(T)$(F_EL(F));

C_s(S)                          = STRG_DATA(S,'OMV');
Y_s(S)                          = STRG_DATA(S,'SOC capacity');
F_s(S)                          = STRG_DATA(S,'throughput ratio');
eta_s(S)                        = STRG_DATA(S,'throughput efficiency');
rho_s(S)                        = STRG_DATA(S,'self-discharge factor');
F_SOC_end(S)                    = STRG_DATA(S,'SOC ratio end');
F_SOC_min(S)                    = STRG_DATA(S,'SOC ratio min');
F_SOC_max(S)                    = STRG_DATA(S,'SOC ratio max');

* ----- Parameter operations -----
C_f(T,G)                        = sum(F$GF(G,F), pi_f(T,F) + qc_f(T,F)*pi_q(F));
F_a(T,G)$(G_HR(G))              = 0 + 1$(pi_h(T) <= lambda_h(T));

PARAMETER 
AF(G)                           'Annuity factor (-)'
C_capex(G)                      'Capital cost (EUR/MW)'   
C_opex(G)
C_capacity(G)
;

* i=4%, n=25
AF('HP_EHR')        = 0.064;
C_capex('HP_EHR')   = 0.71245972106*1000000;
C_opex('HP_EHR')    = 2126.745436;
C_capacity(G)       = C_capex(G)*AF(G) + C_opex(G);

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
SOC(T,S)                'State-of-charge of storage (MWh)'
;

SOS1 VARIABLES
x_s(T,S,SS)             'Storage charge/discharge (MWh)'    
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

eq_storage_balance(T,S)     'Storage balance'
eq_storage_SOC_end(T,S)     'Storage initial state of charge'
eq_storage_SOC_min(T,S)     'Storage minimum state of charge'
eq_storage_SOC_max(T,S)     'Storage maximum state of charge'
eq_storage_flow_max(T,S,SS) 'Storage throughput limit'
;

* ----- Equation definition -----

* check this below
eq_obj..                                    obj                     =e= + sum((T,G),     C_f(T,G)   *x_f(T,G)) 
                                                                        + sum((T,G_CO),  C_c(G_CO)  *x_c(T,G_CO))
                                                                        + sum((T,G_HR),  C_h(G_HR)  *x_h(T,G_HR))
                                                                        - sum((T,G_HR),  pi_h(T)    *x_h(T,G_HR))
                                                                        + sum((G_HR),    C_capacity(G_HR)    *Y_h(G_HR))

;

eq_cold_balance(T)..                        sum(G, x_c(T,G)) + sum(S, x_s(T,S,'discharge') - x_s(T,S,'charge')) =e= D(t);

eq_cold_maximum(T,G)$(G_CO(G))..            x_c(T,G)                =l= F_a(T,G)*Y_c(G);
eq_heat_maximum(T,G)$(G_HR(G))..            x_h(T,G)                =l= F_a(T,G)*Y_h(G);
eq_conversion_CO(T,G)..                     eta(T,G)*x_f(T,G)       =e= x_c(T,G);
eq_conversion_HR(T,G)$(G_HR(G))..           (eta(T,G)+1)*x_f(T,G)   =e= x_h(T,G);

eq_storage_balance(T,S)..                   SOC(T,S)                =e= (1-rho_s(S))*SOC(T--1,S) + eta_s(S)*x_s(T,S,'charge') - x_s(T,S,'discharge')/eta_s(S);
eq_storage_SOC_end(T,S)$(ord(T)=card(T))..  SOC(T,S)                =e= F_SOC_end(S)*Y_s(S);
eq_storage_SOC_min(T,S)..                   SOC(T,S)                =g= F_SOC_min(S)*Y_s(S);
eq_storage_SOC_max(T,S)..                   SOC(T,S)                =l= F_SOC_max(S)*Y_s(S);
eq_storage_flow_max(T,S,SS)..               x_s(T,S,SS)             =l= F_s(S)*Y_s(S);

* ======================================================================
* SOLVE, POST-PROCESSING, AND OUTPUTS
* ======================================================================
$ifi %solve_mode% == UNIQUE     $include WHS-unique.inc
$IFI %solve_mode% == ITERATIVE  $include WHS-iterative.inc

* ======================================================================
* END OF FILE