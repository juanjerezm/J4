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

* ----- Control flags -----
* Set default values if script not called from integrated model nor command line
$ifi not set project    $setlocal project       'default_prj'
$ifi not set scenario   $setlocal scenario      'default_scn'
$ifi not set policytype $setlocal policytype    'taxation'
$ifi not set country    $setlocal country       'DK'


* ======================================================================
*  SETS
* ======================================================================
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

SET G(*)                'Generators'
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

SET F(*)                'Fuels'
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

* --- Load data values --- *
TABLE ENTT_DATA(E,EnttAttrs)    'Entity data'
$onDelim
$include    './data/common/data-entity.csv'
$offDelim
;

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

TABLE CNCT_DATA(G,CnctAttrs)    'Connection data'
$onDelim
$include    './data/common/data-connection.csv'
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
C_p_inv(G)              'Investment cost of pipe connection (EUR/MW-m)'

pi_e(T)                 'Price of electricity (EUR/MWh)'
pi_f(T,F)               'Price of fuel (EUR/MWh)'
pi_q                    'Price of carbon quota (EUR/kg)'
tax_fuel_f(F)           'Fuel taxes - by fuel (EUR/MWh)'
tax_fuel_g(G)           'Fuel taxes - by generator (EUR/MWh)'
tariff_schedule_v(H,M)  'Volumetric electricity tariff - time-of-use (EUR/MWh)'
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
lifetime(E)             = ENTT_DATA(E,'lifetime');
r(E)                    = ENTT_DATA(E,'discount rate');

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

C_p_inv(G)$(G_HR(G))    = CNCT_DATA(G,'capital cost');
L_p(G)$(G_HR(G))        = CNCT_DATA(G,'length');
rho_g(G)$(G_HR(G))      = CNCT_DATA(G,'loss factor');


* ----- Parameter operations -----
AF(E)               = r(E) * (1 + r(E)) ** lifetime(E) / ((1 + r(E)) ** lifetime(E) - 1);
Y_c(G_CO)           = smax(T, D_c(T));                                          !! Cold-only capacity defined by peak demand
tariff_v(T)         = SUM((H,M)$(TM(T,M) AND TH(T,H)), tariff_schedule_v(H,M)); !! mapping hour-month schedule to timesteps

*  Calculate fuel cost from fuel price, taxes (per fuel and generator), electricity tariffs and ETS quotas
C_f(T,G,F)$G_DH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));

* Fuel costs for WHS depend on the policy type
$ifi %policytype% == 'socioeconomic'    C_f(T,G,F)$G_WH(G)  = pi_f(T,F);
$ifi %policytype% == 'taxation'         C_f(T,G,F)$G_WH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));
$ifi %policytype% == 'support'          C_f(T,G,F)$G_WH(G)  = pi_f(T,F) + tax_fuel_f(F) + tax_fuel_g(G) + tariff_v(T)$(F_EL(F)) + pi_q*qc_f(T,F)$(NOT F_EL(F));

* ======================================================================
*  Output
* ======================================================================
execute_unload 'results/%project%/%scenario%/params.gdx';
