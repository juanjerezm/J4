* NOTES:
* - This file solves the WHS model for a unique value of heat price (pi_h)

* ======================================================================
* MODEL
* ======================================================================
* ----- Model definition -----
model
all_eqs             'All equations'
/all/
;

all_eqs.optfile = 1;

* ======================================================================
* SOLVE
* ======================================================================
solve all_eqs using MIP minimizing obj;

* ======================================================================
* POST-PROCESSING
* ======================================================================
PARAMETERS
cold_share    'Share of cold produced by technology'
;

cold_share     = EPS + sum((G_HR(G),T), x_c.l(T, G_HR)) / sum((G,T), x_c.l(T, G));

* ======================================================================
* REPORTING
* ======================================================================
display "Variable levels"
display obj.l;
display Y_h.l;
display cold_share;

* ======================================================================
* OUTPUT
* ======================================================================
* --- Create output directory and unload GDX file --- *
execute             'mkdir %dir_out%'
execute_unload      '%dir_out%\output_%heat_price%.gdx'

file fx / '../../results/%DH_name%/%WH_name%/ts-WHR-%heat_price%.csv' /; 

if (Y_h.l('HP_EHR') >0,
    put fx;
    loop(T,
        put T.tl:0, ",", x_h.l(T,'HP_EHR'):0:6 /;  
    );
    putclose fx;
);
* ======================================================================
* END OF FILE