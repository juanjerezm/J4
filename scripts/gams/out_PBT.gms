$eolCom !!

$ifi not setglobal project $SetGlobal project 'B0'
$ifi not setglobal scenario $SetGlobal scenario 'DKsup'


SETS
E                       'Entity'
G_HR
;

PARAMETERS
AF(E)
r(E)
lifetime(E)             'Lifetime of investment (years)'
L_p(G_HR)
C_p_inv(G_HR)
C_g_inv(G_HR)
k_inv_p
k_inv_g(G_HR)
OPX_REF(E)
;

VARIABLES
OPX(E)
WH_trnsctn
y_hr(G_HR)
;


$gdxin './results/%project%/%scenario%/results-%scenario%-integrated.gdx'
$load E, G_HR
$load AF, r, OPX, OPX_REF, WH_trnsctn, lifetime, L_p, C_p_inv, C_g_inv, k_inv_p, k_inv_g, y_hr

PARAMETER
I(E)                    'Investment'
S(E)                    'Annual savings'
N(E)                    'Number of years'
;

I('DHN')  = sum(G_HR, L_p(G_HR) * C_p_inv(G_HR) * y_hr.l(G_HR) * (1 - k_inv_p      ));
I('WHS')  = sum(G_HR,             C_g_inv(G_HR) * y_hr.l(G_HR) * (1 - k_inv_g(G_HR)));

S('DHN')  = (OPX_REF('DHN') - OPX.l('DHN') - WH_trnsctn.l);
S('WHS')  = (OPX_REF('WHS') - OPX.l('WHS') + WH_trnsctn.l);

N(E)      = lifetime(E);


SET
ITER /I01*I99/
;

SCALAR
CummulativeSavings
;

PARAMETER
PBT(E)
;

loop(ITER,

    if (ORD(ITER) = 1,
        CummulativeSavings = 0;
    elseif ORD(ITER) = N('DHN'),
        display "Payback time exceeds lifetime for DHN";
        break;
    elseif ORD(ITER) = CARD(ITER),
        display "Iteration limit reached for DHN";
        break;
    );

    CummulativeSavings = CummulativeSavings + S('DHN')/(1+r('DHN'))**ORD(ITER);

    if (CummulativeSavings > I('DHN'),
        PBT('DHN') = ORD(ITER) - (CummulativeSavings - I('DHN'))/S('DHN');
        break;
    );

    display CummulativeSavings;

)
;


loop(ITER,

    if (ORD(ITER) = 1,
        CummulativeSavings = 0;
    elseif ORD(ITER) = N('WHS'),
        display "Payback time exceeds lifetime for WHS";
        break;
    elseif ORD(ITER) = CARD(ITER),
        display "Iteration limit reached for WHS";
        break;
    );

    CummulativeSavings = CummulativeSavings + S('WHS')/(1+r('WHS'))**ORD(ITER);

    if (CummulativeSavings > I('WHS'),
        PBT('WHS') = ORD(ITER) - (CummulativeSavings - I('WHS'))/S('WHS');
        break;
    );

    display CummulativeSavings;

)
;

display "Final results";
display I, S, N;
display r;
display PBT;
