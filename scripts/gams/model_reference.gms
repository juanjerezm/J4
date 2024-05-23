* ======================================================================
* DESCRIPTION:
* ======================================================================
* ----- INFO -----

* ----- NOTES -----

* ----- TO DO -----

* ======================================================================
*  SETUP:
* ======================================================================
* ----- GAMS Options -----
$onEmpty
* $Offlisting
* $Offsymlist 
* $Offinclude
option limrow = 0
option limcol = 0

* ----- Control flags -----
* Set default values if script not called from integrated model
$ifi not set name       $setlocal name          'testrun9'
$ifi not set policytype $setlocal policytype    'taxation'
$ifi not set country    $setlocal country       'DK'

* ----- Directories, filenames, and scripts -----
* Make directory for results transfered to the integrated case
$ifi %system.filesys% == msnt   execute 'mkdir    .\results\%name%\transferDir';
$ifi %system.filesys% == unix   execute 'mkdir -p ./results/%name%/transferDir';

* ----- Global scalars -----
SCALARS
M3                      'Thousand multiplier'   /1E3/
D6                      'Million divisor'       /1E-6/;


* ======================================================================
*  SETS
* ======================================================================
* ----- Set declaration -----
SET
T                       'Timesteps'
G                       'Generators'
S                       'Storages'
SS                      'Storage state (SOS1 set)'
F                       'Fuels'
GF(G,F)                 'Generator-fuel mapping'
;

* ----- Set definition -----
SET T                   'Timesteps' 
/T0001*T8760/;

SET SS                  'Storage states (SOS1 set)'
/'charge', 'discharge'/;

SET E                   'Entity'
/'DHN', 'WHS'/
;

SET G                   'Generators'
/
$onDelim
$include    './data/common/name-generator.csv'
$offDelim
/;

SET S(*)                'Storages'
/
$onDelim
$include    './data/common/name-storage.csv'
$offDelim
/;

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

SET StrgAttrs(*)        'Auxiliary set to load storage data'
/
$onDelim
$include    './data/common/attribute-storage.csv'
$offDelim
/;

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

TABLE STRG_DATA(S,StrgAttrs)    'Storage data'
$onDelim
$include    './data/common/data-storage.csv'
$offDelim
;

TABLE FUEL_DATA(F,FuelAttrs)    'Fuel data'
$onDelim
$include    './data/common/data-fuel-%country%.csv'
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
G_DH(G)                 'DH generators'
G_WH(G)                 'WH generators'
S_DH(S)                 'DH storages'
S_WH(S)                 'WH storages'
F_EL(F)                 'Electricity fuel'
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

S_DH(S)     = YES$(STRG_DATA(S,'TYPE') EQ DH);
S_WH(S)     = YES$(STRG_DATA(S,'TYPE') EQ WH); 

F_EL(F)     = YES$(sameas(F,'electricity'));

* ----- Subset operations -----


* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
C_f(T,G,F)              'Cost of fuel consumption (EUR/MWh)'
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_c(G)                  'Cost of cold production (EUR/MWh)'
C_e(G)                  'Cost of electricity production (EUR/MWh)'
C_g_fix(G)              'Fixed cost of generator (EUR/MW)'
C_g_inv(G)              'Investment cost of generator (EUR/MW)'
C_s(S)                  'Storage variable cost (EUR/MWh)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_q(F)                 'Price of carbon quota (EUR/kg)'
tau_f_v(F)              'Fuel taxes and volumetric tariffs (EUR/MWh)'
tau_f_c(F)              'Fuel capacity tariffs (EUR/MW)'
tau_g(G)                'Special fuel surcharges for generator (EUR/MWh)'
qc_e(T)                 'Carbon content of electricity (kg/MWh)'
qc_f(T,F)               'Carbon content of fuel (kg/MWh)'

D_h(T)                  'Demand of heat (MW)'
D_c(T)                  'Demand of cold (MW)'

Y_c(G)                  'Cold output capacity (MW)'
Y_f(G)                  'Firing capacity (MW), (DH generators)'
F_a(T,G)                'Generator availabity factor (-)'
eta_g(T,G)              'Generator efficiency (-), (BP: total, EX: condensing)'
beta_b(G)               'Cb coefficient of CHPs (-)'
beta_v(G)               'Cv coefficient of CHPs (-)'

Y_s(S)                  'Storage capacity (MWh)'
F_s_flo(S)              'Storage throughput capacity factor (-)'  
F_s_end(S)              'Final storage state-of-charge factor (-)'
F_s_min(S)              'Minimum storage state-of-charge factor (-)'
F_s_max(S)              'Maximum storage state-of-charge factor (-)'
rho_s(S)                'Storage self-discharge factor (-)'
eta_s(S)                'Storage throughput efficiency (-)'
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

tau_g(G)
/
$onDelim
$include    './data/common/data-generator-fuel-surcharge-%country%.csv'
$OffDelim
/
;

* - Multi-dimensional parameters -
TABLE F_a(T,G)
$onDelim
$include    './data/common/ts-generator-availability.csv'
$offDelim
;

TABLE eta_g(T,G)
$onDelim
$include    './data/common/ts-generator-efficiency.csv'
$offDelim
;

* - Assigned parameters -
C_e(G)$(G_CHP(G))       = GNRT_DATA(G,'variable cost - electricity');
C_h(G)$(G_HO(G))        = GNRT_DATA(G,'variable cost - heat');
C_c(G)$(G_CO(G))        = GNRT_DATA(G,'variable cost - cold');

pi_f(T,F)               = FUEL_DATA(F,'fuel price')$(NOT F_EL(F))       + pi_e(T)$(F_EL(F));
pi_q(F)                 = FUEL_DATA(F,'carbon price');
qc_f(T,F)               = FUEL_DATA(F,'carbon content')$(NOT F_EL(F))   + qc_e(T)$(F_EL(F));
tau_f_v(F)              = FUEL_DATA(F,'fuel tax') + FUEL_DATA(F,'volumetric tariff');
tau_f_c(F)              = FUEL_DATA(F,'capacity tariff');

Y_f(G_DH)               = GNRT_DATA(G_DH,'capacity');  
beta_b(G)$G_CHP(G)      = GNRT_DATA(G,'Cb');
beta_v(G)$G_EX(G)       = GNRT_DATA(G,'Cv');

C_s(S)                  = STRG_DATA(S,'OMV');
Y_s(S)                  = STRG_DATA(S,'SOC capacity');
eta_s(S)                = STRG_DATA(S,'throughput efficiency');
rho_s(S)                = STRG_DATA(S,'self-discharge factor');
F_s_flo(S)              = STRG_DATA(S,'throughput ratio');
F_s_end(S)              = STRG_DATA(S,'SOC ratio end');
F_s_min(S)              = STRG_DATA(S,'SOC ratio min');
F_s_max(S)              = STRG_DATA(S,'SOC ratio max');

* ----- Parameter operations -----
* cold-only capacity defined by peak demand
Y_c(G_CO)               = smax(T, D_c(T));

*  Calculate fuel cost from fuel price, carbon quota, and taxes/tariffs
$ifi %policytype% == 'socioeconomic'    C_f(T,G,F)  = pi_f(T,F);
$ifi %policytype% == 'taxation'         C_f(T,G,F)  = pi_f(T,F) + qc_f(T,F)*pi_q(F) + tau_f_v(F) + tau_g(G);
$ifi %policytype% == 'support'          C_f(T,G,F)  = pi_f(T,F) + qc_f(T,F)*pi_q(F) + tau_f_v(F) + tau_g(G);

* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
obj                         'Auxiliary objective variable (EUR), to optimize either OPX(DHN) or OPX(WHS)'
OPX(E)                      'Operating cost for entity (stakeholder) (EUR)'
;

POSITIVE VARIABLES
x_f(T,G,F)                  'Consumption of fuel by generator (MWh)'
x_h(T,G)                    'Production of heat (MWh)'
x_e(T,G)                    'Production of electricity (MWh)'
x_c(T,G)                    'Production of cold (MWh)'
z(T,S)                      'State-of-charge of storage (MWh)'
y_f_used(E,F)               'Maximum fuel consumption of fuel per entity at any timestep (MW)'
;

SOS1 VARIABLES
x_s(T,S,SS)                 'Storage charge/discharge flow (MWh)'
;

* ----- Variable attributes -----


* ======================================================================
* EQUATIONS
* ======================================================================
* ----- Equation declaration -----
EQUATIONS
eq_obj_DHN                  'Auxiliary equation to optimize OPX of the DHN only'
eq_obj_WHS                  'Auxiliary equation to optimize OPX of the WHS only'
eq_OPX_DHN                  'Operating cost of DH system'
eq_OPX_WHS                  'Operating cost of WH source'

eq_load_heat(T)             'Heat load in DHN'
eq_load_cold(T)             'Cold load in WHS'

eq_conversion_CO(T,G)       'Conversion constraint for cold-only generators'
eq_conversion_HO(T,G)       'Conversion constraint for heat-only generators'
eq_conversion_BP_1(T,G)     'Conversion constraint for backpressure generators (energy balance)'
eq_conversion_BP_2(T,G)     'Conversion constraint for backpressure generators (elec-heat ratio)'
eq_conversion_EX_1(T,G)     'Conversion constraint for extraction generators (energy balance)'
eq_conversion_EX_2(T,G)     'Conversion constraint for extraction generators (elec-heat ratio)'

eq_max_DH(T,G)              'Capacity constraint for DH generators (input-based)'
eq_max_CO(T,G)              'Capacity constraint for cold-only generators (output-based)'
eq_max_fueluse_DHN(T,F)     'Maximum fuel consumption by DHN at any timestep'
eq_max_fueluse_WHS(T,F)     'Maximum fuel consumption by WHS at any timestep'

eq_sto_balance(T,S)         'Storage balance'
eq_sto_end(T,S)             'Storage initial state-of-charge'
eq_sto_min(T,S)             'Storage minimum state-of-charge'
eq_sto_max(T,S)             'Storage maximum state-of-charge'
eq_sto_flo(T,S,SS)          'Storage throughput limit'
;


* ----- Equation definition -----
eq_obj_DHN..                                OPX('DHN')  =e= obj;
eq_obj_WHS..                                OPX('WHS')  =e= obj;
eq_OPX_DHN..                                OPX('DHN')  =e= + sum((T,G_DH,F)$GF(G_DH,F), C_f(T,G_DH,F) * x_f(T,G_DH,F))
                                                            + sum((T,G_HO),              C_h(G_HO)     * x_h(T,G_HO))
                                                            + sum((T,G_CHP),             C_e(G_CHP)    * x_e(T,G_CHP))
                                                            - sum((T,G_CHP),             pi_e(T)       * x_e(T,G_CHP))
$ifi not %policytype% == 'socioeconomic'                    - sum(F, tau_f_c(F) * y_f_used('DHN',F))
                                                            ;

eq_OPX_WHS..                                OPX('WHS')  =e= + sum((T,G_CO,F)$GF(G_CO,F), C_f(T,G_CO,F) * x_f(T,G_CO,F))
                                                            + sum((T,G_CO),              C_c(G_CO)     * x_c(T,G_CO))
$ifi not %policytype% == 'socioeconomic'                    - sum(F, tau_f_c(F) * y_f_used('WHS',F))
                                                            ;

eq_load_heat(T)..                           sum(G_DH, x_h(T,G_DH)) + sum(S_DH, x_s(T,S_DH,'discharge')) - sum(S_DH, x_s(T,S_DH,'charge')) =e= D_h(T);
eq_load_cold(T)..                           sum(G_CO, x_c(T,G_CO)) =e= D_c(T);

eq_conversion_CO(T,G)$G_CO(G)..             eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e= x_c(T,G);
eq_conversion_HO(T,G)$G_HO(G)..             eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G);
eq_conversion_BP_1(T,G)$G_BP(G)..           eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G) + x_e(T,G);
eq_conversion_BP_2(T,G)$G_BP(G)..                                                 0 =e= beta_b(G) * x_h(T,G) - x_e(T,G);
eq_conversion_EX_1(T,G)$G_EX(G)..           eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e= beta_v(G) * x_h(T,G) + x_e(T,G);
eq_conversion_EX_2(T,G)$G_EX(G)..                                                 0 =g= beta_b(G) * x_h(T,G) - x_e(T,G);

eq_max_DH(T,G)$G_DH(G)..                                 sum(F$GF(G,F), x_f(T,G,F)) =l= F_a(T,G)*Y_f(G);
eq_max_CO(T,G)$G_CO(G)..                                                x_c(T,G)    =l= F_a(T,G)*Y_c(G);
eq_max_fueluse_DHN(T,F)..                       sum(G_DH$GF(G_DH,F), x_f(T,G_DH,F)) =l= y_f_used('DHN',F);
eq_max_fueluse_WHS(T,F)..                       sum(G_CO$GF(G_CO,F), x_f(T,G_CO,F)) =l= y_f_used('WHS',F);

eq_sto_balance(T,S)..                       z(T,S)      =e= (1-rho_s(S)) * z(T--1,S) + eta_s(S)*x_s(T,S,'charge') - x_s(T,S,'discharge')/eta_s(S);
eq_sto_end(T,S)$(ord(T)=card(T))..          z(T,S)      =e= F_s_end(S)*Y_s(S);
eq_sto_min(T,S)..                           z(T,S)      =g= F_s_min(S)*Y_s(S);
eq_sto_max(T,S)..                           z(T,S)      =l= F_s_max(S)*Y_s(S);
eq_sto_flo(T,S,SS)..                        x_s(T,S,SS) =l= F_s_flo(S)*Y_s(S);


* ======================================================================
* MODEL
* ======================================================================
* ----- Model definition -----
model 
mdl_DHN              'DHN'    
/eq_obj_DHN, eq_OPX_DHN, eq_load_heat, eq_conversion_HO, eq_conversion_BP_1, eq_conversion_BP_2, eq_conversion_EX_1, eq_conversion_EX_2, eq_max_DH, eq_sto_balance, eq_sto_end, eq_sto_min, eq_sto_max, eq_sto_flo, eq_max_fueluse_DHN/

mdl_WHS              'WHS'
/eq_obj_WHS, eq_OPX_WHS, eq_load_cold, eq_conversion_CO, eq_max_CO, eq_max_fueluse_WHS/
;


* ======================================================================
* SOLVE AND POST-PROCESSING
* ======================================================================
solve mdl_DHN using mip minimizing obj;
solve mdl_WHS using mip minimizing obj;

PARAMETERS
MC_DH(T)    'Reference marginal cost of DHN (EUR/MWh)'
CO2(F)      'Reference CO2 emissions (kg)'
;
MC_DH(T)    = EPS + eq_load_heat.m(T);
CO2(F)      = sum((T,G)$GF(G,F), qc_f(T,F)*x_f.l(T,G,F));

execute_unload  './results/%name%/results-%name%-reference.gdx';
execute 'gdxdump ./results/%name%/results-%name%-reference.gdx format=csv epsout=0 noheader output=./results/%name%/transferDir/OPEX_ref.csv symb=OPX';
execute 'gdxdump ./results/%name%/results-%name%-reference.gdx format=csv epsout=0 noheader output=./results/%name%/transferDir/CO2_ref.csv symb=CO2';
execute 'gdxdump ./results/%name%/results-%name%-reference.gdx format=csv epsout=0 noheader output=./results/%name%/transferDir/ts-margcost-heat.csv symb=MC_DH';

* ======================================================================
* END OF FILE
