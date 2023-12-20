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
$setglobal  WH_name         MET
$setglobal  DH_name         CPH
$setglobal  solve_mode      ITERATIVE
*$setglobal  solve_mode      UNIQUE
$setglobal  heat_price      19

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
$include    '../../data/wh-%WH_name%/generator-names.csv'
$offDelim
/;

SET F                   'Fuels'
/
$onDelim
$include    '../../data/common-data/fuel-names.csv'
$offDelim
/;

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


* ----- Parameter operations -----
C_f(T,G)                        = sum(F$GF(G,F), pi_f(T,F) + qc_f(T,F)*pi_q(F));
F_a(T,G)$(G_HR(G))              = 0 + 1$(pi_h(T) <= lambda_h(T));

* ----- Investment decision parameters ----- *
PARAMETER 
AF_g(G)                           'Generator Annuity factor (-)'
C_capex_g(G)                      'Generator Capital cost (EUR/MW)'   
C_opex_g(G)                       'Generator Fixed operational costs (EUR/MW)'
C_capacity_g(G)                   'Generator Capacity-related costs (EUR/MW)'
;

AF_g('HP_EHR')        = (0.04*(1.04**25))/((1.04**25)-1);
C_capex_g('HP_EHR')   = 0.71246*1e6;
C_opex_g('HP_EHR')    = 2127;
C_capacity_g(G)       = AF_g(G)*C_capex_g(G) + C_opex_g(G);

* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
obj                     'Cost of DH system (EUR)'
OPEX                   'Operational expenditure (EUR)'
CAPEX                   'Capital expenditure (EUR)'
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
eq_capex                    'Capital expenditure'
eq_opex                     'Operational expenditure'

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
                                                                        + sum((G_HR),    C_capacity_g(G_HR)    *Y_h(G_HR))

;

eq_opex..                                   OPEX                    =e= + sum((T,G),     C_f(T,G)   *x_f(T,G)) 
                                                                        + sum((T,G_CO),  C_c(G_CO)  *x_c(T,G_CO))
                                                                        + sum((T,G_HR),  C_h(G_HR)  *x_h(T,G_HR))
                                                                        - sum((T,G_HR),  pi_h(T)    *x_h(T,G_HR))
                                                                        
                                                                        + sum((G_HR),    C_opex_g(G_HR) *Y_h(G_HR))
                                                                        ;

eq_capex..                                  CAPEX                   =e= + sum((G_HR),    AF_g(G_HR)*C_capex_g(G_HR) *Y_h(G_HR));


eq_cold_balance(T)..                        sum(G, x_c(T,G))        =e= D(t);

eq_cold_maximum(T,G)$(G_CO(G))..            x_c(T,G)                =l= F_a(T,G)*Y_c(G);
eq_heat_maximum(T,G)$(G_HR(G))..            x_h(T,G)                =l= F_a(T,G)*Y_h(G);
eq_conversion_CO(T,G)..                     eta(T,G)*x_f(T,G)       =e= x_c(T,G);
eq_conversion_HR(T,G)$(G_HR(G))..           (eta(T,G)+1)*x_f(T,G)   =e= x_h(T,G);

* ======================================================================
* SOLVE, POST-PROCESSING, AND OUTPUTS
* ======================================================================
$ifi %solve_mode% == UNIQUE     $include WHS-unique.inc
$IFI %solve_mode% == ITERATIVE  $include WHS-iterative.inc

* ======================================================================
* END OF FILE