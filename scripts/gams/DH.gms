* NOTES:

* ======================================================================
*  Options
* ======================================================================
$onEmpty

* ======================================================================
* Control flags
* ======================================================================

* print control flags

* ======================================================================
*  Global scalars
* ======================================================================



* ======================================================================
*  SETS
* ======================================================================
* --- Set declaration ---
SETS
T                       'Timesteps'
G                       'Generators' 
S                       'Storages'
F                       'Fuels'
;

* --- Set definition ---
SETS T               
/T0001*T8760/
;

SET G
/
    'AMV1',
    'AMV4',
    'AVV1',
    'AVV2',
    'HCV7',
    'HCV8',
    'SMV1_SMV7',
    'KKV8',
    'ARC',
    'ARGO5',
    'ARGO6',
    'VF5',
    'VF6',
    'HOB_electric',
    'HOB_biogas',
    'HOB_fueloil',
    'HOB_gasoil',
    'HOB_natgas',
    'HOB_pellets',
    'HP_air'
    'HP_hr'
/;

Set G_BP(G)
/
    'AMV1',
    'AMV4',
    'HCV7',
    'HCV8',
    'SMV1_SMV7',
    'KKV8',
    'ARC',
    'ARGO5',
    'ARGO6',
    'VF5',
    'VF6'
/;

Set G_EX(G)
/
    'AVV1',
    'AVV2'
/;

Set G_HR(G)
/
    'HP_hr'
/;

* ======================================================================
* SUBSETS
* ======================================================================
* --- Subset declaration ---
SETS
G_CHP(G)                'CHP generators'
G_BP(G)                 'Backpressure generators'
G_EX(G)                 'Extraction generators'  
G_HO(G)                 'Heat-only generators'
G_HR(G)                 'Heat recovery generators'
;
* --- Subset definition ---

* --- Subset operations ---
G_CHP(G)    = G_BP(G) + G_EX(G);
G_HO(G)     = G(G) - G_CHP(G) - G_HR(G);

* ======================================================================
* PARAMETERS
* ======================================================================
* --- Parameter declaration ---
PARAMETERS
Y_f(G)                  'Fuel capacity (MWh)'

eta(T,G)                  'Efficiency (-)'
beta_b(G)               'CHP cb coefficient (-)'
beta_v(G)               'CHP cv coefficient (-)'

D(T)                    'Demand (MW)'

pi_e(T)                 'Electricity price (EUR/MWh)'
pi_h(T)                 'Heat price (EUR/MWh)'
;

* --- Parameter definition ---
* Parameter Y_f(G);
* Needs review, and check the HP_hr unit (do it on fuel or on cold, or on heat?)
Y_f('AMV1')                     = 362;
Y_f('AMV4')                     = 500;
Y_f('AVV1')                     = 624;
Y_f('AVV2')                     = 1168;
Y_f('HCV7')                     = 200;
Y_f('HCV8')                     = 121;
Y_f('SMV1_SMV7')                = 243;
Y_f('KKV8')                     = 56;
Y_f('ARC')                      = 224;
Y_f('ARGO5')                    = 65;
Y_f('ARGO6')                    = 73;
Y_f('VF5')                      = 85;
Y_f('VF6')                      = 112;
Y_f('HOB_electric')             = 120;
Y_f('HOB_biogas')               = 13;
Y_f('HOB_fueloil')              = 39;
Y_f('HOB_gasoil')               = 851;
Y_f('HOB_natgas')               = 1151;
Y_f('HOB_pellets')              = 33;
Y_f('HP_air')                   = 7;
Y_f('HP_hr')                    = 1;

* Parameter beta_b(G);
* This data needs to be reviewed
beta_b('AMV1')                    = 0.270;
beta_b('AMV4')                    = 0.380;
beta_b('AVV1')                    = 0.590;
beta_b('AVV2')                    = 0.610;
beta_b('HCV7')                    = 0.290;
beta_b('HCV8')                    = 0.220;
beta_b('SMV1_SMV7')               = 0.250;
beta_b('KKV8')                    = 0.170;
beta_b('ARC')                     = 0.270;
beta_b('ARGO5')                   = 0.210;
beta_b('ARGO6')                   = 0.220;
beta_b('VF5')                     = 0.120;
beta_b('VF6')                     = 0.180;

* Parameter beta_v(G);
* This data needs to be reviewed, numbers are placeholders 
beta_v('AVV1')                    = 0.110;
beta_v('AVV2')                    = 0.110;


PARAMETERS
D(T)
/
$onDelim
$include    '../../data/timeseries/ts-heat-demand.csv'
$offDelim
/

pi_e(T)
/
$onDelim
$include    '../../data/timeseries/ts-elec-price.csv'
$offDelim
/
;

TABLE C_f(T,G)
*check these values
$onDelim
$include    '../../data/timeseries/ts-fuel-cost-NeedsFix.csv'
$offDelim
;

TABLE eta(T,G)
* check the value of hr (and all as well)
$onDelim
$include    '../../data/timeseries/ts-eta-NeedsFix.csv'
$offDelim
;

* --- Parameter operations ---

* ======================================================================
* VARIABLES
* ======================================================================
* --- Variable declaration ---
FREE VARIABLES
obj                     'Cost of DH system (EUR)'
;

POSITIVE VARIABLES
x_h(T,G)                'Heat production (MWh)'
x_f(T,G)                'Fuel consumption (MWh)'
x_e(T,G)                'Electricity production (MWh)'
;

* --- Variable attributes ---

* ======================================================================
* EQUATIONS
* ======================================================================
* --- Equation declaration ---
EQUATIONS
eq_obj                  'Objective function - Cost of DH system'
eq_heat_balance(T)      'Heat balance'
eq_fuel_maximum(T,G)    'Maximum fuel consumption'

eq_conversion_HO(T,G)   'Energy conversion for heat-only generators'
eq_conversion_CHP(T,G)  'Energy conversion for CHP generators'
eq_ratio_BP(T,G)        'Electricity-to-heat ratio for backpressure generators'
eq_ratio_EX(T,G)        'Electricity-to-heat ratio for extraction generators'
;

* --- Equation definition ---

* check this below
eq_obj..                                obj                 =e= sum((T,G), C_f(T,G)*x_f(t,g));
eq_heat_balance(T)..                    D(t)                =e= sum(G, x_h(T,G));

eq_fuel_maximum(T,G)..                  x_f(T,G)            =l= Y_f(G);

eq_conversion_HO(T,G)$G_HO(G)..         eta(T,G)*x_f(T,G)   =e= x_h(T,G);
eq_conversion_CHP(T,G)$G_CHP(G)..       eta(T,G)*x_f(T,G)   =e= x_e(T,G) + beta_v(G)*x_h(T,G); 

eq_ratio_BP(T,G)$G_BP(G)..              x_e(T,G)            =e= beta_b(G)*x_h(T,G);
eq_ratio_EX(T,G)$G_EX(G)..              x_e(T,G)            =g= beta_b(G)*x_h(T,G);


* ======================================================================
* MODEL
* ======================================================================
* --- Model definition ---
model
all_eqs             'All equations'
/all/
;

*all_eqs.optfile = 1;

* ======================================================================
* SOLVE
* ======================================================================
solve all_eqs using lp minimizing obj;

* ======================================================================
* POST-PROCESSING
* ======================================================================


* ======================================================================
* REPORTING
* ======================================================================


* ======================================================================
* OUTPUT
* ======================================================================


* ======================================================================
* END OF FILE
