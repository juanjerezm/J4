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
$eolCom !!
$onEmpty                !! Allows empty sets or parameters
$Offlisting             !! Suppresses listing of input lines
$offSymList             !! Suppresses listing of symbol map
$offInclude             !! Suppresses listing of include-files 
option solprint = off   !! Toggles solution listing
option limRow = 0       !! Maximum number of rows listed in equation block
option limCol = 0       !! Maximum number of columns listed in one variable block
option optcr = 0.01;    !! Relative optimality tolerance

* ----- Control flags -----
* Set default values if script not called from integrated model nor command line
$ifi not set project    $setlocal project       'default_prj'
$ifi not set scenario   $setlocal scenario      'default_scn'
$ifi not set policytype $setlocal policytype    'taxation'
$ifi not set country    $setlocal country       'DK'

* ----- Directories, filenames, and scripts -----

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
H                       'Hours'
M                       'Months'
G                       'Generators'
S                       'Storages'
SS                      'Storage state (SOS1 set)'
F                       'Fuels'
TM(T,M)                 'Timestep-month mapping'
TH(T,H)                 'Timestep-hour mapping'
GF(G,F)                 'Generator-fuel mapping'
;

* ----- Set definition -----
SET T                   'Timesteps' 
/T0001*T8760/;

SET H                   'Hours'
/H01*H24/;

SET M                   'Months'
/M01*M12/;

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

SET TM(T,M)              'Timestep-month mapping'
/
$onDelim
$include    './data/common/ts-TM-mapping.csv'
$offDelim
/;

SET TH(T,H)              'Timestep-hour mapping'
/
$onDelim
$include    './data/common/ts-TH-mapping.csv'
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
pi_q                    'Price of carbon quota (EUR/kg)'
tax_fuel_f(F)           'Fuel taxes - by fuel (EUR/MWh)'
tax_fuel_g(G)           'Fuel taxes - by generator (EUR/MWh)'
tariff_v(T)             'Volumetric electricity tariff - time-of-use (EUR/MWh)'
tariff_c(F)             'Capacity electricity tariff - constant (EUR/MW)'
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
* - Direct assignment - (This should, ideally, be done in a separate data file)
pi_q            = 0.0853;   !! Price of carbon quota (EUR/kg)

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

tax_fuel_g(G)
/
$onDelim
$include    './data/common/data-fueltax-generator-%country%.csv'
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

TABLE tariff_schedule_v(H,M)
$onDelim
$include    './data/common/data-tariffschedule-vol-%country%.csv'
$offDelim
;

* - Assigned parameters -
C_e(G)$(G_CHP(G))       = GNRT_DATA(G,'variable cost - electricity');
C_h(G)$(G_HO(G))        = GNRT_DATA(G,'variable cost - heat');
C_c(G)$(G_CO(G))        = GNRT_DATA(G,'variable cost - cold');

pi_f(T,F)               = FUEL_DATA(F,'fuel price')$(NOT F_EL(F))       + pi_e(T)$(F_EL(F));
qc_f(T,F)               = FUEL_DATA(F,'carbon content')$(NOT F_EL(F))   + qc_e(T)$(F_EL(F));
tax_fuel_f(F)           = FUEL_DATA(F,'fuel tax');
tariff_c(F)             = FUEL_DATA(F,'capacity tariff');

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
Y_c(G_CO)           = smax(T, D_c(T));  !! Cold-only capacity defined by peak demand
tariff_v(T)         = SUM((H,M)$(TM(T,M) AND TH(T,H)), tariff_schedule_v(H,M)); !! mapping hour-month schedule to timesteps

*  Calculate fuel cost from fuel price, taxes (per fuel and generator), electricity tariffs and ETS quotas
C_f(T,G,F)$G_DH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));

* Fuel costs for WHS depend on the policy type
$ifi %policytype% == 'socioeconomic'    C_f(T,G,F)$G_WH(G)  = pi_f(T,F);
$ifi %policytype% == 'taxation'         C_f(T,G,F)$G_WH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));
$ifi %policytype% == 'support'          C_f(T,G,F)$G_WH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));

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
w_g(T,G)                    'Carbon emissions of generator (kg)'
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
eq_obj                      'Objective function of joint OPEX'
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

eq_carbon_emissions(T,G)    'Carbon emissions of generators'

eq_sto_balance(T,S)         'Storage balance'
eq_sto_end(T,S)             'Storage initial state-of-charge'
eq_sto_min(T,S)             'Storage minimum state-of-charge'
eq_sto_max(T,S)             'Storage maximum state-of-charge'
eq_sto_flo(T,S,SS)          'Storage throughput limit'
;


* ----- Equation definition -----
eq_obj..                                    obj         =e= OPX('DHN') + OPX('WHS');
eq_OPX_DHN..                                OPX('DHN')  =e= + sum((T,G_DH,F)$GF(G_DH,F), C_f(T,G_DH,F) * x_f(T,G_DH,F))
                                                            + sum((T,G_HO),              C_h(G_HO)     * x_h(T,G_HO))
                                                            + sum((T,G_CHP),             C_e(G_CHP)    * x_e(T,G_CHP))
                                                            - sum((T,G_CHP),             pi_e(T)       * x_e(T,G_CHP))
$ifi not %policytype% == 'socioeconomic'                    + sum(F,                     tariff_c(F)   * y_f_used('DHN',F))
                                                            ;

eq_OPX_WHS..                                OPX('WHS')  =e= + sum((T,G_CO,F)$GF(G_CO,F), C_f(T,G_CO,F) * x_f(T,G_CO,F))
                                                            + sum((T,G_CO),              C_c(G_CO)     * x_c(T,G_CO))
$ifi not %policytype% == 'socioeconomic'                    + sum(F,                     tariff_c(F)   * y_f_used('WHS',F))
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

eq_carbon_emissions(T,G)..                   sum((F)$GF(G,F), qc_f(T,F)*x_f(T,G,F)) =e= w_g(T,G);

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
mdl_all             'DHN and WHS'       !! Each entity is independent of the other, so we can solve them together
/all/
;


* ======================================================================
* SOLVE AND POST-PROCESSING
* ======================================================================
solve mdl_all using mip minimizing obj;

* Following parameters are inputs to the integrated model
PARAMETERS
MC_DH(T)        'Reference marginal cost of DHN (EUR/MWh)'
OPX_ref(E)      'Reference operating cost (EUR/year)'
CO2_ref(T)      'Reference CO2 emissions per heat production (kg/MWh)'
XH_ref(T,G)     'Reference heat production (MWh)'
XF_ref(T,G,F)   'Reference fuel consumption (MWh)'
;
MC_DH(T)                    = EPS + eq_load_heat.m(T);
OPX_ref(E)                  = EPS + OPX.l(E);
CO2_ref(T)                  = EPS + sum(G, w_g.l(T,G))/D_h(T);
XH_ref(T,G_DH)              = EPS + x_h.l(T,G_DH);
XF_ref(T,G_DH,F)$GF(G_DH,F) = EPS + x_f.l(T,G_DH,F);

PARAMETERS
value_taxes(E)     'Value of energy taxes and ETS (EUR/year)'
value_tariffs(E)   'Value of electricity tariffs (EUR/year)'
value_support(E)   'Value of support schemes (EUR/year)'
;

$ifi     %policytype% == 'socioeconomic' value_taxes('WHS')     = 0;
$ifi not %policytype% == 'socioeconomic' value_taxes('WHS')     = sum((T,G_WH,F)$GF(G_WH,F), x_f.l(T,G_WH,F) * (tax_fuel_f(F) + tax_fuel_g(G_WH) + pi_q*qc_f(T,F)$(NOT F_EL(F))));
                                         value_taxes('DHN')     = sum((T,G_DH,F)$GF(G_DH,F), x_f.l(T,G_DH,F) * (tax_fuel_f(F) + tax_fuel_g(G_DH) + pi_q*qc_f(T,F)$(NOT F_EL(F))));

$ifi     %policytype% == 'socioeconomic' value_tariffs('WHS')   = 0;
$ifi not %policytype% == 'socioeconomic' value_tariffs('WHS')   = sum((T,G_WH,F)$(GF(G_WH,F) AND F_EL(F)), tariff_v(T) * x_f.l(T,G_WH,F)) + sum(F, tariff_c(F) * y_f_used.l('WHS',F));
                                         value_tariffs('DHN')   = sum((T,G_DH,F)$(GF(G_DH,F) AND F_EL(F)), tariff_v(T) * x_f.l(T,G_DH,F)) + sum(F, tariff_c(F) * y_f_used.l('DHN',F));

value_support(E)       = 0;

execute_unload  './results/%project%/%scenario%/results-%scenario%-reference.gdx';

* ======================================================================
* END OF FILE
