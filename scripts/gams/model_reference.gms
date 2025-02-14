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
option optcr = 1e-4     !! Relative optimality tolerance
option EpsToZero = on   !! Outputs Eps values as zero
;

* ======================================================================
*  SCRIPT CONTROL (Commented if running from run.gms):
* ======================================================================
* * ----- Control flags -----
* * Set default values if script not called from integrated model nor command line
* $ifi not set project    $setlocal project       'default_prj'
* $ifi not set scenario   $setlocal scenario      'default_scn'
* $ifi not set policytype $setlocal policytype    'taxation'
* $ifi not set country    $setlocal country       'DK'

* * ----- Directories, filenames, and scripts -----
* * Create directories for output if script not called from integrated model nor command line
* $ifi %system.filesys% == msnt   $call 'mkdir    .\results\%project%\%scenario%\';
* $ifi %system.filesys% == unix   $call 'mkdir -p ./results/%project%/%scenario%/';

* $call gams ./scripts/gams/parameters.gms      --project=%project% --scenario=%scenario% --policytype=%policytype% --country=%country% o=./results/%project%/%scenario%/parameters.lst

* ======================================================================
* SCALARS
* ======================================================================
* ----- Global scalars -----
SCALAR
M3                      'Thousand multiplier'   /1E3/
M6                      'Million multiplier'    /1E6/
D3                      'Thousand divisor'      /1E-3/
D6                      'Million divisor'       /1E-6/
;


* ======================================================================
*  SETS
* ======================================================================
* ----- Set declaration -----
SET
T                       'Timesteps'
H                       'Hours'
M                       'Months'
E                       'Entity'
G                       'Generators'
S                       'Storages'
SS                      'Storage state (SOS1 set)'
F                       'Fuels'
TM(T,M)                 'Timestep-month mapping'
TH(T,H)                 'Timestep-hour mapping'
GF(G,F)                 'Generator-fuel mapping'
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


* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
C_f(T,G,F)              'Cost of fuel consumption (EUR/MWh)'
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_c(G)                  'Cost of cold production (EUR/MWh)'
C_e(G)                  'Cost of electricity production (EUR/MWh)'
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
$gdxin results/%project%/%scenario%/parameters.gdx
$load T, H, M, G, S, SS, E, F, TM, TH, GF                                       !! Load sets
$load G_BP, G_EX, G_HO, G_CO, G_HR, G_CHP, G_DH, G_WH, S_DH, S_WH, F_EL         !! Load subsets
$load D_h, D_c                                                                  !! Load system parameters
$load C_e, C_h, C_c, Y_c, Y_f, F_a, eta_g, beta_b, beta_v                       !! Load generator parameters
$load C_f, pi_f, qc_f, pi_q, pi_e, qc_e                                         !! Load fuel parameters
$load tax_fuel_f, tariff_c, tariff_v, tax_fuel_g                                !! Load tax-and-tariff parameters
$load C_s, Y_s, eta_s, rho_s, F_s_flo, F_s_end, F_s_min, F_s_max                !! Load storage parameters
$gdxin

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
w(T,G,F)                    'Carbon emissions of generator (kg)'
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

eq_carbon_emissions(T,G,F)  'Carbon emissions of generators'

eq_sto_balance(T,S)         'Storage balance'
eq_sto_end(T,S)             'Storage initial state-of-charge'
eq_sto_min(T,S)             'Storage minimum state-of-charge'
eq_sto_max(T,S)             'Storage maximum state-of-charge'
eq_sto_flo(T,S,SS)          'Storage throughput limit'
;


* ----- Equation definition -----
* Variable cost of storages are negligible
eq_obj..                                    obj         =e= OPX('DHN') + OPX('WHS');
eq_OPX_DHN..                                OPX('DHN')  =e= + sum((T,G_DH,F)$GF(G_DH,F), C_f(T,G_DH,F) * x_f(T,G_DH,F))
                                                            + sum((T,G_HO),              C_h(G_HO)     * x_h(T,G_HO))
                                                            + sum((T,S_DH),              C_s(S_DH)     * x_s(T,S_DH,'discharge'))
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

eq_carbon_emissions(T,G,F)$GF(G,F)..                           qc_f(T,F)*x_f(T,G,F) =e= w(T,G,F);

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


PARAMETERS
value_taxes(E)     'Value of energy taxes and ETS (EUR/year)'
value_tariffs(E)   'Value of electricity tariffs (EUR/year)'
value_support(E)   'Value of support schemes (EUR/year)'
;

$ifi     %policytype% == 'socioeconomic' value_taxes('WHS')     = EPS;
$ifi not %policytype% == 'socioeconomic' value_taxes('WHS')     = EPS + sum((T,G_WH,F)$GF(G_WH,F), x_f.l(T,G_WH,F) * (tax_fuel_f(F) + tax_fuel_g(G_WH) + pi_q*qc_f(T,F)$(NOT F_EL(F))));
                                         value_taxes('DHN')     = EPS + sum((T,G_DH,F)$GF(G_DH,F), x_f.l(T,G_DH,F) * (tax_fuel_f(F) + tax_fuel_g(G_DH) + pi_q*qc_f(T,F)$(NOT F_EL(F))));

$ifi     %policytype% == 'socioeconomic' value_tariffs('WHS')   = EPS;
$ifi not %policytype% == 'socioeconomic' value_tariffs('WHS')   = EPS + sum((T,G_WH,F)$(GF(G_WH,F) AND F_EL(F)), tariff_v(T) * x_f.l(T,G_WH,F)) + sum(F, tariff_c(F) * y_f_used.l('WHS',F));
                                         value_tariffs('DHN')   = EPS + sum((T,G_DH,F)$(GF(G_DH,F) AND F_EL(F)), tariff_v(T) * x_f.l(T,G_DH,F)) + sum(F, tariff_c(F) * y_f_used.l('DHN',F));

value_support(E)       = EPS;

* The following is transfered to the integrated model
PARAMETERS
MarginalCostDHN_Ref(T)      'Reference marginal cost of DHN (EUR/MWh)'
MarginalCostWHS_Ref(T)      'Reference marginal cost of WHS (EUR/MWh)'
OperationalCost_Ref(E)      'Reference operating cost of each entity (EUR/year)'
Emissions_Ref(T)            'Reference CO2 emissions per heat production (kg/MWh)'
HeatProd_Ref(T,G_DH)        'Reference heat production (MWh)'
ColdProd_Ref(T,G_WH)        'Reference cold production (MWh)'
;

MarginalCostDHN_Ref(T)      = EPS + eq_load_heat.m(T);
MarginalCostWHS_Ref(T)      = EPS + sum((G_CO,F)$GF(G_CO,F), C_f(T,G_CO,F) * x_f.L(T,G_CO,F) + C_c(G_CO) * x_c.L(T,G_CO))/D_c(T);
OperationalCost_Ref(E)      = EPS + OPX.l(E);
Emissions_Ref(T)            = EPS + sum((G,F)$GF(G,F), w.l(T,G,F))/D_h(T);
HeatProd_Ref(T,G_DH)        = EPS + x_h.l(T,G_DH);
ColdProd_Ref(T,G_WH)        = EPS + x_c.l(T,G_WH);

execute_unload  './results/%project%/%scenario%/results-%scenario%-reference.gdx'
,
obj, OPX, x_f, x_h, x_e, x_c, w, z, y_f_used, x_s,
value_taxes, value_tariffs, value_support
;

execute_unload  './results/%project%/%scenario%/transfer-%scenario%-reference.gdx',
MarginalCostDHN_Ref, MarginalCostWHS_Ref, OperationalCost_Ref, Emissions_Ref, HeatProd_Ref, ColdProd_Ref
;



* ======================================================================
* END OF FILE
