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
* ----- Control flags -----
* Set default values if script not called from another script or command line
* $ifi not set project    $setlocal project       'default_prj'
* $ifi not set scenario   $setlocal scenario      'default_scn'
* $ifi not set policytype $setlocal policytype    'taxation'
* $ifi not set country    $setlocal country       'DK'

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

$gdxin './results/%project%/%scenario%/parameters.gdx'
SETS
        T, E, G, S, SS, F, G_HR(G), G_DH(G), G_WH(G), G_CHP(G), F_EL(F), GF(G,F);
$load   T, E, G, S, SS, F, G_HR   , G_DH   , G_WH   , G_CHP   , F_EL   , GF
$gdxin 


* ======================================================================
* PARAMETERS
* ======================================================================
* ----- Parameter declaration -----
PARAMETERS
NPV_all                         'Net present value of project - total (EUR)'
NPV(E)                          'Net present value for entity (stakeholder) (EUR)'
CAPEX(E)                        'Capital expenditure (EUR)'
OPEX(E,CASE)                    'Operating expenditure (EUR)'
OPEX_Savings(E)                 'Operating expenditure savings (EUR)'
WH_transaction                  'Transaction value of waste-heat (EUR)'
N(G_HR)                         'Full-load hours of heat-recovery generators (hours)'

WasteHeatPrice(T,G_HR)          'Price of recovered heat (EUR/MWh)'
AskPrice(T,G_HR)                'Minimum feasible price for WHS (EUR/MWh)'
BidPrice(T,G_HR)                'Maximum feasible price for DHU (EUR/MWh)'
MarginalAsk(T,G_HR)             'Marginal cost-component of ask-price, monthly average (EUR/MWh)'
MarginalBid(T)                  'Marginal cost-component of bid-price, monthly average (EUR/MWh)'
FixedAsk(G_HR)                  'Fixed cost-component of ask-price, from HR investments (EUR/MWh)'
FixedBid(G_HR)                  'Fixed cost-component of bid-price, from DH investments (EUR/MWh)'
* MarginalAsk_Hourly
* MarginalBid_Hourly

HeatRecoveryCapacity(G,CASE)    'Heating capacity of heat-recovery generators (MWh)'
FuelMaxCapacity(E,F,CASE)       'Maximum fuel consumption across timesteps (MW)'
HeatProduction(T,G,CASE)        'Production of heat (MWh)'
ColdProduction(T,G,CASE)        'Production of cold (MWh)'
ElectricityProduction(T,G,CASE) 'Production of electricity (MWh)'
FuelConsumption(T,G,F,CASE)     'Consumption of fuel (MWh)'
StorageFlow(T,S,SS,CASE)        'Storage charge/discharge flow (MWh)'
StorageLevel(T,S,CASE)          'State-of-charge of storage (MWh)'
CarbonEmissions(T,G,F,CASE)     'Carbon emissions (kg)'

Tariffs(E,CASE)                 'Grid tariffs (EUR/year)'   
ETSQuota(E,CASE)                'ETS quota (EUR/year)'
Taxes(E,CASE)                   'Energy and carbon taxes (EUR/year)'
Support(E,CASE)                 'Support schemes (EUR/year)'
;


* ----- Load economic variables from each case -----
* Load OPEX from reference case
$gdxin './results/%project%/%scenario%/results-%scenario%-reference.gdx'
PARAMETERS opex_r;
$load opex_r=OPX.l
$gdxin

* Load economic KPIs and prices from integrated case
$gdxin './results/%project%/%scenario%/results-%scenario%-integrated.gdx'
PARAMETERS opex_i;
$load opex_i=OPX.l
$load NPV_all=NPV_all.l, NPV=NPV.l, CAPEX=CAPEX.l, WH_transaction=WH_transaction.l
$load WasteHeatPrice=pi_h, AskPrice, BidPrice, MarginalAsk, MarginalBid, FixedAsk, FixedBid
$load N
$gdxin

* Merge OPEX from each case, calculate savings
OPEX(E,CASE)        = EPS + opex_r(E)$REF(CASE) + opex_i(E)$INT(CASE);
OPEX_Savings('DHN') = EPS + OPEX('DHN','reference') - OPEX('DHN','integrated') - WH_transaction;
OPEX_Savings('WHS') = EPS + OPEX('WHS','reference') - OPEX('WHS','integrated') + WH_transaction;


* ----- Load variables from each case and merge -----
* Load operational variables from reference case
$gdxin './results/%project%/%scenario%/results-%scenario%-reference.gdx'
PARAMETERS
xh_r, xc_r, xe_r, xf_r, xs_r, z_r, w_r, yfmax_r;
$load xh_r=x_h.l, xc_r=x_c.l, xe_r=x_e.l, xf_r=x_f.l, xs_r=x_s.l, z_r=z.l, w_r=w.l, yfmax_r=y_f_used.l
$gdxin

* Load operational variables from integrated case
$gdxin './results/%project%/%scenario%/results-%scenario%-integrated.gdx'
PARAMETERS
xh_i, xc_i, xe_i, xf_i, xs_i, z_i, w_i, yfmax_i, yhr_i;
$load xh_i=x_h.l, xc_i=x_c.l, xe_i=x_e.l, xf_i=x_f.l, xs_i=x_s.l, z_i=z.l, w_i=w.l, yfmax_i=y_f_used.l, yhr_i=y_hr.l
$gdxin

* Merge values from each case
HeatProduction(T,G,CASE)$(G_HR(G) OR G_DH(G))   = EPS + xh_r(T,G)$REF(CASE)    + xh_i(T,G)$INT(CASE);
ColdProduction(T,G,CASE)$G_WH(G)                = EPS + xc_r(T,G)$REF(CASE)    + xc_i(T,G)$INT(CASE);
ElectricityProduction(T,G,CASE)$G_CHP(G)        = EPS + xe_r(T,G)$REF(CASE)    + xe_i(T,G)$INT(CASE);
FuelConsumption(T,G,F,CASE)$GF(G,F)             = EPS + xf_r(T,G,F)$REF(CASE)  + xf_i(T,G,F)$INT(CASE);
StorageFlow(T,S,SS,CASE)                        = EPS + xs_r(T,S,SS)$REF(CASE) + xs_i(T,S,SS)$INT(CASE);
StorageLevel(T,S,CASE)                          = EPS + z_r(T,S)$REF(CASE)     + z_i(T,S)$INT(CASE);
CarbonEmissions(T,G,F,CASE)$GF(G,F)             = EPS + w_r(T,G,F)$REF(CASE)   + w_i(T,G,F)$INT(CASE);
FuelMaxCapacity(E,F,CASE)                       = EPS + yfmax_r(E,F)$REF(CASE) + yfmax_i(E,F)$INT(CASE);
HeatRecoveryCapacity(G,CASE)$G_HR(G)            = EPS                          + yhr_i(G)$INT(CASE);


* ----- Calculate tariffs, taxes, ETS quotas, and support schemes -----
$gdxin './results/%project%/%scenario%/parameters.gdx'
PARAMETERS 
        tariff_v, tariff_c, tax_fuel_f, tax_fuel_g, pi_q, qc_f, C_p_inv, C_g_inv, L_p, k_inv_p, k_inv_g, AF, N, r;
$load   tariff_v, tariff_c, tax_fuel_f, tax_fuel_g, pi_q, qc_f, C_p_inv, C_g_inv, L_p, k_inv_p, k_inv_g, AF, N=lifetime, r
$ifi     %policytype% == 'support' $ifi %country% == 'DK' PARAMETERS AF_og;
$ifi     %policytype% == 'support' $ifi %country% == 'DK' $load AF_og
$gdxin 

* - Parameters from the reference case -
$gdxin './results/%project%/%scenario%/transfer-%scenario%-reference.gdx'
PARAMETERS EmissionsDHN_Ref;
$load EmissionsDHN_Ref,
$gdxin

$ifi     %policytype% == 'socioeconomic'    Tariffs('WHS',CASE) = EPS;
$ifi not %policytype% == 'socioeconomic'    Tariffs('WHS',CASE) = EPS + sum((T,G_WH,F)$(GF(G_WH,F) AND F_EL(F)), tariff_v(T) * FuelConsumption(T,G_WH,F,CASE)) + sum(F, tariff_c(F) * FuelMaxCapacity('WHS',F,CASE));
                                            Tariffs('DHN',CASE) = EPS + sum((T,G_DH,F)$(GF(G_DH,F) AND F_EL(F)), tariff_v(T) * FuelConsumption(T,G_DH,F,CASE)) + sum(F, tariff_c(F) * FuelMaxCapacity('DHN',F,CASE));

$ifi     %policytype% == 'socioeconomic'    Taxes('WHS',CASE) = EPS;
$ifi not %policytype% == 'socioeconomic'    Taxes('WHS',CASE) = EPS + sum((T,G_WH,F)$GF(G_WH,F), FuelConsumption(T,G_WH,F,CASE) * (tax_fuel_f(F) + tax_fuel_g(G_WH)));
                                            Taxes('DHN',CASE) = EPS + sum((T,G_DH,F)$GF(G_DH,F), FuelConsumption(T,G_DH,F,CASE) * (tax_fuel_f(F) + tax_fuel_g(G_DH)));

$ifi     %policytype% == 'socioeconomic'    ETSQuota('WHS',CASE) = EPS;
$ifi not %policytype% == 'socioeconomic'    ETSQuota('WHS',CASE) = EPS + sum((T,G_WH,F)$GF(G_WH,F), FuelConsumption(T,G_WH,F,CASE) * pi_q*qc_f(T,F)$(NOT F_EL(F)));
                                            ETSQuota('DHN',CASE) = EPS + sum((T,G_DH,F)$GF(G_DH,F), FuelConsumption(T,G_DH,F,CASE) * pi_q*qc_f(T,F)$(NOT F_EL(F)));

$ifi not %policytype% == 'support'                          Support(E,CASE)         = EPS;
$ifi     %policytype% == 'support'                          Support(E,'reference')  = EPS;
$ifi     %policytype% == 'support' $ifi %country% == 'DE'   Support('DHN','integrated') = EPS + sum(G_HR, L_p(G_HR) * C_p_inv(G_HR) * HeatRecoveryCapacity(G_HR,'integrated') * k_inv_p      ) *  AF('DHN');
$ifi     %policytype% == 'support' $ifi %country% == 'DE'   Support('WHS','integrated') = EPS + sum(G_HR,             C_g_inv(G_HR) * HeatRecoveryCapacity(G_HR,'integrated') * k_inv_g(G_HR)) *  AF('WHS') + pi_q * sum((T, G_HR), HeatProduction(T,G_HR,'integrated')*EmissionsDHN_Ref(T));
$ifi     %policytype% == 'support' $ifi %country% == 'FR'   Support('DHN','integrated') = EPS + sum(G_HR, L_p(G_HR) * C_p_inv(G_HR) * HeatRecoveryCapacity(G_HR,'integrated') * k_inv_p      ) *  AF('DHN');
$ifi     %policytype% == 'support' $ifi %country% == 'FR'   Support('WHS','integrated') = EPS + sum(G_HR,             C_g_inv(G_HR) * HeatRecoveryCapacity(G_HR,'integrated') * k_inv_g(G_HR)) *  AF('WHS');
$ifi     %policytype% == 'support' $ifi %country% == 'DK'   Support('DHN','integrated') = EPS + sum(G_HR, L_p(G_HR) * C_p_inv(G_HR) * HeatRecoveryCapacity(G_HR,'integrated') * k_inv_p      ) * (AF_og('DHN') - AF('DHN'));
$ifi     %policytype% == 'support' $ifi %country% == 'DK'   Support('WHS','integrated') = EPS + 0;

* ----- Calculate internal rate of return and payback-time -----
SET
ITER /I01*I99/
;
$include scripts/gams/out_IRR.gms
$include scripts/gams/out_PBT.gms

* ----- Ensuring all elements of variables/parameters directly imported appear in final file, even if all values are zero -----
NPV_all                 = EPS + NPV_all;
NPV(E)                  = EPS + NPV(E);
CAPEX(E)                = EPS + CAPEX(E);
WH_transaction          = EPS + WH_transaction;
N(G_HR)                 = EPS + N(G_HR);
IRR(E)                  = EPS + IRR(E);  
PBT(E)                  = EPS + PBT(E);
WasteHeatPrice(T,G_HR)  = EPS + WasteHeatPrice(T,G_HR);
AskPrice(T,G_HR)        = EPS + AskPrice(T,G_HR);
BidPrice(T,G_HR)        = EPS + BidPrice(T,G_HR);
MarginalAsk(T,G_HR)     = EPS + MarginalAsk(T,G_HR);
MarginalBid(T)          = EPS + MarginalBid(T);
FixedAsk(G_HR)          = EPS + FixedAsk(G_HR);
FixedBid(G_HR)          = EPS + FixedBid(G_HR);


* ======================================================================
* OUTPUT
* ======================================================================
execute_unload './results/%project%/%scenario%/results-%scenario%-postprocessing_all.gdx';

execute_unload  './results/%project%/%scenario%/results-%scenario%-postprocessing.gdx',
NPV_all, NPV, CAPEX, OPEX, OPEX_Savings, WH_transaction, IRR, PBT, N
WasteHeatPrice, AskPrice, BidPrice, MarginalAsk, MarginalBid, FixedAsk, FixedBid
HeatProduction, ColdProduction, ElectricityProduction, FuelConsumption, StorageFlow, StorageLevel, CarbonEmissions, FuelMaxCapacity, HeatRecoveryCapacity
Tariffs, Taxes, ETSQuota, Support
;

* ======================================================================
* END OF FILE
