* ======================================================================
* DESCRIPTION:
* ======================================================================


* ----- NOTES -----
* -

* ======================================================================
*  SETUP:
* ======================================================================
* ----- Options -----
$onEmpty
option optcr = 0.0001
option limrow = 50
option limcol = 50

* ----- Control flags -----
$SetGlobal DH_name      CPH

* ----- Directories -----


* ----- Filenames -----


* ----- Global scalars -----



* ======================================================================
*  SETS
* ======================================================================
* ----- Set declaration -----
SET
A                       'Agents'
T                       'Timesteps'
U                       'Units'
G(U)                    'Generators' 
S(U)                    'Storages'
F                       'Fuels'
GF(G,F)                 'Generator-fuel mapping'
*SS                      'Storage state (SOS1 set)'  
;

* ----- Set definition -----
SET A                   'Agents'
/'DH', 'WH'/
;

SET T                   'Timesteps' 
/T0001*T8760/
;

SET U                   'Units'
/
$onDelim
$include    '../../data/common/name-unit.csv'
$offDelim
/;


SET G(U)                'Generators'
/
$onDelim
$include    '../../data/common/name-generator.csv'
$offDelim
/;

SET S(U)                'Storages'
/
$onDelim
$include    '../../data/common/name-storage.csv'
$offDelim
/;

SET F                   'Fuels'
/
$onDelim
$include    '../../data/common/name-fuel.csv'
$offDelim
/;

* SET SS                  'Storage states (SOS1 set)'
* /'charge', 'discharge'/
* ;
* 
SET GF(G,F)             'Generator-fuel mapping'
/
$onDelim
$include    '../../data/common/map-generator-fuel.csv'
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
$include    '../../data/common/attribute-generator.csv'
$offDelim
/;

SET StrgAttrs(*)        'Auxiliary set to load storage data'
/
$onDelim
$include    '../../data/common/attribute-storage.csv'
$offDelim
/;

SET FuelAttrs(*)        'Auxiliary set to load fuel data'
/
$onDelim
$include    '../../data/common/attribute-fuel.csv'
$offDelim
/;

* --- Load data values --- *
TABLE GNRT_DATA(G,GnrtAttrs)    'Generator data'
$onDelim
$include    '../../data/common/data-generator.csv'
$offDelim
;

* TABLE STRG_DATA(S,StrgAttrs)    'Storage data'
* $onDelim
* $include    '../../data/common/data-storage.csv'
* $offDelim
* ;

TABLE FUEL_DATA(F,FuelAttrs)    'Fuel data'
$onDelim
$include    '../../data/common/data-fuel.csv'
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
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_c(G)                  'Cost of cold production (EUR/MWh)'
C_e(G)                  'Cost of electricity production (EUR/MWh)'
C_f(T,G)                'Cost of fuel consumption (EUR/MWh)'
C_k(G)                  'Cost per capacity (EUR/MW)'

D_h(T)                  'Demand of heat (MW)'
D_c(T)                  'Demand of cold (MW)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_hr(T)                'Marginal cost of HP operation (EUR/MWh)'
* This parameter above should be indexed by G_HR, as different technologies can be included/selected.
pi_q(F)                 'Price of carbon quota (EUR/kg)'

qc_e(T)                  'Carbon content of electricity (kg/MWh)'
qc_f(T,F)                'Carbon content of fuel (kg/MWh)'

Y_c(G)                  'Cold output capacity (MWh)'
Y_f(G)                  'Fuel input capacity (MWh)'
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
PARAMETERS
D_h(T)
/
$onDelim
$include    '../../data/common/ts-demand-heat.csv'
$offDelim
/

D_c(T)
/
$onDelim
$include    '../../data/common/ts-demand-cold.csv'
$offDelim
/

pi_e(T)
/
$onDelim
$include    '../../data/common/ts-electricity-price.csv'
$offDelim
/

pi_hr(T)
/
$onDelim
$include    '../../data/common/ts-MC.csv'
$offDelim
/

qc_e(T)
/
$onDelim
$include    '../../data/common/ts-electricity-carbon.csv'
$offDelim
/

Y_f(G)
/
$onDelim
$include    '../../data/portfolios/portfolio-capacity-%DH_name%.csv'
$offDelim
/
;

* - Multi-dimensional parameters -
TABLE F_a(T,G)
$onDelim
$include    '../../data/common/ts-generator-availability.csv'
$offDelim
;

TABLE eta(T,G)
$onDelim
$include    '../../data/common/ts-generator-efficiency.csv'
$offDelim
;

* - Assigned parameters -
C_e(G)$(G_CHP(G))               = GNRT_DATA(G,'variable cost - electricity');
C_h(G)$(G_HO(G))                = GNRT_DATA(G,'variable cost - heat');
C_h(G)$(G_HR(G))                = GNRT_DATA(G,'variable cost - heat');
C_c(G)$(G_CO(G))                = GNRT_DATA(G,'variable cost - cold');
* Cost of heat for HO and HR can be merged.

pi_f(T,F)                       = FUEL_DATA(F,'fuel price')$(NOT F_EL(F))       + pi_e(T)$(F_EL(F));
pi_q(F)                         = FUEL_DATA(F,'carbon price');
qc_f(T,F)                       = FUEL_DATA(F,'carbon content')$(NOT F_EL(F))   + qc_e(T)$(F_EL(F));
* Y_f(G)                          = GNRT_DATA(G,'fuel capacity');
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
C_f(T,G)                        = sum(F$GF(G,F), pi_f(T,F) + qc_f(T,F)*pi_q(F));
C_k(G)$(G_HR(G))                = GNRT_DATA(G,'annuity factor')*GNRT_DATA(G,'capital cost') + GNRT_DATA(G,'fixed cost');

* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
obj(A)                  'Total cost for agent (EUR)'
;

POSITIVE VARIABLES
x_f_dh(T,G)             'Consumption of fuel (MWh)'
x_f_wh(T,G)             'Consumption of fuel (MWh)'
x_h(T,G)                'Production of heat (MWh)'
x_hr(T,G)               'Production of recovered heat (MWh)'
x_e(T,G)                'Production of electricity (MWh)'
x_c(T,G)                'Production of cold (MWh)'
* SOC(T,S)                'State-of-charge of storage (MWh)'
Y_h(G)                  'Heat capacity (MWh)'
;

* SOS1 VARIABLES
* x_s(T,S,SS)             'Storage charge/discharge (MWh)'    
* ;


* ======================================================================
* EQUATIONS
* ======================================================================
* ----- Equation declaration -----
EQUATIONS
eq_obj_DH                   'Objective function - Total cost of DH system'
eq_obj_WH                   'Objective function - Total cost of WH system'

eq_heat_balance(T)          'Heat balance'
eq_cold_balance(T)          'Cold balance'

eq_conversion_BP(T,G)       'Energy conversion for backpressure generators'
eq_conversion_EX(T,G)       'Energy conversion for extraction generators'
eq_conversion_HO(T,G)       'Energy conversion for heat-only generators'
eq_conversion_HR(T,G)       'Energy conversion for heat-recovery generators'
*eq_conversion_HR(T,G)       'Energy conversion for heat-recovery generators'
eq_conversion_CO(T,G)       'Energy conversion for cold-only generators'

eq_ratio_BP(T,G)            'Electricity-to-heat ratio for backpressure generators'
eq_ratio_EX(T,G)            'Electricity-to-heat ratio for extraction generators'

* extend ramping to all generators?
eq_ramping_up(T,G)          'Ramping-up limit'
eq_ramping_down(T,G)        'Ramping-down limit'

eq_fuel_maximum(T,G)        'Maximum fuel consumption'
eq_cold_maximum(T,G)        'Maximum cold production'
eq_heat_maximum(T,G)        'Maximum heat production'

* eq_storage_balance(T,S)     'Storage balance'
* eq_storage_SOC_end(T,S)     'Storage initial state of charge'
* eq_storage_SOC_min(T,S)     'Storage minimum state of charge'
* eq_storage_SOC_max(T,S)     'Storage maximum state of charge'
* eq_storage_flow_max(T,S,SS) 'Storage throughput limit'
;

* ----- Equation definition -----

* check this below
eq_obj_DH..                                    obj('DH')            =e= + sum((T,G_DH),  C_f(T,G_DH)    * x_f_dh(T,G_DH)) 
                                                                        + sum((T,G_HO),  C_h(G_HO)      * x_h(T,G_HO))
                                                                        + sum((T,G_CHP), C_e(G_CHP)     * x_e(T,G_CHP))
                                                                        - sum((T,G_CHP), pi_e(T)        * x_e(T,G_CHP))
                                                                        + sum((T,G_HR),  pi_hr(T)       * x_hr(T,G_HR))
                                                                        ;

eq_obj_WH..                                    obj('WH')            =e= + sum((T,G_WH),  C_f(T,G_WH)    * x_f_wh(T,G_WH)) 
                                                                        + sum((T,G_CO),  C_c(G_CO)      * x_c(T,G_CO))
                                                                        + sum((T,G_HR),  C_h(G_HR)      * x_hr(T,G_HR))
                                                                        - sum((T,G_HR),  pi_hr(T)       * x_hr(T,G_HR))
                                                                        + sum(G_HR,      C_k(G_HR)      * Y_h(G_HR))
;   


eq_heat_balance(T)..                        sum(G_DH, x_h(T,G_DH)) + sum(G_HR, x_hr(T,G_HR))        =e= D_h(t);
eq_cold_balance(T)..                        sum(G_WH, x_c(T,G_WH))                                  =e= D_c(t);

eq_conversion_BP(T,G)$(G_BP(G))..           eta(T,G)     * x_f_dh(T,G)      =e= x_e(T,G) + x_h(T,G);
eq_conversion_EX(T,G)$(G_EX(G))..           eta(T,G)     * x_f_dh(T,G)      =e= x_e(T,G) + beta_v(G)*x_h(T,G);
eq_conversion_HO(T,G)$(G_HO(G))..           eta(T,G)     * x_f_dh(T,G)      =e= x_h(T,G);
eq_conversion_HR(T,G)$(G_HR(G))..           (eta(T,G)+1) * x_f_wh(T,G)      =e= x_hr(T,G);
eq_conversion_CO(T,G)$(G_WH(G))..           eta(T,G)     * x_f_wh(T,G)      =e= x_c(T,G);

eq_ratio_BP(T,G)$G_BP(G)..                  x_e(T,G)                        =e= beta_b(G)*x_h(T,G);
eq_ratio_EX(T,G)$G_EX(G)..                  x_e(T,G)                        =g= beta_b(G)*x_h(T,G);

eq_ramping_up(T,G)$(G_DH(G))..              x_f_dh(T++1,G) - x_f_dh(T,G)    =l= R_f(G)*Y_f(G);
eq_ramping_down(T,G)$(G_DH(G))..            x_f_dh(T,G) - x_f_dh(T++1,G)    =l= R_f(G)*Y_f(G);

eq_fuel_maximum(T,G)$(G_DH(G))..            x_f_dh(T,G)                     =l= F_a(T,G)*Y_f(G);
eq_cold_maximum(T,G)$(G_CO(G))..            x_c(T,G)                        =l= F_a(T,G)*Y_c(G);
eq_heat_maximum(T,G)$(G_HR(G))..            x_hr(T,G)                       =l= F_a(T,G)*Y_h(G);

* eq_storage_balance(T,S)..                   SOC(T,S)                =e= (1-rho_s(S))*SOC(T--1,S) + eta_s(S)*x_s(T,S,'charge') - x_s(T,S,'discharge')/eta_s(S);
* eq_storage_SOC_end(T,S)$(ord(T)=card(T))..  SOC(T,S)                =e= F_SOC_end(S)*Y_s(S);
* eq_storage_SOC_min(T,S)..                   SOC(T,S)                =g= F_SOC_min(S)*Y_s(S);
* eq_storage_SOC_max(T,S)..                   SOC(T,S)                =l= F_SOC_max(S)*Y_s(S);
* eq_storage_flow_max(T,S,SS)..               x_s(T,S,SS)             =l= F_s(S)*Y_s(S);

* ======================================================================
* MODEL
* ======================================================================
* ----- Model definition -----
model
all_eqs             'All equations'
/all/
;

* all_eqs.optfile = 1;

File empinfo /'%emp.info%'/; putclose empinfo
    'equilibrium' /
    'min', obj('DH'), 'x_f_dh', 'x_h', 'x_e',         eq_obj_DH, 'eq_heat_balance', 'eq_fuel_maximum', 'eq_conversion_HO', 'eq_conversion_EX', 'eq_conversion_BP', 'eq_ramping_up', 'eq_ramping_down', 'eq_ratio_EX', 'eq_ratio_BP'/
    'min', obj('WH'), 'x_f_wh', 'x_c', 'x_hr', 'Y_h', eq_obj_WH, 'eq_cold_balance', 'eq_cold_maximum', 'eq_conversion_CO', 'eq_conversion_HR', 'eq_heat_maximum'/
;



* ======================================================================
* SOLVE
* ======================================================================
solve all_eqs using EMP;

* * ======================================================================
* * POST-PROCESSING
* * ======================================================================
* PARAMETERS
* MC_DH(T)    'Marginal cost (EUR/MWh)';
* MC_DH(T)    = eq_heat_balance.m(T);

* * PARAMETERS
* * fuel_use(T,F)
* * heat_share(G)       'Heat share (-)'
* * fuel_share(F)
* * ;

* * heat_share(G) = sum(T, x_h.l(T,G))/sum(T, D(T));
* * fuel_use(T,F) = sum(G$GF(G,F), x_f.l(T,G));
* * fuel_sharE(F) = sum(T, fuel_use(T,F))/sum((T,G), x_f.l(T,G));

* * Change in cost?
* * Change in emissions?

* * ======================================================================
* * OUTPUT
* * ======================================================================
* * --- Create output directory and unload GDX file --- *
* $setglobal  dir_DH  ..\..\results\%DH_name%
* $ifi %EHR% == NO    $setglobal  dir_WH  %dir_DH%\baseline
* $ifi %EHR% == YES   $setglobal  dir_WH  %dir_DH%\%WH%

* execute             'mkdir %dir_WH%'
* execute_unload      '%dir_WH%\output.gdx'

* * --- Output MC of DH if EHR is disabled --- *
* $ifi NOT %EHR% == YES
*     execute 'gdxdump %dir_WH%\output.gdx output=%dir_DH%\ts-MC_DH-%DH_name%.csv format=csv symb=MC_DH epsout=0 noheader';

* * ======================================================================
* * REPORTING
* * ======================================================================
* display "DH name: %DH_name%";
* display "Output GDX file: %dir_WH%\output.gdx"

* display "Variable levels"
* display obj.l;

* * ======================================================================
* * END OF FILE