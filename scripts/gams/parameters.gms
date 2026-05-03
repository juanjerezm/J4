* ======================================================================
*  DESCRIPTION
* ======================================================================
* ----- INFO -----
* Written by Juan Jerez, jujmo@dtu.dk, 2024.
*
* This script builds the model input dataset and exports it to GDX.
* It reads default data from ./data/common/, applies optional scenario-specific
* overrides from ./data/overrides/%override%/, derives model subsets and parameters, and
* computes policy-dependent cost terms used by the optimization models.
*
* Main outputs:
* - ./results/%scenario%/gdx/parameters.gdx
* - all sets, subsets, and parameters consumed by model_reference.gms,
*   model_integrated.gms, and postprocessing.gms.

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
* ----- Set definition -----

SET T                   'Timesteps' 
/T0001*T8760/;

SET M                   'Months'
/M01*M12/;

SET SS                  'Storage states (SOS1 set)'
/'charge', 'discharge'/;

SET E                   'Entity'
/'DHN', 'WHS'/
;

SET G(*)                'Generators'
/
$onDelim
$if     EXIST './data/overrides/%override%/name-generator.csv' $include './data/overrides/%override%/name-generator.csv'
$if not EXIST './data/overrides/%override%/name-generator.csv' $include './data/common/name-generator.csv'
$offDelim
/;

SET S(*)                'Storages'
/
$onDelim
$if     EXIST './data/overrides/%override%/name-storage.csv' $include './data/overrides/%override%/name-storage.csv'
$if not EXIST './data/overrides/%override%/name-storage.csv' $include './data/common/name-storage.csv'
$offDelim
/;

SET F(*)                'Fuels'
/
$onDelim
$if     EXIST './data/overrides/%override%/name-fuel.csv' $include './data/overrides/%override%/name-fuel.csv'
$if not EXIST './data/overrides/%override%/name-fuel.csv' $include './data/common/name-fuel.csv'
$offDelim
/;

SET TM(T,M)              'Timestep-month mapping'
/
$onDelim
$include    './data/common/ts-TM-mapping.csv'
$offDelim
/;

SET GF(G,F)             'Generator-fuel mapping'
/
$onDelim
$if     EXIST './data/overrides/%override%/map-generator-fuel.csv' $include './data/overrides/%override%/map-generator-fuel.csv'
$if NOT EXIST './data/overrides/%override%/map-generator-fuel.csv' $include './data/common/map-generator-fuel.csv'
$offDelim
/;


* ======================================================================
*  Auxiliary data loading (required after definition of sets, but before subsets)
* ======================================================================
* --- Define acronyms ---
ACRONYMS EX 'Extraction', BP 'Backpressure', HO 'Heat-only', HR 'Heat recovery', CO 'Cold-only';
ACRONYMS DH 'District heating network', WH 'Waste heat source';
ACRONYMS timeVar 'time-variable data';
ACRONYMS TRUE, FALSE;

* --- Load data attributes ---
SET EnttAttrs(*)        'Auxiliary set to load entity data'
/
$onDelim
$include    './data/common/attribute-entity.csv'
$offDelim
/;

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

SET CnctAttrs(*)        'Auxiliary set to load connection data'
/
$onDelim
$include    './data/common/attribute-connection.csv'
$offDelim
/;

SET FuelAttrs(*)        'Auxiliary set to load fuel data'
/
$onDelim
$include    './data/common/attribute-fuel.csv'
$offDelim
/;

SET TaxAttrs(*)         'Auxiliary set to load tax data'
/
$onDelim
$include    './data/common/attribute-taxes.csv'
$offDelim
/;

* --- Load data values --- *
TABLE ENTT_DATA(E,EnttAttrs)    'Entity data'
$onDelim
$if     EXIST './data/overrides/%override%/data-entity.csv' $include './data/overrides/%override%/data-entity.csv'
$if NOT EXIST './data/overrides/%override%/data-entity.csv' $include './data/common/data-entity.csv'
$offDelim
;

TABLE GNRT_DATA(G,GnrtAttrs)    'Generator data'
$onDelim
$if     EXIST './data/overrides/%override%/data-generator.csv' $include './data/overrides/%override%/data-generator.csv'
$if NOT EXIST './data/overrides/%override%/data-generator.csv' $include './data/common/data-generator.csv'
$offDelim
;

TABLE STRG_DATA(S,StrgAttrs)    'Storage data'
$onDelim
$if     EXIST './data/overrides/%override%/data-storage.csv' $include './data/overrides/%override%/data-storage.csv'
$if NOT EXIST './data/overrides/%override%/data-storage.csv' $include './data/common/data-storage.csv'
$offDelim
;

TABLE CNCT_DATA(G,CnctAttrs)    'Connection data'
$onDelim
$if     EXIST './data/overrides/%override%/data-connection.csv' $include './data/overrides/%override%/data-connection.csv'
$if NOT EXIST './data/overrides/%override%/data-connection.csv' $include './data/common/data-connection.csv'
$offDelim
;

TABLE FUEL_DATA(F,FuelAttrs)    'Fuel data'
$onDelim
$if     EXIST './data/overrides/%override%/data-fuel-%country%.csv' $include './data/overrides/%override%/data-fuel-%country%.csv'
$if NOT EXIST './data/overrides/%override%/data-fuel-%country%.csv' $include './data/common/data-fuel-%country%.csv'
$offDelim
;

TABLE TAX_DATA(*,TaxAttrs)     'Tax data'
$onDelim
$if     EXIST './data/overrides/%override%/data-taxes-%country%.csv' $include './data/overrides/%override%/data-taxes-%country%.csv'
$if NOT EXIST './data/overrides/%override%/data-taxes-%country%.csv' $include './data/common/data-taxes-%country%.csv'
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
G_EL(G)                 'Electricity-consuming generators'
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

G_EL(G)     = YES$GF(G,'electricity');
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

D_h(T)                  'Demand of heat (MW)'
D_c(T)                  'Demand of cold (MW)'

w_e(T)                  'Carbon content of electricity (kg/MWh)'
w_f(T,F)                'Carbon content of fuel (kg/MWh)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
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

psi_k_g(G)              'CAPEX Subsidiy fraction - generation (-)'
psi_k_p(G)              'CAPEX Subsidiy fraction - piping (-)'
psi_c_h(T,G)            'OPEX Subsidiy (EUR/Mwh)'
;

* ----- Parameter definition -----
* - Scalar parameters -


* - One-dimensional parameters -
PARAMETERS
D_h(T)
/
$onDelim
$if     EXIST './data/overrides/%override%/ts-demand-heat.csv' $include './data/overrides/%override%/ts-demand-heat.csv'
$if NOT EXIST './data/overrides/%override%/ts-demand-heat.csv' $include './data/common/ts-demand-heat.csv' 
$offDelim
/

D_c(T)
/
$onDelim
$if     EXIST './data/overrides/%override%/ts-demand-cold.csv' $include './data/overrides/%override%/ts-demand-cold.csv'
$if NOT EXIST './data/overrides/%override%/ts-demand-cold.csv' $include './data/common/ts-demand-cold.csv'
$offDelim
/

pi_e(T)
/
$onDelim
$if     EXIST './data/overrides/%override%/ts-electricity-price.csv' $include './data/overrides/%override%/ts-electricity-price.csv'
$if NOT EXIST './data/overrides/%override%/ts-electricity-price.csv' $include './data/common/ts-electricity-price.csv'
$offDelim
/

w_e(T)
/
$onDelim
$if     EXIST './data/overrides/%override%/ts-electricity-carbon.csv' $include './data/overrides/%override%/ts-electricity-carbon.csv'
$if NOT EXIST './data/overrides/%override%/ts-electricity-carbon.csv' $include './data/common/ts-electricity-carbon.csv'
$offDelim
/

tariff_c(G)
/
$onDelim
$if     EXIST './data/overrides/%override%/data-capacity-tariff-%country%.csv' $include './data/overrides/%override%/data-capacity-tariff-%country%.csv'
$if NOT EXIST './data/overrides/%override%/data-capacity-tariff-%country%.csv' $include './data/common/data-capacity-tariff-%country%.csv'
$offDelim
/


* - Multi-dimensional parameters -
TABLE F_a(T,G)
$onDelim
$if     EXIST './data/overrides/%override%/ts-generator-availability.csv' $include './data/overrides/%override%/ts-generator-availability.csv'
$if NOT EXIST './data/overrides/%override%/ts-generator-availability.csv' $include './data/common/ts-generator-availability.csv'
$offDelim
;

TABLE eta_g(T,G)
$onDelim
$if     EXIST './data/overrides/%override%/ts-generator-efficiency.csv' $include './data/overrides/%override%/ts-generator-efficiency.csv'
$if NOT EXIST './data/overrides/%override%/ts-generator-efficiency.csv' $include './data/common/ts-generator-efficiency.csv'
$offDelim
;

TABLE tariff_v(T,G)
$onDelim
$if     EXIST './data/overrides/%override%/data-volumetric-tariff-%country%.csv' $include './data/overrides/%override%/data-volumetric-tariff-%country%.csv'
$if NOT EXIST './data/overrides/%override%/data-volumetric-tariff-%country%.csv' $include './data/common/data-volumetric-tariff-%country%.csv'
$offDelim
;

* - Parameter assignments -
lifetime(E)             = ENTT_DATA(E,'lifetime');
r(E)                    = ENTT_DATA(E,'discount rate');

w_f(T,F)                = FUEL_DATA(F,'carbon content')$(NOT F_EL(F)) + w_e(T)$(F_EL(F));
pi_f(T,F)               = FUEL_DATA(F,'fuel price')$(NOT F_EL(F)) + pi_e(T)$(F_EL(F));
pi_q(G)                 = TAX_DATA(G,'ets quota');

tax_f(G)                = TAX_DATA(G,'fuel input');
tax_h(G)                = TAX_DATA(G,'heat output');
tax_e(G)                = TAX_DATA(G,'electricity output');
tax_c(G)                = TAX_DATA(G,'cold output');
tax_w(G)                = TAX_DATA(G,'emissions');

C_f(T,G,F)$GF(G,F)      = FUEL_DATA(F,'fuel price')$(NOT F_EL(F)) + pi_e(T)$(F_EL(F)); !! Same as fuel price now
C_h(G)                  = GNRT_DATA(G,'variable cost - heat');
C_e(G)                  = GNRT_DATA(G,'variable cost - electricity');
C_c(G)                  = GNRT_DATA(G,'variable cost - cold');
C_y(G)$(G_HR(G))        = GNRT_DATA(G,'fixed cost');
K_g(G)$(G_HR(G))        = GNRT_DATA(G,'capital cost');

Y_f(G_DH)               = GNRT_DATA(G_DH,'capacity');  
beta_b(G)$G_CHP(G)      = GNRT_DATA(G,'Cb');
beta_v(G)$G_EX(G)       = GNRT_DATA(G,'Cv');

K_p(G)$(G_HR(G))        = CNCT_DATA(G,'capital cost');
L_p(G)$(G_HR(G))        = CNCT_DATA(G,'length');
rho_p(G)$(G_HR(G))      = CNCT_DATA(G,'loss factor');

C_s(S)                  = STRG_DATA(S,'OMV');
Y_s(S)                  = STRG_DATA(S,'SOC capacity');
eta_s(S)                = STRG_DATA(S,'throughput efficiency');
rho_s(S)                = STRG_DATA(S,'self-discharge factor');
F_s_flo(S)              = STRG_DATA(S,'throughput ratio');
F_s_end(S)              = STRG_DATA(S,'SOC ratio end');
F_s_min(S)              = STRG_DATA(S,'SOC ratio min');
F_s_max(S)              = STRG_DATA(S,'SOC ratio max');


* ----- Parameter operations -----
AF(E)                   = r(E) * (1 + r(E)) ** lifetime(E) / ((1 + r(E)) ** lifetime(E) - 1);
Y_c(G_CO)               = smax(T, D_c(T))+D6; !! Cooling capacity defined by peak demand + epsilon (to allow proper calculation of reference marginal cost)

* Overriding taxes and tariffs for WHS generators under the socioeconomic policy.
$ifi "%policytype%" == 'socioeconomic'    tax_f(G_WH) = 0;
$ifi "%policytype%" == 'socioeconomic'    tax_h(G_WH) = 0;
$ifi "%policytype%" == 'socioeconomic'    tax_e(G_WH) = 0;
$ifi "%policytype%" == 'socioeconomic'    tax_c(G_WH) = 0;
$ifi "%policytype%" == 'socioeconomic'    tax_w(G_WH) = 0;
$ifi "%policytype%" == 'socioeconomic'    pi_q(G_WH)  = 0;
$ifi "%policytype%" == 'socioeconomic'    tariff_v(T,G)$(G_WH(G) AND G_EL(G)) = 0;
$ifi "%policytype%" == 'socioeconomic'    tariff_c(G)$(G_WH(G) AND G_EL(G)) = 0;

* - Policy parameters -
$ifi NOT "%policytype%" == 'support'  psi_k_g(G_HR)      = EPS + 0;                        !! default value w/o support policy
$ifi NOT "%policytype%" == 'support'  psi_k_p(G_HR)      = EPS + 0;                        !! default value w/o support policy
$ifi NOT "%policytype%" == 'support'  psi_c_h(T,G_HR)    = EPS + 0;                        !! default value w/o support policy
$ifi     "%policytype%" == 'support'  $include './scripts/gams/policy-definition.inc';

* WHS capacity tariff are not be indexed by G, since they share a single grid connection point.
* Therefore we take (for simplicity) the maximum value among all WHS units, since their tariff data should be identical.
* This applies regardless of policy type.
tariff_c_WHS            = smax(G$(G_WH(G) AND G_EL(G)), tariff_c(G));


* ======================================================================
*  Output
* ======================================================================
execute_unload './results/%scenario%/gdx/parameters.gdx';
