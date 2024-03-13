PARAMETERS
pi_hr(T)                'Price of recovered heat (EUR/MWh)'
/
$onDelim
$include    './data/common/ts-waste-heat-price.csv'
$offDelim
/

lambda_h(T)             'Marginal cost of district heating system - reference case (EUR/MWh)'
/
$onDelim
$include    '%transDir%/ts-margcost-heat.csv'
$offDelim
/
;


* WHR is available if its price is lower than the marginal cost of the district heating system
F_a(T,G_HR)             = EPS + 1$(pi_hr(T) < lambda_h(T));


SCALAR OPX_WH_REF           'Operating cost for WH - reference case (EUR)'
/
$onDelim
$include    '%transDir%/reference-opex-WH.csv'
$offDelim
/
;
