* ======================================================================
* DESCRIPTION
* ======================================================================
* ----- INFO -----
* Written by Juan Jerez, jujmo@dtu.dk, 2024.
*
* This script solves the reference case without waste-heat recovery (WHR).
* It imports the full parameter set from parameters.gdx and optimizes
* operating expenditure for DHN and WHS under independent operation.
*
* Main outputs:
* - ./results/%scenario%/gdx/results-reference.gdx
* - ./results/%scenario%/gdx/transfer-reference.gdx
*   (marginal costs, emissions intensities, and warm-start trajectories used by
*   model_integrated.gms).


* ======================================================================
*  SETUP
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


* ----- Control flag definition -----
* $include './scripts/gams/manual-control-flag-definition.inc'   !! Manual control flag definition


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
M                       'Months'
E                       'Entity'
G                       'Generators'
S                       'Storages'
SS                      'Storage state (SOS1 set)'
F                       'Fuels'
TM(T,M)                 'Timestep-month mapping'
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
G_EL(G)                 'Electricity-consuming generators'
;


* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
D_h(T)                  'Demand of heat (MW)'
D_c(T)                  'Demand of cold (MW)'

w_f(T,F)                'Carbon content of fuel (kg/MWh)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_q(G)                 'Price of ETS emission quota (EUR/kg-CO2)'

tax_f(G)                'Tax on fuel consumption (EUR/MWh)'
tax_h(G)                'Tax on heat production (EUR/MWh)'
tax_c(G)                'Tax on cold production (EUR/MWh)'
tax_e(G)                'Tax on electricity production (EUR/MWh)'
tax_w(G)                'Tax on emissions (EUR/kg-CO2)'

tariff_v(T,G)           'Volumetric electricity tariff (EUR/MWh)'
tariff_c(G)             'Capacity electricity tariff (EUR/MW)'
tariff_c_WHS            'Capacity electricity tariff - single grid connection (EUR/MW)'

C_f(T,G,F)              'Cost of fuel consumption (EUR/MWh)'
C_h(G)                  'Cost of heat production (EUR/MWh)'
C_c(G)                  'Cost of cold production (EUR/MWh)'
C_e(G)                  'Cost of electricity production (EUR/MWh)'

Y_c(G)                  'Cooling capacity - cold-only units (MW)'
Y_f(G)                  'Firing capacity - DH units (MW)'
F_a(T,G)                'Generator availabity factor (-)'
eta_g(T,G)              'Generator efficiency (-), (BP: total, EX: condensing)'
beta_b(G)               'CHP Cb coefficient (-)'
beta_v(G)               'CHP Cv coefficient (-)'

C_s(S)                  'Variable cost of storage (EUR/MWh)'
Y_s(S)                  'Storage capacity (MWh)'
eta_s(S)                'Storage throughput efficiency (-)'
rho_s(S)                'Storage self-discharge factor (-)'
F_s_flo(S)              'Storage throughput factor (-)'  
F_s_end(S)              'Storage final state-of-charge factor (-)'
F_s_min(S)              'Storage minimum state-of-charge factor (-)'
F_s_max(S)              'Storage maximum state-of-charge factor (-)'
;

* ----- Parameter definition -----
$gdxin './results/%scenario%/gdx/parameters.gdx'
$load T, M, G, S, SS, E, F, TM, GF                                              !! sets
$load G_BP, G_EX, G_HO, G_CO, G_HR, G_CHP, G_DH, G_WH, S_DH, S_WH, F_EL, G_EL   !! subsets
$load C_f, C_h, C_c, C_e, Y_c, Y_f, F_a, eta_g, beta_b, beta_v                  !! generator parameters
$load C_s, Y_s, eta_s, rho_s, F_s_flo, F_s_end, F_s_min, F_s_max                !! storage parameters
$load tariff_v, tariff_c, tariff_c_WHS                                          !! tariff parameters      
$load tax_f, tax_h, tax_c, tax_e, tax_w                                         !! tax parameters
$load D_h, D_c, w_f, pi_e, pi_q                                                 !! others
$gdxin

* ----- Parameter operations -----


* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
obj                         'Auxiliary objective variable (EUR), to optimize both DHN and WHS OPEXs'
OPEX(E)                     'Operating expenditure (EUR)'
;

POSITIVE VARIABLES
x_f(T,G,F)                  'Consumption of fuel (MWh)'
x_h(T,G)                    'Production of heat (MWh)'
x_e(T,G)                    'Production of electricity (MWh)'
x_c(T,G)                    'Production of cold (MWh)'
w(T,G,F)                    'Carbon emissions (kg)'
z(T,S)                      'State-of-charge of storage (MWh)'

x_f_max_DHN(G)              'Maximum fuel (electricity) consumption of DHN generators (MW)'
x_f_max_WHS                 'Maximum fuel (electricity) consumption at WHS (MW)'

QuotaPayment(E)             'ETS quota payments (EUR)'
TaxPayment(E)               'Tax payments (EUR)'
TariffPayment(E)            'Tariff payments (EUR)'
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
eq_OPEX_DHN                 'Operating expenditure of DHN'
eq_OPEX_WHS                 'Operating expenditure of WHS'

eq_taxes_DHN                'Tax payments of DHN'
eq_taxes_WHS                'Tax payments of WHS'
eq_tariffs_DHN              'Tariff payments of DHN'
eq_tariffs_WHS              'Tariff payments of WHS'
eq_quotas_DHN               'ETS quota payments of DHN'
eq_quotas_WHS               'ETS quota payments of WHS'

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
eq_max_elec_DHN(T,G,F)      'Maximum individual electricity consumption of DHN generators'
eq_max_elec_WHS(T)          'Maximum joint electricity consumption of WHS generators'

eq_carbon_emissions(T,G,F)  'Carbon emissions of generators'

eq_sto_balance(T,S)         'Storage balance'
eq_sto_end(T,S)             'Storage initial state-of-charge'
eq_sto_min(T,S)             'Storage minimum state-of-charge'
eq_sto_max(T,S)             'Storage maximum state-of-charge'
eq_sto_flo(T,S,SS)          'Storage throughput limit'
;

* ----- Equation definition -----
* Variable cost of storages are negligible
eq_obj..                                    obj         =e= OPEX('DHN') + OPEX('WHS');
eq_OPEX_DHN..                               OPEX('DHN') =e= + sum((T,G_DH,F)$GF(G_DH,F), C_f(T,G_DH,F) * x_f(T,G_DH,F))
                                                            + sum((T,G_DH),              C_h(G_DH)     * x_h(T,G_DH))
                                                            + sum((T,G_CHP),             C_e(G_CHP)    * x_e(T,G_CHP))
                                                            + sum((T,S_DH),              C_s(S_DH)     * x_s(T,S_DH,'discharge'))
                                                            - sum((T,G_CHP),             pi_e(T)       * x_e(T,G_CHP))
                                                            + TaxPayment('DHN') + TariffPayment('DHN') + QuotaPayment('DHN')
                                                            ;

eq_OPEX_WHS..                               OPEX('WHS') =e= + sum((T,G_CO,F)$GF(G_CO,F), C_f(T,G_CO,F) * x_f(T,G_CO,F))
                                                            + sum((T,G_CO),              C_c(G_CO)     * x_c(T,G_CO))
                                                            + TaxPayment('WHS') + TariffPayment('WHS') + QuotaPayment('WHS')
                                                            ;

eq_taxes_DHN..                       TaxPayment('DHN')  =e= + sum((T,G_DH),              x_h(T,G_DH)   * tax_h(G_DH))
                                                            + sum((T,G_DH),              x_e(T,G_DH)   * tax_e(G_DH))
                                                            + sum((T,G_DH),              x_c(T,G_DH)   * tax_c(G_DH))
                                                            + sum((T,G_DH,F)$GF(G_DH,F), x_f(T,G_DH,F) * tax_f(G_DH))
                                                            + sum((T,G_DH,F)$GF(G_DH,F), w(T,G_DH,F)   * tax_w(G_DH))
                                                            ;

eq_taxes_WHS..                       TaxPayment('WHS')  =e= + sum((T,G_CO),              x_c(T,G_CO)   * tax_c(G_CO))
                                                            + sum((T,G_CO,F)$GF(G_CO,F), x_f(T,G_CO,F) * tax_f(G_CO))
                                                            + sum((T,G_CO,F)$GF(G_CO,F), w(T,G_CO,F)   * tax_w(G_CO))
                                                            ;

eq_tariffs_DHN..                   TariffPayment('DHN') =e= + sum((T,G_DH,F)$(GF(G_DH,F) AND F_EL(F)), tariff_v(T, G_DH) * x_f(T,G_DH,F))
                                                            + sum(G_DH$G_EL(G_DH),                     tariff_c(G_DH)    * x_f_max_DHN(G_DH))
                                                            ;

eq_tariffs_WHS..                   TariffPayment('WHS') =e= + sum((T,G_CO,F)$(GF(G_CO,F) AND F_EL(F)), tariff_v(T, G_CO) * x_f(T,G_CO,F))
                                                            +                                          tariff_c_WHS      * x_f_max_WHS
                                                            ;

eq_quotas_DHN..                     QuotaPayment('DHN') =e= + sum((T,G_DH,F)$GF(G_DH,F), w(T,G_DH,F) * pi_q(G_DH));
eq_quotas_WHS..                     QuotaPayment('WHS') =e= + sum((T,G_CO,F)$GF(G_CO,F), w(T,G_CO,F) * pi_q(G_CO));

eq_load_heat(T)..                           sum(G_DH, x_h(T,G_DH)) + sum(S_DH, x_s(T,S_DH,'discharge')) - sum(S_DH, x_s(T,S_DH,'charge')) =e= D_h(T); !! Demand on RHS for proper marginal calculation
eq_load_cold(T)..                           sum(G_CO, x_c(T,G_CO))                                                                        =e= D_c(T); !! Demand on RHS for proper marginal calculation

eq_conversion_CO(T,G)$G_CO(G)..             eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e= x_c(T,G);
eq_conversion_HO(T,G)$G_HO(G)..             eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G);
eq_conversion_BP_1(T,G)$G_BP(G)..           eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e=             x_h(T,G) + x_e(T,G);
eq_conversion_BP_2(T,G)$G_BP(G)..                                                 0 =e= beta_b(G) * x_h(T,G) - x_e(T,G);
eq_conversion_EX_1(T,G)$G_EX(G)..           eta_g(T,G) * sum(F$GF(G,F), x_f(T,G,F)) =e= beta_v(G) * x_h(T,G) + x_e(T,G);
eq_conversion_EX_2(T,G)$G_EX(G)..                                                 0 =g= beta_b(G) * x_h(T,G) - x_e(T,G);

eq_max_DH(T,G)$G_DH(G)..                                 sum(F$GF(G,F), x_f(T,G,F)) =l= F_a(T,G)*Y_f(G);
eq_max_CO(T,G)$G_CO(G)..                                                x_c(T,G)    =l= F_a(T,G)*Y_c(G);
eq_max_elec_DHN(T,G,F)$(G_DH(G) AND G_EL(G) AND GF(G,F))..           x_f_max_DHN(G) =g= x_f(T,G,F);
eq_max_elec_WHS(T)..                                                 x_f_max_WHS    =g= sum((G_CO,F)$(G_EL(G_CO) AND GF(G_CO,F)), x_f(T,G_CO,F));

eq_carbon_emissions(T,G,F)$GF(G,F)..                            w_f(T,F)*x_f(T,G,F) =e= w(T,G,F);

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
* SOLVE
* ======================================================================
solve mdl_all using mip minimizing obj;


* ======================================================================
* OUTPUT
* ======================================================================
* The following parameters are transfered for use in the integrated model
PARAMETERS
MarginalCostDHN_REF(T)      'Reference marginal cost of DHN (EUR/MWh)'
MarginalCostWHS_REF(T)      'Reference marginal cost of WHS (EUR/MWh)'
;

MarginalCostDHN_REF(T)      = EPS + eq_load_heat.m(T);
MarginalCostWHS_REF(T)      = EPS + eq_load_cold.m(T);

execute_unload  './results/%scenario%/gdx/results-reference.gdx',
x_f, x_h, x_e, x_c, w, z, x_s
obj, OPEX, TariffPayment, TaxPayment, QuotaPayment
MarginalCostDHN_REF, MarginalCostWHS_REF
;


* ======================================================================
* END OF FILE
