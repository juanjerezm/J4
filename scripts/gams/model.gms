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
* * Set default values if script not called from another script or command line
* $ifi not setglobal project    $setGlobal project      'default_prj'
* $ifi not setglobal scenario   $setGlobal scenario     'default_scn'
* $ifi not setglobal policytype $setGlobal policytype   'taxation'
* $ifi not setglobal country    $setGlobal country      'DK'
* $ifi not setglobal mode       $SetGlobal mode         'iterative'         !! Choose between 'single' and 'iterative'

* * ----- Directories, filenames, and scripts -----
* * Create directories for output
* $ifi %system.filesys% == msnt   $call 'mkdir    .\results\%project%\%scenario%\';
* $ifi %system.filesys% == unix   $call 'mkdir -p ./results/%project%/%scenario%/';

* * Execute the reference case
* $call gams ./scripts/gams/parameters      --project=%project% --scenario=%scenario% --policytype=%policytype% --country=%country% o=./results/%project%/%scenario%/parameters.lst
* $call gams ./scripts/gams/model_reference --project=%project% --scenario=%scenario% --policytype=%policytype% --country=%country% o=./results/%project%/%scenario%/model_reference.lst

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
C_p_inv(G)              'Investment cost of pipe connection (EUR/MW-m)'

OPX_REF(E)              'Reference operating cost for entity (stakeholder) (EUR)'
w_ref(T)                'Reference mean carbon footprint of heat (kg/MWh)'
x_h_ref(T,G)            'Reference heat production (MWh)'
x_c_ref(T,G)            'Reference cold production (MWh)'
x_s_ref(T,S,ss)         'Reference storage operation (MWh)'
z_ref(T,S)              'Reference storage state-of-charge (MWh)'

SubstitutionCost(T)     'Substitution cost of cooling (EUR/MWh)'
MarginalBid(T)          'Marginal cost-component of bid-price, from DH marginal cost in reference case (EUR/MWh)'
MarginalAsk(T,G)        'Marginal cost-component of ask-price, from marginal cost of HR units (EUR/MWh)'
MarginalBid_month(M)    'Marginal cost-component of bid-price - monthly average (EUR/MWh)'
MarginalAsk_month(M,G)  'Marginal cost-component of ask-price - monthly average (EUR/MWh)'
FixedBid(G)             'Fixed cost-component of bid-price, from DH investments (EUR/MWh)'
FixedAsk(G)             'Fixed cost-component of ask-price, from HR investments (EUR/MWh)'
BidPrice(T,G_HR)        'Maximum feasible price for DHU (EUR/MWh)'
AskPrice(T,G_HR)        'Minimum feasible price for WHS (EUR/MWh)'
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

k_inv_g(G)              'Investment subsidy fraction for HR units (-)'
k_inv_p                 'Investment subsidy fraction for connection pipe (-)'
pi_h_ceil(G)            'Waste-heat ceiling price (EUR/MWh)'
;

* ----- Parameter definition -----
* - Direct assignment - (This should, ideally, be done in a separate data file)
$gdxin './results/%project%/%scenario%/parameters.gdx'
$load T, H, M, G, S, SS, E, F, TM, TH, GF                                       !! Load sets
$load G_BP, G_EX, G_HO, G_CO, G_HR, G_CHP, G_DH, G_WH, S_DH, S_WH, F_EL         !! Load subsets
$load lifetime, r, AF                                                           !! Load entity parameters
$load D_h, D_c                                                                  !! Load system parameters
$load C_e, C_h, C_c, C_g_inv, C_g_fix, Y_c, Y_f, F_a, eta_g, beta_b, beta_v     !! Load generator parameters
$load C_p_inv, L_p, rho_g                                                       !! Load connection parameters
$load C_f, pi_f, qc_f, pi_q, pi_e, qc_e                                         !! Load fuel parameters
$load tax_fuel_f, tariff_c, tariff_v, tax_fuel_g                                !! Load tax-and-tariff parameters
$load C_s, Y_s, eta_s, rho_s, F_s_flo, F_s_end, F_s_min, F_s_max                !! Load storage parameters
$load k_inv_g, k_inv_p, pi_h_ceil                                               !! Load policy parameters
$gdxin

* - Parameters from the reference case -
$gdxin './results/%project%/%scenario%/transfer-%scenario%-reference.gdx'
$load MarginalBid=MarginalCostDHN_Ref,
$load SubstitutionCost=MarginalCostWHS_Ref,
$load OPX_REF=OperationalCost_Ref,
$load w_ref=EmissionsDHN_Ref,
$load x_h_ref=HeatProd_Ref,
$load x_c_ref=ColdProd_Ref,
$load x_s_ref=StorageProd_Ref
$load z_ref=StorageLevel_Ref
$gdxin


* ----- Parameter operations -----
N(G_HR)                     = 8760;     !! Initial estimation of full load hours for HR units

* Calculate marginal cost of HR units (€/MWh-heat)
MarginalAsk(T,G_HR)         = sum(F$GF(G_HR,F), C_f(T,G_HR,F))/eta_g(T,G_HR) + C_h(G_HR);

* And substract the substitution cost of cooling (€/MWh-cold), adjusted by the ratio heat-cold
MarginalAsk(T,G_HR)         = MarginalAsk(T,G_HR) - SubstitutionCost(T) * (eta_g(T,G_HR) - 1)/eta_g(T,G_HR);

* Calculate monthly averages, and reassign values to each hour
MarginalAsk_month(M,G_HR)   = sum(T$TM(T,M), MarginalAsk(T,G_HR)  )/730;
MarginalBid_month(M)        = sum(T$TM(T,M), MarginalBid(T)       )/730;
loop(T,
    MarginalAsk(T,G_HR)     = sum(M$TM(T,M), MarginalAsk_month(M,G_HR));
    MarginalBid(T)          = sum(M$TM(T,M), MarginalBid_month(M));
);

* Define initial mark-ups from investement costs, and availability factor from it
FixedBid(G_HR)              = (L_p(G_HR) * C_p_inv(G_HR) * AF('DHN')                )/(N(G_HR) + D6) * (1 - k_inv_p);         !! Adjusted by the subsidy factor
FixedAsk(G_HR)              = (            C_g_inv(G_HR) * AF('WHS') + C_g_fix(G_HR))/(N(G_HR) + D6) * (1 - k_inv_g(G_HR));   !! Adjusted by the subsidy factor

BidPrice(T,G_HR)            = MarginalBid(T)      - FixedBid(G_HR);
AskPrice(T,G_HR)            = MarginalAsk(T,G_HR) + FixedAsk(G_HR);
pi_h(T,G_HR)                = (BidPrice(T,G_HR) + AskPrice(T,G_HR))/2;  !! Price for recovered waste heat mean between bid and ask

F_a(T,G_HR)$( AskPrice(T,G_HR) GE BidPrice(T,G_HR) ) = 0;

* Apply price-ceiling for waste-heat (DK - support)
$ifi %country% == 'DK' $ifi %policytype% == 'support' pi_h(T,G_HR)$(pi_h(T,G_HR) GE (pi_h_ceil(G_HR)-FixedBid(G_HR))) = pi_h_ceil(G_HR)-FixedBid(G_HR);


* ----- Temporary or auxiliary assignments -----


* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
NPV_all                     'Net present value of project - total (EUR)'
OPX(E)                      'Operating cost for entity (stakeholder) (EUR)'
WH_transaction              'Transaction value of waste-heat (EUR)'
;

POSITIVE VARIABLES
NPV(E)                      'Net present value for entity (stakeholder) (EUR)'
CAPEX(E)                    'Capital expenditure for entity (stakeholder) (EUR)'
x_f(T,G,F)                  'Consumption of fuel by generator (MWh)'
x_h(T,G)                    'Production of heat (MWh)'
x_e(T,G)                    'Production of electricity (MWh)'
x_c(T,G)                    'Production of cold (MWh)'
w(T,G,F)                    'Carbon emissions of generator (kg)'
z(T,S)                      'State-of-charge of storage (MWh)'
y_hr(G)                     'Heating capacity of heat-recovery generators (MWh)'
y_f_used(E,F)               'Maximum fuel consumption of fuel per entity at any timestep (MW)'
;

SOS1 VARIABLES
x_s(T,S,SS)                 'Storage charge/discharge flow (MWh)'
;

* ----- Variable attributes -----
* Warm-starting the model
x_h.l(T,G_DH) = x_h_ref(T,G_DH);
x_c.l(T,G_WH) = x_c_ref(T,G_WH);
x_s.l(T,S,SS) = x_s_ref(T,S,SS);
z.l(T,S)      = z_ref(T,S);


* ======================================================================
* EQUATIONS
* ======================================================================
* ----- Equation declaration -----
EQUATIONS
eq_NPV_all                  'Net Present Value (total)'
eq_NPV_DHN                  'Net Present Value for DHN'
eq_NPV_WHS                  'Net Present Value for WHS'
eq_CAPEX_DHN                'Capital expenditure for DHN'
eq_CAPEX_WHS                'Capital expenditure for WHS'
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

eq_carbon_emissions(T,G,F)  'Carbon emissions of generators'

eq_sto_balance(T,S)         'Storage balance'
eq_sto_end(T,S)             'Storage initial state of charge'
eq_sto_min(T,S)             'Storage minimum state of charge'
eq_sto_max(T,S)             'Storage maximum state of charge'
eq_sto_flo(T,S,SS)          'Storage throughput limit'
;

* ----- Equation definition -----
* Variable cost of storages are negligible
eq_NPV_all..                                NPV_all     =e= NPV('DHN') + NPV('WHS');

* Added small tolerance so the MIP solver doesn't complain
eq_NPV_DHN..                                NPV('DHN')  =e= - CAPEX('DHN') + (OPX_REF('DHN') - OPX('DHN') - WH_transaction)/AF('DHN') + D6;
eq_NPV_WHS..                                NPV('WHS')  =e= - CAPEX('WHS') + (OPX_REF('WHS') - OPX('WHS') + WH_transaction)/AF('WHS') + D6;

eq_CAPEX_DHN..                              CAPEX('DHN')=e= + sum(G_HR, L_p(G_HR) * C_p_inv(G_HR) * y_hr(G_HR) * (1 - k_inv_p      ));
eq_CAPEX_WHS..                              CAPEX('WHS')=e= + sum(G_HR,             C_g_inv(G_HR) * y_hr(G_HR) * (1 - k_inv_g(G_HR)));

eq_OPX_DHN..                                OPX('DHN')  =e= + sum((T,G_DH,F)$GF(G_DH,F), C_f(T,G_DH,F) * x_f(T,G_DH,F))
                                                            + sum((T,G_HO),              C_h(G_HO)     * x_h(T,G_HO))
                                                            + sum((T,S_DH),              C_s(S_DH)     * x_s(T,S_DH,'discharge'))
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
$ifi %policytype% == 'support' $ifi %country% == 'DE'       - pi_q * sum((T, G_HR), x_h(T,G_HR)*w_ref(T))
                                                            ;

eq_trnsctn..                                WH_transaction  =e= sum((T,G_HR), pi_h(T,G_HR)  * x_h(T,G_HR));

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

eq_carbon_emissions(T,G,F)$GF(G,F)..                           qc_f(T,F)*x_f(T,G,F) =e= w(T,G,F);

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
* SOLVE
* ======================================================================

$ifi %mode% == 'single'     $include './scripts/gams/solve_single.inc';
$ifi %mode% == 'iterative'  $include './scripts/gams/solve_iterative.inc';


* ======================================================================
* OUTPUT
* ======================================================================
AskPrice(T,G_HR)        = EPS + AskPrice(T,G_HR);
BidPrice(T,G_HR)        = EPS + BidPrice(T,G_HR);
MarginalAsk(T,G_HR)     = EPS + MarginalAsk(T,G_HR);
MarginalBid(T)          = EPS + MarginalBid(T);
FixedAsk(G_HR)          = EPS + FixedAsk(G_HR);
FixedBid(G_HR)          = EPS + FixedBid(G_HR);
pi_h(T,G_HR)            = EPS + pi_h(T,G_HR);

execute_unload './results/%project%/%scenario%/results-%scenario%-integrated.gdx',
$ifi %mode% == 'iterative' log_n, N
NPV_all, NPV, OPX, CAPEX, WH_transaction,
x_f, x_h, x_e, x_c, w, z, y_hr, y_f_used, x_s
pi_h, AskPrice, BidPrice, MarginalAsk, MarginalBid, FixedAsk, FixedBid
;


* ======================================================================
* END OF FILE
