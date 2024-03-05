* ======================================================================
* DESCRIPTION:
* ======================================================================

$Offlisting
$Offsymlist
$Offinclude

* ----- NOTES -----
* - Tariff values are placeholders. They should be replaced with actual values.

* ======================================================================
*  SETUP:
* ======================================================================
* ----- Options -----
$onEmpty
* option optcr = 0.0001
option limrow = 0
option limcol = 0
option EpsToZero = on

* ----- Control flags -----
$SetGlobal portfolio      'test'
$SetGlobal scenario       'capital-subsidy'
$SetGlobal whr            'no'

* ----- Directories -----
* this command works with windows specifically. Change \ to / for linux.
$SetGlobal OutDir       './results/%portfolio%/%scenario%/'
execute                 'mkdir %OutDir%';

* ----- Filenames -----


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

lambda_h(T)             'Marginal cost of district heating system (EUR/MWh)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_hr(T)                'Price of recovered heat (Marginal cost of HP operation) (EUR/MWh)'
pi_q(F)                 'Price of carbon quota (EUR/kg)'
tau_f(G)                'Fuel tariff (EUR/MWh)'

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

* pi_hr(T)
* /
* $onDelim
* $include    './data/common/ts-heat-price.csv'
* $offDelim
* /

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
$onlisting

* - Assigned parameters -
C_e(G)$(G_CHP(G))               = GNRT_DATA(G,'variable cost - electricity');
C_h(G)$(G_HO(G))                = GNRT_DATA(G,'variable cost - heat');
C_h(G)$(G_HR(G))                = GNRT_DATA(G,'variable cost - heat');
C_c(G)$(G_CO(G))                = GNRT_DATA(G,'variable cost - cold');
C_inv(G)$(G_HR(G))              = GNRT_DATA(G,'capital cost');
C_fix(G)$(G_HR(G))              = GNRT_DATA(G,'fixed cost');
tau_f(G)                        = GNRT_DATA(G,'fuel tariff');

pi_f(T,F)                       = FUEL_DATA(F,'fuel price')$(NOT F_EL(F))       + pi_e(T)$(F_EL(F));
pi_q(F)                         = FUEL_DATA(F,'carbon price');
qc_f(T,F)                       = FUEL_DATA(F,'carbon content')$(NOT F_EL(F))   + qc_e(T)$(F_EL(F));
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
Y_c(G_CO)                       = smax(T, D_c(T));
***====> carbon quota still included
C_f(T,G)                        = sum(F$GF(G,F), pi_f(T,F) + qc_f(T,F)*pi_q(F) + tau_f(G));
* The following line allows to define capacities as a fraction of the maximum load.
Y_h(G)                          = Y_h(G)*smax(T, D_h(T));   
* Parameter Y_e required only for extraction units, because already constrained for backpressure units.
Y_e(G)$G_EX(G)                  = Y_h(G)*(beta_b(G) + beta_v(G));
pi_hr(T)                        = sum(G_HR, C_h(G_HR) + C_f(T,G_HR)/(eta(T,G_HR)+1))/card(G_HR);

* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
OPX_DH_ref                  'Operating cost for DH - reference case (EUR)'
OPX_DH_int                  'Operating cost for DH - integrated case (EUR)'
OPX_WH_ref                  'Operating cost for WH - reference case (EUR)'
OPX_WH_int                  'Operating cost for WH - integrated case (EUR)'
NPV                         'Net present value of WHR - integrated case (EUR)'
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
eq_NPV                      'Net present value of WH for integrated case'

eq_heat_balance_ref(T)      'Heat balance for reference case'
eq_heat_balance_int(T)      'Heat balance for integrated case'
eq_cold_balance_ref(T)      'Cold balance for reference case'
eq_cold_balance_int(T)      'Cold balance for integrated case'

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

PARAMETER
P_inv                        'Subsidy on WHR investment'
;

* ----- Equation definition -----
eq_OPX_DH_ref..                             OPX_DH_ref  =e= + sum((T,G_DH),  C_f(T,G_DH)            * x_f_dh(T,G_DH)) 
                                                            + sum((T,G_HO),  C_h(G_HO)              * x_h(T,G_HO))
                                                            + sum((T,G_CHP), C_e(G_CHP)             * x_e(T,G_CHP))
                                                            - sum((T,G_CHP), (pi_e(T)-tau_f(G_CHP)) * x_e(T,G_CHP))
                                                            ;

eq_OPX_DH_int..                             OPX_DH_int  =e= + sum((T,G_DH),  C_f(T,G_DH)            * x_f_dh(T,G_DH)) 
                                                            + sum((T,G_HO),  C_h(G_HO)              * x_h(T,G_HO))
                                                            + sum((T,G_CHP), C_e(G_CHP)             * x_e(T,G_CHP))
                                                            - sum((T,G_CHP), (pi_e(T)-tau_f(G_CHP)) * x_e(T,G_CHP))
                                                            + sum((T,G_HR),  pi_hr(T)               * x_hr(T,G_HR))
                                                            ;

eq_OPX_WH_ref..                             OPX_WH_ref  =e= + sum((T,G_CO), C_f(T,G_CO) * x_f_wh(T,G_CO)) 
                                                            + sum((T,G_CO), C_c(G_CO)   * x_c(T,G_CO))
                                                            ;

eq_OPX_WH_int..                             OPX_WH_int  =e= + sum((T,G_WH), C_f(T,G_WH) * x_f_wh(T,G_WH)) 
                                                            + sum((T,G_CO), C_c(G_CO)   * x_c(T,G_CO))
                                                            + sum((T,G_HR), C_h(G_HR)   * x_hr(T,G_HR))
                                                            - sum((T,G_HR), pi_hr(T)    * x_hr(T,G_HR))
                                                            + sum(G_HR,     C_fix(G_HR) * Y_hr(G_HR))
                                                            ;   

eq_NPV..                                    NPV =e= - sum(G_HR, C_inv(G_HR) * (1-P_inv) * Y_hr(G_HR)) + (OPX_WH_ref - OPX_WH_int)/AF;

eq_heat_balance_ref(T)..                    sum(G_DH, x_h(T,G_DH))                                  =e= D_h(t);
eq_heat_balance_int(T)..                    sum(G_DH, x_h(T,G_DH)) + sum(G_HR, x_hr(T,G_HR))        =e= D_h(t);
eq_cold_balance_ref(T)..                    sum(G_CO, x_c(T,G_CO))                                  =e= D_c(t);
eq_cold_balance_int(T)..                    sum(G_WH, x_c(T,G_WH))                                  =e= D_c(t);

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
eq_emissions_WH(T,G)$G_WH(G)..              w_q_wh(T,G)                     =e= sum(F$GF(G,F), qc_f(T,F)*x_f_wh(T,G))/M3;


* ======================================================================
* MODEL
* ======================================================================
* ----- Model definition -----
model 
mdl_WH_ref               'WH source, reference case'
/eq_OPX_WH_ref, eq_cold_balance_ref, eq_conversion_CO, eq_cold_maximum, eq_emissions_WH/

mdl_DH_ref               'DH system, reference case'
/eq_OPX_DH_ref, eq_heat_balance_ref, eq_conversion_BP, eq_conversion_EX, eq_conversion_HO, eq_ratio_BP, eq_ratio_EX, eq_ramping_up, eq_ramping_down, eq_heat_maximum, eq_elec_maximum, eq_emissions_DH/

mdl_WH_int               'WH source, integrated case'
/eq_OPX_WH_int, eq_NPV, eq_cold_balance_int, eq_conversion_CO, eq_conversion_HR_cold, eq_conversion_HR_heat, eq_cold_maximum, eq_whrc_maximum, eq_emissions_WH/

mdl_DH_int               'DH system, integrated case'
/eq_OPX_DH_int, eq_heat_balance_int, eq_conversion_BP, eq_conversion_EX, eq_conversion_HO, eq_ratio_BP, eq_ratio_EX, eq_ramping_up, eq_ramping_down, eq_heat_maximum, eq_elec_maximum, eq_emissions_DH/
;

mdl_WH_ref.optfile = 1;
mdl_DH_ref.optfile = 1;
mdl_WH_int.optfile = 1;
mdl_DH_int.optfile = 1;

* ======================================================================
* SOLVE
* ======================================================================
execute_unload '%OutDir%/data.gdx';

* Solve reference case for waste heat source
solve mdl_WH_ref using LP minimizing OPX_WH_ref;
* Fix operating costs for reference case to use in integrated case
OPX_WH_ref.fx = OPX_WH_ref.l;

* Solve reference case for district heating system
solve mdl_DH_ref using LP minimizing OPX_DH_ref;

* Unload reference case results
execute_unload '%OutDir%/output_reference.gdx' OPX_WH_ref, x_f_wh, x_c, w_q_wh, OPX_DH_ref, x_f_dh, x_h, x_e, w_q_dh;

* WHR is accepted into DH system only if price of recovered heat is lower than marginal cost of DH system
lambda_h(T)             = eq_heat_balance_ref.m(T);
F_a(T,G_HR)             = EPS + 1$(pi_hr(T) < lambda_h(T));



$ifi %scenario% == 'capital-subsidy' $include './scripts/gams/solve-capital-subsidy.inc'



* * ======================================================================
* * POST-PROCESSING
* * ======================================================================


* ======================================================================
* END OF FILE
