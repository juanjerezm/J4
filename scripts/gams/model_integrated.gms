* ======================================================================
* DESCRIPTION
* ======================================================================
* ----- INFO -----
* Written by Juan Jerez, jujmo@dtu.dk, 2024.
*
* This script solves the integrated case with potential waste-heat recovery.
* It imports core inputs from parameters.gdx and baseline transfer values from
* transfer-reference.gdx, then maximizes total project NPV across DHN and WHS.
* Depending on solve_mode, the model is solved once (static) or iteratively
* while updating full-load-hour dependent mark-ups.
*
* Main output:
* - ./results/%scenario%/gdx/results-integrated.gdx
*   (economic KPIs, prices, capacities, and dispatch variables).


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

lifetime(E)             'Lifetime of investment (years)'
r(E)                    'Discount rate of investment (-)'
AF(E)                   'Project annuity factor (-)'

D_h(T)                  'Demand of heat (MW)'
D_c(T)                  'Demand of cold (MW)'

w_f(T,F)                'Carbon content of fuel (kg/MWh)'

pi_h(T,G)               'Price of recovered heat (EUR/MWh)'
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
C_y(G)                  'Cost per capacity installed - fixed O&M (EUR/MW)'
K_g(G)                  'Investment cost of generator (EUR/MW)'

Y_c(G)                  'Cooling capacity - cold-only units (MW)'
Y_f(G)                  'Firing capacity - DH units (MW)'
F_a(T,G)                'Generator availabity factor (-)'
eta_g(T,G)              'Generator efficiency (-), (BP: total, EX: condensing)'
beta_b(G)               'CHP Cb coefficient (-)'
beta_v(G)               'CHP Cv coefficient (-)'

K_p(G)                  'Investment cost of piping connection (EUR/MW-m)'
L_p(G)                  'Piping connection length (m)'
rho_p(G)                'Piping connection heat loss factor (-)'

C_s(S)                  'Variable cost of storage (EUR/MWh)'
Y_s(S)                  'Storage capacity (MWh)'
eta_s(S)                'Storage throughput efficiency (-)'
rho_s(S)                'Storage self-discharge factor (-)'
F_s_flo(S)              'Storage throughput factor (-)'  
F_s_end(S)              'Storage final state-of-charge factor (-)'
F_s_min(S)              'Storage minimum state-of-charge factor (-)'
F_s_max(S)              'Storage maximum state-of-charge factor (-)'

psi_k_g(G)              'CAPEX subsidiy fraction - generation (-)'
psi_k_p(G)              'CAPEX subsidiy fraction - piping (-)'
psi_c_h(T,G)            'OPEX subsidiy (EUR/Mwh)'

SubstitutionCost(T)     'Substitution cost of cooling (EUR/MWh)'
AskMarginal(T,G)        'Marginal component of ask-price, from HR unit marginal operation cost (EUR/MWh)'
BidMarginal(T)          'Marginal component of bid price, from DH marginal cost in reference case (EUR/MWh)'
AskMarginal_month(M,G)  'Marginal component of ask-price, monthly average (EUR/MWh)'
BidMarginal_month(M)    'Marginal component of bid-price, monthly average (EUR/MWh)'
AskFixed(G)             'Fixed component of ask-price, from HR investments (EUR/MWh)'
BidFixed(G)             'Fixed component of bid-price, from DH investments (EUR/MWh)'
AskPrice(T,G_HR)        'Minimum feasible price for WHS (EUR/MWh)'
BidPrice(T,G_HR)        'Maximum feasible price for DHN (EUR/MWh)'
N(G_HR)                 'Full-load hours equivalent (hours)'

OPEX_REF(E)             'Operating expenditure in reference case (EUR)'
x_f_REF(T,G,F)          'Fuel consumption in reference case (MWh)'
x_h_REF(T,G)            'Heat production in reference case (MWh)'
x_e_REF(T,G)            'Electricity production in reference case (MWh)'
x_c_REF(T,G)            'Cold production in reference case (MWh)'
x_s_REF(T,S,ss)         'Storage charge/discharge in reference case (MWh)'
z_REF(T,S)              'Storage state-of-charge in reference case (MWh)'
;

* ----- Parameter definition -----
$gdxin './results/%scenario%/gdx/parameters.gdx'
$load T, M, G, S, SS, E, F, TM, GF                                              !! sets
$load G_BP, G_EX, G_HO, G_CO, G_HR, G_CHP, G_DH, G_WH, S_DH, S_WH, F_EL, G_EL   !! subsets
$load lifetime, r, AF                                                           !! entity parameters
$load C_f, C_h, C_c, C_e, Y_c, Y_f, F_a, eta_g, beta_b, beta_v, K_g, C_y        !! generator parameters
$load C_s, Y_s, eta_s, rho_s, F_s_flo, F_s_end, F_s_min, F_s_max                !! storage parameters
$load K_p, L_p, rho_p                                                           !! connection parameters
$load tariff_v, tariff_c, tariff_c_WHS                                          !! tariff parameters
$load tax_f, tax_h, tax_c, tax_e, tax_w                                         !! tax parameters
$load psi_k_g, psi_k_p, psi_c_h,                                                !! policy parameters
$load D_h, D_c, w_f, pi_e, pi_q                                                 !! others
$gdxin

* * - Values from the reference case -
$gdxin './results/%scenario%/gdx/results-reference.gdx'
$load OPEX_REF=OPEX.l                                                                       !! For NPV calculation
$load x_f_REF=x_f.l, x_h_REF=x_h.l, x_e_REF=x_e.l, x_c_REF=x_c.l, x_s_REF=x_s.l, z_REF=z.l  !! For warm startup
$load BidMarginal=MarginalCostDHN_REF, SubstitutionCost=MarginalCostWHS_REF                 !! For bid/ask calculation
$gdxin

* ----- Parameter operations -----
N(G_HR)                     = 8760;     !! Initial estimation of full load hours for HR units

* Calculate marginal cost of HR units (€/MWh-heat)
AskMarginal(T,G_HR)         = + sum(F$GF(G_HR,F), C_f(T,G_HR,F) + tax_f(G_HR) + tariff_v(T,G_HR))/eta_g(T,G_HR) !! Fuel-input costs
                              + C_h(G_HR) + tax_h(G_HR)                         !! Heat-output costs
                              - psi_c_h(T,G_HR)                                 !! OPEX subsidy
                              - SubstitutionCost(T) * (1 - 1/eta_g(T,G_HR))     !! Cooling substitution cost (adjusted by the heat-to-cold ratio)
                            ;

* Calculate monthly averages of marginal bid/ask price components
AskMarginal_month(M,G_HR)   = sum(T$TM(T,M), AskMarginal(T,G_HR)  )/730;
BidMarginal_month(M)        = sum(T$TM(T,M), BidMarginal(T)       )/730;

* Reassing monthly values to each timestep
loop(T,
    AskMarginal(T,G_HR)     = sum(M$TM(T,M), AskMarginal_month(M,G_HR));
    BidMarginal(T)          = sum(M$TM(T,M), BidMarginal_month(M));
);

* Calculate fixed bid/ask price components based on investment and fixed O&M costs
BidFixed(G_HR)              = (L_p(G_HR) * K_p(G_HR) * AF('DHN')            )/(N(G_HR) + D6) * (1 - psi_k_p(G_HR));   !! Adjusted by the subsidy factor
AskFixed(G_HR)              = (            K_g(G_HR) * AF('WHS') + C_y(G_HR))/(N(G_HR) + D6) * (1 - psi_k_g(G_HR));   !! Adjusted by the subsidy factor

* Calculate bid and ask prices and final price of recovered heat
BidPrice(T,G_HR)            = BidMarginal(T)      - BidFixed(G_HR);
AskPrice(T,G_HR)            = AskMarginal(T,G_HR) + AskFixed(G_HR);
pi_h(T,G_HR)                = 0.5*(BidPrice(T,G_HR) + AskPrice(T,G_HR));  !! Waste-heat price is assumed midrange between bid and ask prices

* If ask price is lower than the bid price, availability of HR units is set to zero.
F_a(T,G_HR)$(AskPrice(T,G_HR) GE BidPrice(T,G_HR)) = 0;


* ----- Temporary or auxiliary assignments -----


* ======================================================================
* VARIABLES
* ======================================================================
* ----- Variable declaration -----
FREE VARIABLES
NPV_all                     'Net present value of project across all stakeholders (EUR)'
OPEX(E)                     'Operating expenditure (EUR)'
HeatTransaction             'Transaction value of waste-heat (EUR)'
;

POSITIVE VARIABLES
NPV(E)                      'Net present value (EUR)'
CAPEX(E)                    'Capital expenditure (EUR)'
x_f(T,G,F)                  'Consumption of fuel (MWh)'
x_h(T,G)                    'Production of heat (MWh)'
x_e(T,G)                    'Production of electricity (MWh)'
x_c(T,G)                    'Production of cold (MWh)'
w(T,G,F)                    'Carbon emissions (kg)'
z(T,S)                      'State-of-charge of storage (MWh)'
y_hr(G)                     'Heating capacity of heat-recovery generators (MWh)'

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
* Warm-starting the model
x_f.l(T,G,F)    = x_f_REF(T,G,F);
x_h.l(T,G_DH)   = x_h_REF(T,G_DH);
x_e.l(T,G_CHP)  = x_e_REF(T,G_CHP);
x_s.l(T,S,SS)   = x_s_REF(T,S,SS);
z.l(T,S)        = z_REF(T,S);


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
eq_OPEX_DHN                 'Operating expenditure of DHN'
eq_OPEX_WHS                 'Operating expenditure of WHS'
eq_heat_transaction         'Transaction of waste-heat'  

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
eq_conversion_HR_1(T,G)     'Conversion constraint for heat-recovery generators (energy balance)'
eq_conversion_HR_2(T,G)     'Conversion constraint for heat-recovery generators (heat-cold ratio)'

eq_max_DH(T,G)              'Capacity constraint for DH generators (input-based)'
eq_max_HR(T,G)              'Capacity constraint for heat-recovery generators (output-based)'
eq_max_CO(T,G)              'Capacity constraint for cold-only generators (output-based)'
eq_max_elec_DHN(T,G,F)      'Maximum individual electricity consumption of DHN generators'
eq_max_elec_WHS(T)          'Maximum joint electricity consumption of WHS generators'

eq_carbon_emissions(T,G,F)  'Carbon emissions of generators'

eq_sto_balance(T,S)         'Storage balance'
eq_sto_end(T,S)             'Storage initial state of charge'
eq_sto_min(T,S)             'Storage minimum state of charge'
eq_sto_max(T,S)             'Storage maximum state of charge'
eq_sto_flo(T,S,SS)          'Storage throughput limit'
;

* ----- Equation definition -----
eq_NPV_all..                                NPV_all     =e= NPV('DHN') + NPV('WHS');

* Added small tolerance so the MIP solver doesn't complain
eq_NPV_DHN..                                NPV('DHN')  =e= - CAPEX('DHN') + (OPEX_REF('DHN') - OPEX('DHN') - HeatTransaction)/AF('DHN') + D6;
eq_NPV_WHS..                                NPV('WHS')  =e= - CAPEX('WHS') + (OPEX_REF('WHS') - OPEX('WHS') + HeatTransaction)/AF('WHS') + D6;

eq_CAPEX_DHN..                              CAPEX('DHN')=e= + sum(G_HR, L_p(G_HR) * K_p(G_HR) * y_hr(G_HR) * (1 - psi_k_p(G_HR)));  !! CAPEX support applied
eq_CAPEX_WHS..                              CAPEX('WHS')=e= + sum(G_HR,             K_g(G_HR) * y_hr(G_HR) * (1 - psi_k_g(G_HR)));  !! CAPEX support applied

eq_OPEX_DHN..                               OPEX('DHN') =e= + sum((T,G_DH,F)$GF(G_DH,F), C_f(T,G_DH,F)  * x_f(T,G_DH,F))
                                                            + sum((T,G_DH),              C_h(G_DH)      * x_h(T,G_DH))
                                                            + sum((T,G_CHP),             C_e(G_CHP)     * x_e(T,G_CHP))
                                                            + sum((T,S_DH),              C_s(S_DH)      * x_s(T,S_DH,'discharge'))
                                                            - sum((T,G_CHP),             pi_e(T)        * x_e(T,G_CHP))
                                                            + TaxPayment('DHN') + TariffPayment('DHN') + QuotaPayment('DHN')
                                                            ;

eq_OPEX_WHS..                               OPEX('WHS') =e= + sum((T,G_WH,F)$GF(G_WH,F), C_f(T,G_WH,F)  * x_f(T,G_WH,F))
                                                            + sum((T,G_WH),              C_c(G_WH)      * x_c(T,G_WH))
                                                            + sum((T,G_HR),              C_h(G_HR)      * x_h(T,G_HR))
                                                            + sum((G_HR),                C_y(G_HR)      * y_hr(G_HR))
                                                            + TaxPayment('WHS') + TariffPayment('WHS') + QuotaPayment('WHS')
                                                            - sum((T,G_HR),              psi_c_h(T,G_HR) * x_h(T,G_HR)) !! OPEX support applied here
                                                            ;

eq_taxes_DHN..                       TaxPayment('DHN')  =e= + sum((T,G_DH,F)$GF(G_DH,F), x_f(T,G_DH,F) * tax_f(G_DH))
                                                            + sum((T,G_DH),              x_h(T,G_DH)   * tax_h(G_DH))
                                                            + sum((T,G_DH),              x_e(T,G_DH)   * tax_e(G_DH))
                                                            + sum((T,G_DH,F)$GF(G_DH,F), w(T,G_DH,F)   * tax_w(G_DH))
                                                            ;

eq_taxes_WHS..                       TaxPayment('WHS')  =e= + sum((T,G_WH,F)$GF(G_WH,F), x_f(T,G_WH,F) * tax_f(G_WH))
                                                            + sum((T,G_HR),              x_h(T,G_HR)   * tax_h(G_HR))
                                                            + sum((T,G_WH),              x_c(T,G_WH)   * tax_c(G_WH))
                                                            + sum((T,G_WH,F)$GF(G_WH,F), w(T,G_WH,F)   * tax_w(G_WH))
                                                            ;

eq_tariffs_DHN..                   TariffPayment('DHN') =e= + sum((T,G_DH,F)$(GF(G_DH,F) AND F_EL(F)), tariff_v(T, G_DH) * x_f(T,G_DH,F))
                                                            + sum(G_DH$G_EL(G_DH),                     tariff_c(G_DH)    * x_f_max_DHN(G_DH))
                                                            ;

eq_tariffs_WHS..                   TariffPayment('WHS') =e= + sum((T,G_WH,F)$(GF(G_WH,F) AND F_EL(F)), tariff_v(T, G_WH) * x_f(T,G_WH,F))
                                                            +                                          tariff_c_WHS      * x_f_max_WHS
                                                            ;

eq_quotas_DHN..                     QuotaPayment('DHN') =e= + sum((T,G_DH,F)$GF(G_DH,F), w(T,G_DH,F) * pi_q(G_DH));
eq_quotas_WHS..                     QuotaPayment('WHS') =e= + sum((T,G_WH,F)$GF(G_WH,F), w(T,G_WH,F) * pi_q(G_WH));

eq_heat_transaction..                  HeatTransaction  =e= + sum((T,G_HR), pi_h(T,G_HR)  * x_h(T,G_HR));

eq_load_heat(T)..                           D_h(T) =e= sum(G_DH, x_h(T,G_DH)) + sum(G_HR, x_h(T,G_HR)*(1-rho_p(G_HR))) + sum(S_DH, x_s(T,S_DH,'discharge')) - sum(S_DH, x_s(T,S_DH,'charge'));
eq_load_cold(T)..                           D_c(T) =e= sum(G_WH, x_c(T,G_WH));

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
eq_max_elec_DHN(T,G,F)$(G_DH(G) AND G_EL(G) AND GF(G,F))..           x_f_max_DHN(G) =g= x_f(T,G,F);
eq_max_elec_WHS(T)..                                                 x_f_max_WHS    =g= sum((G_WH,F)$(G_EL(G_WH) AND GF(G_WH,F)), x_f(T,G_WH,F));

eq_carbon_emissions(T,G,F)$GF(G,F)..                            w_f(T,F)*x_f(T,G,F) =e= w(T,G,F);

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
$ifi "%solve_mode%" == 'static'       $include './scripts/gams/solve-static.inc';
$ifi "%solve_mode%" == 'iterative'    $include './scripts/gams/solve-iterative.inc';


* ======================================================================
* OUTPUT
* ======================================================================
AskPrice(T,G_HR)        = EPS + AskPrice(T,G_HR);
BidPrice(T,G_HR)        = EPS + BidPrice(T,G_HR);
AskMarginal(T,G_HR)     = EPS + AskMarginal(T,G_HR);
BidMarginal(T)          = EPS + BidMarginal(T);
AskFixed(G_HR)          = EPS + AskFixed(G_HR);
BidFixed(G_HR)          = EPS + BidFixed(G_HR);
pi_h(T,G_HR)            = EPS + pi_h(T,G_HR);

execute_unload './results/%scenario%/gdx/results-integrated.gdx',
$ifi "%solve_mode%" == 'iterative' log_n,
NPV_all, NPV, OPEX, CAPEX, HeatTransaction, N
x_f, x_h, x_e, x_c, w, z, y_hr, x_f_max_DHN, x_f_max_WHS, x_s
pi_h, AskPrice, BidPrice, AskMarginal, BidMarginal, AskFixed, BidFixed
TariffPayment, TaxPayment, QuotaPayment
;


* ======================================================================
* END OF FILE
