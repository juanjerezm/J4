* ======================================================================
* DESCRIPTION
* ======================================================================
* ----- INFO -----
* Written by Juan Jerez, jujmo@dtu.dk, 2024.
*
* This script consolidates and enriches outputs from the reference and
* integrated optimization runs. It merges economic and operational variables
* from both cases, computes comparative KPIs (for example OPEX savings), and
* derives policy-relevant accounting terms (tariffs, taxes, ETS quotas,
* support), plus IRR and payback time.
*
* Main output:
* - ./results/%scenario%/gdx/results-postprocessing.gdx
*   (single source for downstream CSV export and analysis scripts).



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
SETS
CASE                    'Case identifier'                       /integrated, reference/
INT(CASE)               'Case identifier for integrated case'   /integrated/
REF(CASE)               'Case identifier for reference case'    /reference/
;

$gdxin './results/%scenario%/gdx/parameters.gdx'
SETS
        T, E, G, S, SS, F, G_HR(G), G_DH(G), G_WH(G), G_CHP(G), F_EL(F), G_EL(G), GF(G,F);
$load   T, E, G, S, SS, F, G_HR   , G_DH   , G_WH   , G_CHP   , F_EL   , G_EL   , GF
$gdxin 


* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
NPV_all                             'Net present value of project across all stakeholders (EUR)'
NPV(E)                              'Net present value (EUR)'
CAPEX(E)                            'Capital expenditure (EUR)'
OPEX(E,CASE)                        'Operating expenditure (EUR)'
OPEX_savings(E)                     'Operating expenditure savings (EUR)'
HeatTransaction                     'Transaction value of waste-heat (EUR)'

WasteHeatPrice(T,G_HR)              'Price of recovered heat (EUR/MWh)'
AskMarginal(T,G)                    'Marginal component of ask-price, from HR unit marginal operation cost (EUR/MWh)'
BidMarginal(T)                      'Marginal component of bid price, from DH marginal cost in reference case (EUR/MWh)'
AskFixed(G)                         'Fixed component of ask-price, from HR investments (EUR/MWh)'
BidFixed(G)                         'Fixed component of bid-price, from DH investments (EUR/MWh)'
AskPrice(T,G_HR)                    'Minimum feasible price for WHS (EUR/MWh)'
BidPrice(T,G_HR)                    'Maximum feasible price for DHN (EUR/MWh)'
FLH(G_HR)                           'Full-load hours equivalent (hours)'

FuelConsumption(T,G,F,CASE)         'Consumption of fuel (MWh)'
HeatProduction(T,G,F,CASE)          'Production of heat (MWh)'
ColdProduction(T,G,F,CASE)          'Production of cold (MWh)'
ElectricityProduction(T,G,F,CASE)   'Production of electricity (MWh)'
StorageFlow(T,S,SS,CASE)            'Storage charge/discharge flow (MWh)'
StorageLevel(T,S,CASE)              'State-of-charge of storage (MWh)'
CarbonEmissions(T,G,F,CASE)         'Carbon emissions (kg)'
HeatRecoveryCapacity(G,CASE)        'Heating capacity of heat-recovery generators (MWh)'

Taxes(E,CASE)                       'Energy and carbon taxes (EUR/year)'
Tariffs(E,CASE)                     'Grid tariffs (EUR/year)'   
ETSQuota(E,CASE)                    'ETS quota (EUR/year)'
Support(E,CASE)                     'Support schemes (EUR/year)'
;


* ----- Load parameters and variables from each case and merge -----
* - Parameters for calculating support schemes and comparative KPIs -
$gdxin './results/%scenario%/gdx/parameters.gdx'
PARAMETERS 
        L_p, K_p, K_g, psi_k_p, psi_k_g, psi_c_h, AF, N, r;
$load   L_p, K_p, K_g, psi_k_p, psi_k_g, psi_c_h, AF, N=lifetime, r
$gdxin

* - Variables that do not need to be merged -
$gdxin './results/%scenario%/gdx/results-integrated.gdx'
$load NPV_all=NPV_all.l, NPV=NPV.l, CAPEX=CAPEX.l, HeatTransaction=HeatTransaction.l
$load WasteHeatPrice=pi_h, AskPrice, BidPrice, AskMarginal, BidMarginal, AskFixed, BidFixed
$load FLH=N
$gdxin


PARAMETERS x_f_tmp(T,G,F), x_h_tmp(T,G), x_c_tmp(T,G), x_e_tmp(T,G), x_s_tmp(T,S,SS), z_tmp(T,S), w_tmp(T,G,F), y_hr_tmp(G);
PARAMETERS OPEX_tmp(E), Tariffs_tmp(E), Taxes_tmp(E), ETSQuota_tmp(E);

* - Variables to be merged from reference case -
$onMultiR                                                       !! Allows repeated definitions of same parameter, which are overwritten
execute_load './results/%scenario%/gdx/results-reference.gdx',
x_f_tmp=x_f.l, x_h_tmp=x_h.l, x_c_tmp=x_c.l, x_e_tmp=x_e.l, x_s_tmp=x_s.l, z_tmp=z.l, w_tmp=w.l,
OPEX_tmp=OPEX.l, Tariffs_tmp=TariffPayment.l, Taxes_tmp=TaxPayment.l, ETSQuota_tmp=QuotaPayment.l;
* $gdxin './results/%scenario%/gdx/results-reference.gdx'
* $load x_f_tmp=x_f.l, x_h_tmp=x_h.l, x_c_tmp=x_c.l, x_e_tmp=x_e.l, x_s_tmp=x_s.l, z_tmp=z.l, w_tmp=w.l
* $load OPEX_tmp=OPEX.l, Tariffs_tmp=TariffPayment.l, Taxes_tmp=TaxPayment.l, ETSQuota_tmp=QuotaPayment.l
* $gdxin

FuelConsumption(T,G,F,REF)$GF(G,F)                              = EPS + x_f_tmp(T,G,F);
HeatProduction(T,G,F,REF)$((G_HR(G) OR G_DH(G)) AND GF(G,F))    = EPS + x_h_tmp(T,G);
ColdProduction(T,G,F,REF)$(G_WH(G) AND GF(G,F))                 = EPS + x_c_tmp(T,G);
ElectricityProduction(T,G,F,REF)$(G_CHP(G) AND GF(G,F))         = EPS + x_e_tmp(T,G);
StorageFlow(T,S,SS,REF)                                         = EPS + x_s_tmp(T,S,SS);
StorageLevel(T,S,REF)                                           = EPS + z_tmp(T,S);
CarbonEmissions(T,G,F,REF)$GF(G,F)                              = EPS + w_tmp(T,G,F);
HeatRecoveryCapacity(G,REF)$G_HR(G)                             = EPS;

OPEX(E,REF)                                                     = EPS + OPEX_tmp(E);
Taxes(E,REF)                                                    = EPS + Taxes_tmp(E);
Tariffs(E,REF)                                                  = EPS + Tariffs_tmp(E);
ETSQuota(E,REF)                                                 = EPS + ETSQuota_tmp(E);

* - Variables to be merged from integrated case -
* $gdxin './results/%scenario%/gdx/results-integrated.gdx'
* $load x_f_tmp=x_f.l, x_h_tmp=x_h.l, x_c_tmp=x_c.l, x_e_tmp=x_e.l, x_s_tmp=x_s.l, z_tmp=z.l, w_tmp=w.l, y_hr_tmp=y_hr.l
* $load OPEX_tmp=OPEX.l, Tariffs_tmp=TariffPayment.l, Taxes_tmp=TaxPayment.l, ETSQuota_tmp=QuotaPayment.l
* $gdxin
execute_load './results/%scenario%/gdx/results-integrated.gdx',
x_f_tmp=x_f.l, x_h_tmp=x_h.l, x_c_tmp=x_c.l, x_e_tmp=x_e.l, x_s_tmp=x_s.l, z_tmp=z.l, w_tmp=w.l, y_hr_tmp=y_hr.l,
OPEX_tmp=OPEX.l, Tariffs_tmp=TariffPayment.l, Taxes_tmp=TaxPayment.l, ETSQuota_tmp=QuotaPayment.l;


FuelConsumption(T,G,F,INT)$GF(G,F)                              = EPS + x_f_tmp(T,G,F);
HeatProduction(T,G,F,INT)$((G_HR(G) OR G_DH(G)) AND GF(G,F))    = EPS + x_h_tmp(T,G);
ColdProduction(T,G,F,INT)$(G_WH(G) AND GF(G,F))                 = EPS + x_c_tmp(T,G);
ElectricityProduction(T,G,F,INT)$(G_CHP(G) AND GF(G,F))         = EPS + x_e_tmp(T,G);
StorageFlow(T,S,SS,INT)                                         = EPS + x_s_tmp(T,S,SS);
StorageLevel(T,S,INT)                                           = EPS + z_tmp(T,S);
CarbonEmissions(T,G,F,INT)$GF(G,F)                              = EPS + w_tmp(T,G,F);
HeatRecoveryCapacity(G,INT)$G_HR(G)                             = EPS + y_hr_tmp(G);

OPEX(E,INT)                                                     = EPS + OPEX_tmp(E);
Taxes(E,INT)                                                    = EPS + Taxes_tmp(E);
Tariffs(E,INT)                                                  = EPS + Tariffs_tmp(E);
ETSQuota(E,INT)                                                 = EPS + ETSQuota_tmp(E);

$offMulti                                                       !! Deactivate repeated parameter definition

* - Calculate annual value of support schemes
Support(E,REF)      = EPS;
Support('DHN',INT)  = EPS + sum(G_HR, L_p(G_HR) * K_p(G_HR) * HeatRecoveryCapacity(G_HR,INT) * psi_k_p(G_HR)) * AF('WHS') + sum((T,G_HR,F), psi_c_h(T,G_HR) * HeatProduction(T,G_HR,F,INT));
Support('WHS',INT)  = EPS + sum(G_HR,             K_g(G_HR) * HeatRecoveryCapacity(G_HR,INT) * psi_k_g(G_HR)) * AF('DHN');

* - Calculate annual OPEX savings
OPEX_savings('DHN') = EPS + OPEX('DHN','reference') - OPEX('DHN','integrated') - HeatTransaction;
OPEX_savings('WHS') = EPS + OPEX('WHS','reference') - OPEX('WHS','integrated') + HeatTransaction;

* ----- Calculate internal rate of return and payback-time -----
SET
ITER /I01*I99/
;
$include './scripts/gams/IRR.inc'
$include './scripts/gams/PBT.inc'

* ----- Ensuring all elements of variables/parameters directly imported appear in final file, even if all values are zero -----
NPV_all                 = EPS + NPV_all;
NPV(E)                  = EPS + NPV(E);
CAPEX(E)                = EPS + CAPEX(E);
HeatTransaction         = EPS + HeatTransaction;
WasteHeatPrice(T,G_HR)  = EPS + WasteHeatPrice(T,G_HR);
AskPrice(T,G_HR)        = EPS + AskPrice(T,G_HR);
BidPrice(T,G_HR)        = EPS + BidPrice(T,G_HR);
AskMarginal(T,G_HR)     = EPS + AskMarginal(T,G_HR);
BidMarginal(T)          = EPS + BidMarginal(T);
AskFixed(G_HR)          = EPS + AskFixed(G_HR);
BidFixed(G_HR)          = EPS + BidFixed(G_HR);
FLH(G_HR)               = EPS + FLH(G_HR);


* ======================================================================
* OUTPUT
* ======================================================================
execute_unload  './results/%scenario%/gdx/results-postprocessing.gdx',
NPV_all, NPV, CAPEX, OPEX, OPEX_savings, Tariffs, Taxes, ETSQuota, Support, HeatTransaction,
IRR, PBT, FLH,
WasteHeatPrice, AskPrice, BidPrice, AskMarginal, BidMarginal, AskFixed, BidFixed,
FuelConsumption, HeatProduction, ColdProduction, ElectricityProduction, StorageFlow, StorageLevel, CarbonEmissions, HeatRecoveryCapacity
;

* ======================================================================
* END OF FILE
