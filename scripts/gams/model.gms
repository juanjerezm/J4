* ======================================================================
* DESCRIPTION:
* ======================================================================


* ----- NOTES -----
* - Tariff values are placeholders. They should be replaced with actual values.

* ======================================================================
*  SETUP:
* ======================================================================
* ----- Options -----
$onEmpty
$Offlisting
$Offsymlist
$Offinclude

option limrow = 0
option limcol = 0
option EpsToZero = on

* ----- Control flags -----
$SetGlobal portfolio      'test'
$SetGlobal scenario       'capital-subsidy'
$SetGlobal whr            'yes'

* ----- Directories and filenames -----
* Creates directories for output and transfer files
$ifi %system.filesys% == msnt   $SetGlobal outDir   '.\results\%portfolio%\%scenario%\'
$ifi %system.filesys% == unix   $SetGlobal outDir   './results/%portfolio%/%scenario%/'
$ifi %system.filesys% == msnt   $SetGlobal transDir '%outDir%\transDir\'
$ifi %system.filesys% == unix   $SetGlobal transDir '%outDir%/transDir/'
execute                 'mkdir %outDir%';
execute                 'mkdir %transDir%';


* ----- Global scalars -----
SCALAR
M3                      'Thousand multiplier'   /1E3/


* ======================================================================
*  SETS
* ======================================================================
* ----- Set declaration -----
SET
T                       'Timesteps'
*SS                      'Storage state (SOS1 set)'  
U                       'Units'
G(U)                    'Generators' 
* S(U)                    'Storages'
F                       'Fuels'
GF(G,F)                 'Generator-fuel mapping'
;

* ----- Set definition -----
SET T                   'Timesteps' 
/T0001*T8760/
;

* SET SS                  'Storage states (SOS1 set)'
* /'charge', 'discharge'/
* ;
* 

SET U                   'Units'
/
$onDelim
$include    './data/common/name-unit.csv'
$offDelim
/;

SET G(U)                'Generators'
/
$onDelim
$include    './data/common/name-generator.csv'
$offDelim
/;

* SET S(U)                'Storages'
* /
* $onDelim
* $include    './data/common/name-storage.csv'
* $offDelim
* /;

SET F                   'Fuels'
/
$onDelim
$include    './data/common/name-fuel.csv'
$offDelim
/;


SET GF(G,F)             'Generator-fuel mapping'
/
$onDelim
$include    './data/common/map-generator-fuel.csv'
$offDelim
/;

* ======================================================================
*  Auxiliary data loading (required after definition of sets, but before subsets)
* ======================================================================
* --- Define acronyms ---
ACRONYMS EX 'Extraction', BP 'Backpressure', HO 'Heat-only', HR 'Heat recovery', CO 'Cold-only';
ACRONYMS DH 'District heating network', WH 'Waste heat source';
ACRONYMS timeVar 'time-variable data';

* --- Load data attributes ---
SET GnrtAttrs(*)        'Auxiliary set to load generator data'
/
$onDelim
$include    './data/common/attribute-generator.csv'
$offDelim
/;

* SET StrgAttrs(*)        'Auxiliary set to load storage data'
* /
* $onDelim
* $include    './data/common/attribute-storage.csv'
* $offDelim
* /;

SET FuelAttrs(*)        'Auxiliary set to load fuel data'
/
$onDelim
$include    './data/common/attribute-fuel.csv'
$offDelim
/;

* --- Load data values --- *
TABLE GNRT_DATA(G,GnrtAttrs)    'Generator data'
$onDelim
$include    './data/common/data-generator.csv'
$offDelim
;

* TABLE STRG_DATA(S,StrgAttrs)    'Storage data'
* $onDelim
* $include    '../../data/common/data-storage.csv'
* $offDelim
* ;

TABLE FUEL_DATA(F,FuelAttrs)    'Fuel data'
$onDelim
$include    './data/common/data-fuel.csv'
$offDelim
;

* ======================================================================
* SUBSETS
* ======================================================================
* ----- Subset declaration -----
SETS
G_BP(G)                 'Backpressure generators'
G_EX(G)                 'Extraction generators'  
G_HO(G)                 'Heat-only generators'
G_CO(G)                 'Cold-only generators'
G_HR(G)                 'Heat-recovery generators'
G_CHP(G)                'CHP generators'
G_DH(G)                 'DH generator'
G_WH(G)                 'WH generator'
F_EL(F)                 'Electricity fuel'

* S_DH(S)
* S_WH(S)
;

* --- Subset definition ---
G_BP(G)     = YES$(GNRT_DATA(G,'TYPE') EQ BP);
G_EX(G)     = YES$(GNRT_DATA(G,'TYPE') EQ EX);
G_HO(G)     = YES$(GNRT_DATA(G,'TYPE') EQ HO);
G_CO(G)     = YES$(GNRT_DATA(G,'TYPE') EQ CO);
G_HR(G)     = YES$(GNRT_DATA(G,'TYPE') EQ HR);

G_CHP(G)    = YES$(G_BP(G) OR G_EX(G));
G_DH(G)     = YES$(G_HO(G) OR G_CHP(G));
G_WH(G)     = YES$(G_CO(G) OR G_HR(G));

* S_DH(S)     = YES$(STRG_DATA(S,'TYPE') EQ DH);
* S_WH(S)     = YES$(STRG_DATA(S,'TYPE') EQ WH); 

F_EL(F)     = YES$(sameas(F,'electricity'));

* ----- Subset operations -----


* ======================================================================
* SCALARS
* ======================================================================
SCALARS
lifetime                'Lifetime of the project (years)'
dis_rate                'Discount rate (-)'
AF                      'Annuity factor (-)'
;

lifetime                = 25;
dis_rate                = 0.04;
AF                      = dis_rate*(1+dis_rate)**lifetime/((1+dis_rate)**lifetime-1);

* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_c(G)                  'Cost of cold production (EUR/MWh)'
C_e(G)                  'Cost of electricity production (EUR/MWh)'
C_f(T,G)                'Cost of fuel consumption (EUR/MWh)'
C_fix(G)                'Fixed cost of generator (EUR/MW)'
C_inv(G)                'Investment cost of generator (EUR/MW)'

D_h(T)                  'Demand of heat (MW)'
D_c(T)                  'Demand of cold (MW)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_q(F)                 'Price of carbon quota (EUR/kg)'
tau_f(F)                'Fuel taxes and tariffs (EUR/MWh)'

qc_e(T)                  'Carbon content of electricity (kg/MWh)'
qc_f(T,F)                'Carbon content of fuel (kg/MWh)'

Y_c(G)                  'Cold output capacity (MWh)'
Y_h(G)                  'Heat output capacity (MWh)'
Y_e(G)                  'Electricity output capacity (MWh)' 
R_f(G)                  'Input ramping rate (-)'
F_a(T,G)                'Generator availabity factor (-)'
eta(T,G)                'Generator efficiency (-)'
beta_b(G)               'Cb coefficient of CHPs (-)'
beta_v(G)               'Cv coefficient of CHPs (-)'

* Y_s(S)                  'Storage capacity (MWh)'
* F_s(S)                  'Storage throughput capacity factor (-)'  
* F_SOC_end(S)            'Final storage state-of-charge factor (-)'
* F_SOC_min(S)            'Minimum storage state-of-charge factor (-)'
* F_SOC_max(S)            'Maximum storage state-of-charge factor (-)'
* rho_s(S)                'Storage self-discharge factor (-)'
* eta_s(S)                'Storage throughput efficiency (-)'
* C_s(S)                  'Storage variable cost (EUR/MWh)'
;

* ----- Parameter definition -----
* - One-dimensional parameters -
$offlisting
PARAMETERS
D_h(T)
/
$onDelim
$include    './data/common/ts-demand-heat.csv'
$offDelim
/

D_c(T)
/
$onDelim
$include    './data/common/ts-demand-cold.csv'
$offDelim
/

pi_e(T)
/
$onDelim
$include    './data/common/ts-electricity-price.csv'
$offDelim
/

qc_e(T)
/
$onDelim
$include    './data/common/ts-electricity-carbon.csv'
$offDelim
/

Y_h(G)
/
$onDelim
$include    './data/portfolios/portfolio-%portfolio%.csv'
$offDelim
/
;

* - Multi-dimensional parameters -
TABLE F_a(T,G)
$onDelim
$include    './data/common/ts-generator-availability.csv'
$offDelim
;

TABLE eta(T,G)
$onDelim
$include    './data/common/ts-generator-efficiency.csv'
$offDelim
;

* - Assigned parameters -
C_e(G)$(G_CHP(G))               = GNRT_DATA(G,'variable cost - electricity');
C_h(G)$(G_HO(G))                = GNRT_DATA(G,'variable cost - heat');
C_h(G)$(G_HR(G))                = GNRT_DATA(G,'variable cost - heat');
C_c(G)$(G_CO(G))                = GNRT_DATA(G,'variable cost - cold');
C_inv(G)$(G_HR(G))              = GNRT_DATA(G,'capital cost');
C_fix(G)$(G_HR(G))              = GNRT_DATA(G,'fixed cost');

pi_f(T,F)                       = FUEL_DATA(F,'fuel price')$(NOT F_EL(F))       + pi_e(T)$(F_EL(F));
pi_q(F)                         = FUEL_DATA(F,'carbon price');
qc_f(T,F)                       = FUEL_DATA(F,'carbon content')$(NOT F_EL(F))   + qc_e(T)$(F_EL(F));
tau_f(F)                        = FUEL_DATA(G,'fuel tax') + FUEL_DATA(G,'fuel tariff');
R_f(G)                          = GNRT_DATA(G,'ramping rate');
beta_b(G)$G_CHP(G)              = GNRT_DATA(G,'Cb');
beta_v(G)$G_EX(G)               = GNRT_DATA(G,'Cv');


* C_s(S)                          = STRG_DATA(S,'OMV');
* Y_s(S)                          = STRG_DATA(S,'SOC capacity');
* F_s(S)                          = STRG_DATA(S,'throughput ratio');
* eta_s(S)                        = STRG_DATA(S,'throughput efficiency');
* rho_s(S)                        = STRG_DATA(S,'self-discharge factor');
* F_SOC_end(S)                    = STRG_DATA(S,'SOC ratio end');
* F_SOC_min(S)                    = STRG_DATA(S,'SOC ratio min');
* F_SOC_max(S)                    = STRG_DATA(S,'SOC ratio max');

* ----- Parameter operations -----
* Line below: defines generation capacity as ratio of peak demand.
Y_h(G)                          = Y_h(G)*smax(T, D_h(T));   
Y_c(G_CO)                       = 1     *smax(T, D_c(T));
* Line below: required for extraction units, backpressure units already constrained.
Y_e(G)$G_EX(G)                  = Y_h(G)*(beta_b(G) + beta_v(G));
*  Calculate fuel cost from fuel price, carbon quota, and taxes/tariffs
C_f(T,G)                        = sum(F$GF(G,F), pi_f(T,F) + qc_f(T,F)*pi_q(F) + tau_f(G));

* Loads parameters specific to integrated case: WH price, reference DH marginal costs and reference WH OPEX
$ifi %whr% == 'yes' $include './scripts/gams/reference_load.inc'
* Empties the list of heat-recovery generators
$ifi %whr% == 'no'  G_HR(G)     = NO;
$onlisting

* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
OPX_DH                      'Operating cost for DH (EUR)'
OPX_WH                      'Operating cost for WH (EUR)'
NPV                         'Net present value of WHR investments (EUR)'
;

POSITIVE VARIABLES
x_f_DH(T,G)                 'Consumption of fuel of DH generator (MWh)'
x_f_WH(T,G)                 'Consumption of fuel of WH generator (MWh)'
x_h(T,G)                    'Production of heat (MWh)'
x_hr(T,G)                   'Production of recovered heat (MWh)'
x_e(T,G)                    'Production of electricity (MWh)'
x_c(T,G)                    'Production of cold (MWh)'
* SOC(T,S)                    'State-of-charge of storage (MWh)'
Y_hr(G)                     'Heat capacity (MWh)'

w_q_DH(T,G)                 'Carbon emissions of DH generator (ton/MWh)'
w_q_WH(T,G)                 'Carbon emissions of WH generator (ton/MWh)'
;

* SOS1 VARIABLES
* x_s(T,S,SS)                 'Storage charge/discharge (MWh)'    
* ;

* ----- Variable operations -----


* ======================================================================
* EQUATIONS
* ======================================================================
* ----- Equation declaration -----
EQUATIONS
eq_OPX_DH                   'Operating cost of DH system'
eq_OPX_WH                   'Operating cost of WH source'
eq_NPV                      'Net present value of WHR investment'

eq_heat_balance(T)          'Heat balance in DH system'
eq_cold_balance(T)          'Cold balance in WH source'

eq_conversion_BP(T,G)       'Energy conversion for backpressure generators'
eq_conversion_EX(T,G)       'Energy conversion for extraction generators'
eq_conversion_HO(T,G)       'Energy conversion for heat-only generators'
eq_conversion_HR_heat(T,G)  'Energy conversion for heat-recovery generators (heat)'
eq_conversion_HR_cold(T,G)  'Energy conversion for heat-recovery generators (cold)'
eq_conversion_CO(T,G)       'Energy conversion for cold-only generators'

eq_ratio_BP(T,G)            'Electricity-to-heat ratio for backpressure generators'
eq_ratio_EX(T,G)            'Electricity-to-heat ratio for extraction generators'

eq_ramping_up(T,G)          'Ramping-up limit'
eq_ramping_down(T,G)        'Ramping-down limit'

eq_heat_maximum(T,G)        'Maximum heat production'
eq_elec_maximum(T,G)        'Maximum elec production for extraction units'
eq_cold_maximum(T,G)        'Maximum cold production'
eq_whrc_maximum(T,G)        'Maximum waste-heat recovery for heat-recovery units'

* eq_storage_balance(T,S)     'Storage balance'
* eq_storage_SOC_end(T,S)     'Storage initial state of charge'
* eq_storage_SOC_min(T,S)     'Storage minimum state of charge'
* eq_storage_SOC_max(T,S)     'Storage maximum state of charge'
* eq_storage_flow_max(T,S,SS) 'Storage throughput limit'

eq_emissions_DH(T,G)        'Carbon emissions of DH generator'
eq_emissions_WH(T,G)        'Carbon emissions of WH generator'
;

SCALAR
P_inv                        'Subsidy on WHR investment' /0/
;

* ----- Equation definition -----
eq_OPX_DH..                                 OPX_DH  =e= + sum((T,G_DH),  C_f(T,G_DH)            * x_f_dh(T,G_DH))
                                                        + sum((T,G_HO),  C_h(G_HO)              * x_h(T,G_HO))
                                                        + sum((T,G_CHP), C_e(G_CHP)             * x_e(T,G_CHP))
                                                        - sum((T,G_CHP), pi_e(T)                * x_e(T,G_CHP))
$ifi %whr% == 'yes'                                     + sum((T,G_HR),  pi_hr(T)               * x_hr(T,G_HR))
                                                        ;

eq_OPX_WH..                                 OPX_WH  =e= + sum((T,G_CO), C_f(T,G_CO) * x_f_wh(T,G_CO))
                                                        + sum((T,G_CO), C_c(G_CO)   * x_c(T,G_CO))
$ifi %whr% == 'yes'                                     + sum((T,G_HR), C_f(T,G_HR) * x_f_wh(T,G_HR))
$ifi %whr% == 'yes'                                     + sum((T,G_HR), C_h(G_HR)   * x_hr(T,G_HR))
$ifi %whr% == 'yes'                                     - sum((T,G_HR), pi_hr(T)    * x_hr(T,G_HR))
$ifi %whr% == 'yes'                                     + sum(G_HR,     C_fix(G_HR) * Y_hr(G_HR))
                                                        ;

$ifi %whr% == 'yes'
eq_NPV..                                    NPV =e= - sum(G_HR, C_inv(G_HR) * (1-P_inv) * Y_hr(G_HR)) + (OPX_WH_REF - OPX_WH)/AF;

eq_heat_balance(T)..                        sum(G_DH, x_h(T,G_DH)) + sum(G_HR, x_hr(T,G_HR))    =e= D_h(t);
eq_cold_balance(T)..                        sum(G_CO, x_c(T,G_CO)) + sum(G_HR, x_c(T,G_HR))     =e= D_c(t);

eq_conversion_BP(T,G)$(G_BP(G))..           eta(T,G)     * x_f_dh(T,G)      =e= x_e(T,G) + x_h(T,G);
eq_conversion_EX(T,G)$(G_EX(G))..           eta(T,G)     * x_f_dh(T,G)      =e= x_e(T,G) + beta_v(G)*x_h(T,G);
eq_conversion_HO(T,G)$(G_HO(G))..           eta(T,G)     * x_f_dh(T,G)      =e= x_h(T,G);
eq_conversion_HR_heat(T,G)$(G_HR(G))..      (eta(T,G)+1) * x_f_wh(T,G)      =e= x_hr(T,G);
eq_conversion_HR_cold(T,G)$(G_HR(G))..      eta(T,G)     * x_f_wh(T,G)      =e= x_c(T,G);
eq_conversion_CO(T,G)$(G_CO(G))..           eta(T,G)     * x_f_wh(T,G)      =e= x_c(T,G);

eq_ratio_BP(T,G)$G_BP(G)..                  x_e(T,G)                        =e= beta_b(G)*x_h(T,G);
eq_ratio_EX(T,G)$G_EX(G)..                  x_e(T,G)                        =g= beta_b(G)*x_h(T,G);

eq_ramping_up(T,G)$(G_DH(G))..              x_h(T++1,G) - x_h(T,G)          =l= R_f(G)*Y_h(G);
eq_ramping_down(T,G)$(G_DH(G))..            x_h(T,G) - x_h(T++1,G)          =l= R_f(G)*Y_h(G);

eq_heat_maximum(T,G)$(G_DH(G))..            x_h(T,G)                        =l= F_a(T,G)*Y_h(G);
eq_elec_maximum(T,G)$(G_EX(G))..            x_e(T,G)                        =l= F_a(T,G)*Y_e(G);
eq_cold_maximum(T,G)$(G_CO(G))..            x_c(T,G)                        =l= F_a(T,G)*Y_c(G);
eq_whrc_maximum(T,G)$(G_HR(G))..            x_hr(T,G)                       =l= F_a(T,G)*Y_hr(G);

* eq_storage_balance(T,S)..                   SOC(T,S)                =e= (1-rho_s(S))*SOC(T--1,S) + eta_s(S)*x_s(T,S,'charge') - x_s(T,S,'discharge')/eta_s(S);
* eq_storage_SOC_end(T,S)$(ord(T)=card(T))..  SOC(T,S)                =e= F_SOC_end(S)*Y_s(S);
* eq_storage_SOC_min(T,S)..                   SOC(T,S)                =g= F_SOC_min(S)*Y_s(S);
* eq_storage_SOC_max(T,S)..                   SOC(T,S)                =l= F_SOC_max(S)*Y_s(S);
* eq_storage_flow_max(T,S,SS)..               x_s(T,S,SS)             =l= F_s(S)*Y_s(S);

eq_emissions_DH(T,G)$G_DH(G)..              w_q_dh(T,G)                     =e= sum(F$GF(G,F), qc_f(T,F)*x_f_dh(T,G))/M3;
eq_emissions_WH(T,G)$(G_CO(G) OR G_HR(G)).. w_q_wh(T,G)                     =e= sum(F$GF(G,F), qc_f(T,F)*x_f_wh(T,G))/M3;


* ======================================================================
* MODEL
* ======================================================================
* ----- Model definition -----
model 
model_WH_reference              'Model for WH source - reference case'
/eq_OPX_WH, eq_cold_balance, eq_conversion_CO, eq_cold_maximum, eq_emissions_WH/

model_WH_integrated             'Model for WH source - integrated case'
/model_WH_reference, eq_NPV, eq_conversion_HR_cold, eq_conversion_HR_heat, eq_whrc_maximum/

model_DH                        'Model for DH system'
/eq_OPX_DH, eq_heat_balance, eq_conversion_BP, eq_conversion_EX, eq_conversion_HO, eq_ratio_BP, eq_ratio_EX, eq_ramping_up, eq_ramping_down, eq_heat_maximum, eq_elec_maximum, eq_emissions_DH/;

model_WH_reference.optfile = 1;
model_WH_integrated.optfile = 1;
model_DH.optfile = 1;

* ======================================================================
* SOLVE
* ======================================================================
* Output data (before solving to avoid variables with values)
execute_unload '%outDir%/data.gdx';

$ifi %scenario% == 'no-policy'          $include './scripts/gams/solve_no-policy.inc'
$ifi %scenario% == 'capital-subsidy'    $include './scripts/gams/solve_capital-subsidy.inc'

* * ======================================================================
* * POST-PROCESSING
* * ======================================================================
* Transfer results from reference case to be used in the next step
$ifi %whr% == 'no'  $include './scripts/gams/reference_unload.inc'

* ======================================================================
* END OF FILE