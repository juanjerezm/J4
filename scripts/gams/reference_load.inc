PARAMETERS
pi_hr(T)                'Price of recovered heat (EUR/MWh)'
* /
* $onDelim
* $include    './data/common/ts-heat-price.csv'
* $offDelim
* /

lambda_h(T)             'Marginal cost of district heating system - reference case (EUR/MWh)'
/
$onDelim
$include    '%transDir%/ts-margcost-heat.csv'
$offDelim
/
;

* Price of recovered heat is set at the marginal cost of HP operation
pi_hr(T)                = sum(G_HR, C_h(G_HR) + C_f(T,G_HR)/(eta(T,G_HR)+1))/card(G_HR);

* WHR is available if its price is lower than the marginal cost of the district heating system
F_a(T,G_HR)             = EPS + 1$(pi_hr(T) < lambda_h(T));


SCALAR OPX_WH_REF           'Operating cost for WH - reference case (EUR)'
/
$onDelim
$include    '%transDir%/reference-opex-WH.csv'
$offDelim
/
;
