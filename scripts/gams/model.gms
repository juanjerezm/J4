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
* --- Name flag ---
* Flag 'name' identifies the optimization run, setting directories and filenames.
* Results will be overwritten if 'name' is not unique. Do not use spaces or hyphens (-).

* $ifi not setglobal name     $SetGlobal name 'default'
$ifi not setglobal name     $SetGlobal name 'default'

* --- Solving flag ---
* Uncomment solving mode:
*   - 'single'      solves the model once, using assumed full-load hours
*   - 'iterative'   solves the model iteratively, updating full-load hours

* $ifi not setglobal mode     $SetGlobal mode 'single'
$ifi not setglobal mode     $SetGlobal mode 'iterative'

* --- Policy flag ---
* Uncomment policy setup to analyse:
*  - 'socioeconomic' does not include taxes, tariffs or support schemes,
*  - 'taxation'      includes energy/carbon taxes and electricity tariffs,
*  - 'support'       includes support schemes on top of taxation

* $ifi not setglobal policytype $SetGlobal policytype 'socioeconomic'
$ifi not setglobal policytype $SetGlobal policytype 'taxation'
* $ifi not setglobal policytype $SetGlobal policytype 'support'

* ----- Country flag -----
* Uncomment country to analyse:
$ifi not setglobal country  $SetGlobal country  'DK'
* $ifi not setglobal country  $SetGlobal country  'DE'
* $ifi not setglobal country  $SetGlobal country  'FR'

* ----- Directories, filenames, and scripts -----
* Create directories for output
$ifi %system.filesys% == msnt   $call 'mkdir    .\results\%name%\';
$ifi %system.filesys% == unix   $call 'mkdir -p ./results/%name%/';

* Execute the reference case
$call gams ./scripts/gams/model_reference o=./results/%name%/model_reference.lst --name=%name% --policytype=%policytype% --country=%country% 

* ----- Global scalars -----
SCALAR
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

lifetime(E)             'Lifetime of investment (years)'
r(E)                    'Discount rate of investment (-)'
AF(E)                   'Project annuity factor (-)'

C_f(T,G,F)              'Cost of fuel consumption (EUR/MWh)'
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_c(G)                  'Cost of cold production (EUR/MWh)'
C_e(G)                  'Cost of electricity production (EUR/MWh)'
C_g_fix(G)              'Fixed cost of generator (EUR/MW)'
C_g_inv(G)              'Investment cost of generator (EUR/MW)'
C_s(S)                  'Storage variable cost (EUR/MWh)'
C_s_inv(S)              'Fixed cost of storage (EUR/MWh)'
C_s_fix(S)              'Investment cost of storage (EUR/MWh)'
C_p_inv                 'Investment cost of pipe connection (EUR/MW-m)'

MC_DH(T)                'Marginal cost of DH (EUR/MWh)'
OPX_REF(E)              'Operating cost for entity (stakeholder) - reference case (EUR)'
CO2_REF(T)              'Mean carbon footprint of heat in reference case (kg/MWh)'
XH_ref(T,G)             'Reference heat production (MWh)'
XF_ref(T,G,F)           'Reference fuel consumption (MWh)'

MC_DH_month(M)          'Marginal cost of DH - monthly average (EUR/MWh)'
MC_HR(T,G)              'Marginal cost of HR units (EUR/MWh)'
MC_HR_month(M,G)        'Marginal cost of HR units - monthly average (EUR/MWh)'
MU_DH(G)                'Markup from DH investments (EUR/MWh)'
MU_HR(G)                'Markup from HR investments (EUR/MWh)'
N(G)                    'Full load hours of HR units (h)'

pi_h(T,G)               'Price of recovered heat (EUR/MWh)'
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
L_p(G)                  'Length of pipe connection (m)'
rho_g(G)                'Heat loss factor in pipe connection (-)'

Y_s(S)                  'Storage capacity (MWh)'
F_s_flo(S)              'Storage throughput capacity factor (-)'  
F_s_end(S)              'Final storage state-of-charge factor (-)'
F_s_min(S)              'Minimum storage state-of-charge factor (-)'
F_s_max(S)              'Maximum storage state-of-charge factor (-)'
rho_s(S)                'Storage self-discharge factor (-)'
eta_s(S)                'Storage throughput efficiency (-)'
;

$offlisting
* ----- Parameter definition -----
* - Direct assignment - (This should, ideally, be done in a separate data file)
* ETS quota price
pi_q            = 0.0853;

* DH transmission pipe, 0 - 50 MW
L_p(G_HR)       = 1000;
rho_g(G_HR)     = 0.03;
C_p_inv         = 25;

* Investment project parameters
lifetime('DHN') = 40;
lifetime('WHS') = 25;
r('DHN')        = 0.04;
r('WHS')        = 0.04;

* Initial estimation full load hours
N(G_HR)         = 8760;

* - Parameters from the reference case -
$gdxin './results/%name%/results-%name%-reference.gdx'
$load MC_DH, OPX_REF, CO2_REF, XH_ref, XF_ref 
$gdxin

* - One-dimensional parameters -
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
C_h(G)$(G_HR(G))        = GNRT_DATA(G,'variable cost - heat');
C_c(G)$(G_CO(G))        = GNRT_DATA(G,'variable cost - cold');
C_g_inv(G)$(G_HR(G))    = GNRT_DATA(G,'capital cost');
C_g_fix(G)$(G_HR(G))    = GNRT_DATA(G,'fixed cost');

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
* cold-only capacity defined by peak demand
Y_c(G_CO)               = smax(T, D_c(T));

* Mapping Hour-Month tariff to timestep tariff
tariff_v(T)             = SUM((H,M)$(TM(T,M) AND TH(T,H)), tariff_schedule_v(H,M));

*  Calculate fuel cost from fuel price, taxes (per fuel and generator), electricity tariffs and ETS quotas
C_f(T,G,F)$G_DH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));

* Fuel costs for WHS depend on the policy type
$ifi %policytype% == 'socioeconomic'    C_f(T,G,F)$G_WH(G)  = pi_f(T,F);
$ifi %policytype% == 'taxation'         C_f(T,G,F)$G_WH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));
$ifi %policytype% == 'support'          C_f(T,G,F)$G_WH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));

* Calculate annuity factor
AF(E)               = r(E) * (1 + r(E)) ** lifetime(E) / ((1 + r(E)) ** lifetime(E) - 1);

* Calculate marginal cost of HR units
MC_HR(T,G_HR)       = sum(F$GF(G_HR,F), C_f(T,G_HR,F))/eta_g(T,G_HR) + C_h(G_HR);

* Substract the cooling substitution cost from the HR marginal. This implementation is janky, but it works assuming that, in the reference case, free-cooling is always used when available.
MC_HR(T,G_HR)       = MC_HR(T,G_HR)
                    - ((sum(F$GF('free_cooling',F),     C_f(T,'free_cooling',F)    /eta_g(T,'free_cooling'))     + C_c('free_cooling'))/eta_g(T,G_HR))$(F_a(T,'free_cooling') GE 0) 
                    - ((sum(F$GF('electric_chiller',F), C_f(T,'electric_chiller',F)/eta_g(T,'electric_chiller')) + C_c('electric_chiller'))/eta_g(T,G_HR))$(F_a(T,'free_cooling') EQ 0)
                    ;

* Calculate monthly averages, and reassign values to each hour
MC_HR_month(M,G_HR) = sum(T$TM(T,M), MC_HR(T,G_HR))/730;
MC_DH_month(M)      = sum(T$TM(T,M), MC_DH(T))/730;
loop(T,
    MC_HR(T,G_HR)   = sum(M$TM(T,M), MC_HR_month(M,G_HR));
    MC_DH(T)        = sum(M$TM(T,M), MC_DH_month(M));
);

* Define initial mark-ups from investement costs, and availability factor from it
MU_DH(G_HR)     = (L_p(G_HR) * C_p_inv       * AF('DHN')                )/(N(G_HR) + D6);
MU_HR(G_HR)     = (            C_g_inv(G_HR) * AF('WHS') + C_g_fix(G_HR))/(N(G_HR) + D6);
pi_h(T,G_HR)    = ((MC_DH(T) - MU_DH(G_HR)) + (MC_HR(T,G_HR) + MU_HR(G_HR)))/2;
F_a(T,G_HR)$((MC_HR(T,G_HR) + MU_HR(G_HR)) GE (MC_DH(T) - MU_DH(G_HR))) = 0;

* add a small tolerance value so the MIP solver doesn't complain
OPX_REF(E) = 1  + OPX_REF(E);


* ----- Support policy section -----
PARAMETERS
k_inv_g(G)      'Investment subsidy fraction for HR units (-)'
k_inv_p         'Investment subsidy fraction for connection pipe (-)'
pi_h_ceil(G)    'Waste-heat ceiling price (EUR/MWh)'
;

* Default values without support policy
k_inv_g(G)      = 0;
k_inv_p         = 0;
pi_h_ceil(G)    = 0;

$ifi %policytype% == 'support' $include './scripts/gams/definition_policy.inc';

* ----- Temporary or auxiliary assignments -----


* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
NPV_all                     'Net present value of project - total (EUR)'
OPX(E)                      'Operating cost for entity (stakeholder) (EUR)'
WH_trnsctn                  'Transaction of waste-heat (EUR)'
;

POSITIVE VARIABLES
NPV(E)                      'Net present value for entity (stakeholder) (EUR)'
x_f(T,G,F)                  'Consumption of fuel by generator (MWh)'
x_h(T,G)                    'Production of heat (MWh)'
x_e(T,G)                    'Production of electricity (MWh)'
x_c(T,G)                    'Production of cold (MWh)'
z(T,S)                      'State-of-charge of storage (MWh)'
y_hr(G)                     'Heating capacity of heat-recovery generators (MWh)'
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
eq_NPV_all                  'Net Present Value (total)'
eq_NPV_DHN                  'Net Present Value for DHN'
eq_NPV_WHS                  'Net Present Value for WHS'
eq_OPX_DHN                  'Operating cost of DH system'
eq_OPX_WHS                  'Operating cost of WH source'
eq_trnsctn                  'Transaction of waste-heat'  

eq_load_heat(T)             'Heat load in DHN'
eq_load_cold(T)             'Cold load in WHS'

eq_conversion_CO(T,G)       'Conversion constraint for cold-only generators'
eq_conversion_HO(T,G)       'Conversion constraint for heat-only generators'
eq_conversion_BP_1(T,G)     'Conversion constraint for backpressure generators (energy balance)'
eq_conversion_BP_2(T,G)     'Conversion constraint for backpressure generators (elec-heat ratio)'
eq_conversion_EX_1(T,G)     'Conversion constraint for extraction generators (energy balance)'
eq_conversion_EX_2(T,G)     'Conversion constraint for extraction generators (elec-heat ratio)'
eq_conversion_HR_1(T,G)     'Conversion constraint for heat-recovery generators (energy balance)'
eq_conversion_HR_2(T,G)     'Conversion constraint for heat-recovery generators (heat-cold ratio)'

eq_max_DH(T,G)              'Capacity constraint for DH generators (input-based)'
eq_max_HR(T,G)              'Capacity constraint for heat-recovery generators (output-based)'
eq_max_CO(T,G)              'Capacity constraint for cold-only generators (output-based)'
eq_max_fueluse_DHN(T,F)     'Maximum fuel consumption by DHN at any timestep'
eq_max_fueluse_WHS(T,F)     'Maximum fuel consumption by WHS at any timestep'

eq_sto_balance(T,S)         'Storage balance'
eq_sto_end(T,S)             'Storage initial state of charge'
eq_sto_min(T,S)             'Storage minimum state of charge'
eq_sto_max(T,S)             'Storage maximum state of charge'
eq_sto_flo(T,S,SS)          'Storage throughput limit'
;

* ----- Equation definition -----
eq_NPV_all..                                NPV_all     =e= NPV('DHN') + NPV('WHS');

eq_NPV_DHN..                                NPV('DHN')  =e= - sum(G_HR, L_p(G_HR) * C_p_inv       * y_hr(G_HR) * (1 - k_inv_p      )) + (OPX_REF('DHN') - OPX('DHN') - WH_trnsctn)/AF('DHN');
eq_NPV_WHS..                                NPV('WHS')  =e= - sum(G_HR,             C_g_inv(G_HR) * y_hr(G_HR) * (1 - k_inv_g(G_HR))) + (OPX_REF('WHS') - OPX('WHS') + WH_trnsctn)/AF('WHS');

eq_OPX_DHN..                                OPX('DHN')  =e= + sum((T,G_DH,F)$GF(G_DH,F), C_f(T,G_DH,F) * x_f(T,G_DH,F))
                                                            + sum((T,G_HO),              C_h(G_HO)     * x_h(T,G_HO))
                                                            + sum((T,G_CHP),             C_e(G_CHP)    * x_e(T,G_CHP))
                                                            - sum((T,G_CHP),             pi_e(T)       * x_e(T,G_CHP))
$ifi not %policytype% == 'socioeconomic'                    + sum(F,                     tariff_c(F)   * y_f_used('DHN',F))
                                                            ;

eq_OPX_WHS..                                OPX('WHS')  =e= + sum((T,G_CO,F)$GF(G_CO,F), C_f(T,G_CO,F) * x_f(T,G_CO,F))
                                                            + sum((T,G_CO),              C_c(G_CO)     * x_c(T,G_CO))
                                                            + sum((T,G_HR,F)$GF(G_HR,F), C_f(T,G_HR,F) * x_f(T,G_HR,F))
                                                            + sum((T,G_HR),              C_h(G_HR)     * x_h(T,G_HR))
                                                            + sum(G_HR,                  C_g_fix(G_HR) * y_hr(G_HR))
$ifi not %policytype% == 'socioeconomic'                    + sum(F,                     tariff_c(F)   * y_f_used('WHS',F))
$ifi %policytype% == 'support' $ifi %country% == 'DE'       - pi_q * sum((T, G_HR), x_h(T,G_HR)*CO2_ref(T))
                                                            ;

eq_trnsctn..                                WH_trnsctn  =e= sum((T,G_HR), pi_h(T,G_HR)  * x_h(T,G_HR));

eq_load_heat(T)..                           sum(G_DH, x_h(T,G_DH)) + sum(G_HR, x_h(T,G_HR)*(1-rho_g(G_HR))) + sum(S_DH, x_s(T,S_DH,'discharge')) - sum(S_DH, x_s(T,S_DH,'charge')) =e= D_h(T);
eq_load_cold(T)..                           sum(G_WH, x_c(T,G_WH))                                                                                                                 =e= D_c(T);

eq_conversion_CO(T,G)$G_CO(G)..             eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e= x_c(T,G);
eq_conversion_HO(T,G)$G_HO(G)..             eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G);
eq_conversion_BP_1(T,G)$G_BP(G)..           eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G) + x_e(T,G);
eq_conversion_BP_2(T,G)$G_BP(G)..                                                 0 =e= beta_b(G) * x_h(T,G) - x_e(T,G);
eq_conversion_EX_1(T,G)$G_EX(G)..           eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e= beta_v(G) * x_h(T,G) + x_e(T,G);
eq_conversion_EX_2(T,G)$G_EX(G)..                                                 0 =g= beta_b(G) * x_h(T,G) - x_e(T,G);
eq_conversion_HR_1(T,G)$G_HR(G)..                        sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G) - x_c(T,G);
eq_conversion_HR_2(T,G)$G_HR(G)..           eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G);

eq_max_DH(T,G)$G_DH(G)..                                 sum(F$GF(G,F), x_f(T,G,F)) =l= F_a(T,G)*Y_f(G);
eq_max_CO(T,G)$G_CO(G)..                                                x_c(T,G)    =l= F_a(T,G)*Y_c(G);
eq_max_HR(T,G)$G_HR(G)..                                                x_h(T,G)    =l= F_a(T,G)*y_hr(G);
eq_max_fueluse_DHN(T,F)..                       sum(G_DH$GF(G_DH,F), x_f(T,G_DH,F)) =l= y_f_used('DHN',F);
eq_max_fueluse_WHS(T,F)..                       sum(G_WH$GF(G_WH,F), x_f(T,G_WH,F)) =l= y_f_used('WHS',F);

eq_sto_balance(T,S)..                       z(T,S)      =e= (1-rho_s(S)) * z(T--1,S) + eta_s(S)*x_s(T,S,'charge') - x_s(T,S,'discharge')/eta_s(S);
eq_sto_end(T,S)$(ord(T)=card(T))..          z(T,S)      =e= F_s_end(S) * Y_s(S);
eq_sto_min(T,S)..                           z(T,S)      =g= F_s_min(S) * Y_s(S);
eq_sto_max(T,S)..                           z(T,S)      =l= F_s_max(S) * Y_s(S);
eq_sto_flo(T,S,SS)..                        x_s(T,S,SS) =l= F_s_flo(S) * Y_s(S);


* ======================================================================
* MODEL
* ======================================================================
* ----- Model definition -----
model 
mdl_all              'All equations'    /all/
;

mdl_all.optfile = 1;

* ======================================================================
* SOLVE AND POSTPROCESSING
* ======================================================================

$ifi %mode% == 'single'     $include './scripts/gams/solve_single.inc';
$ifi %mode% == 'iterative'  $include './scripts/gams/solve_iterative.inc';

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

$ifi not %policytype% == 'support'       value_support(E)       = 0;
$ifi     %policytype% == 'support'       $include './scripts/gams/value_policy.inc';
 
execute_unload './results/%name%/results-%name%-integrated.gdx'
* ======================================================================
* END OF FILE
