$eolCom !!

$ifi not setglobal project $SetGlobal project 'B0'
$ifi not setglobal scenario $SetGlobal scenario 'FRsup'


SETS
E                       'Entity'
G_HR
;

PARAMETERS
AF(E)
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
$load AF, OPX, OPX_REF, WH_trnsctn, lifetime, L_p, C_p_inv, C_g_inv, k_inv_p, k_inv_g, y_hr

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
tolerance       /0.001/
IRR_Low         /0/
IRR_High        /10/
IRR_Estimation
NPV_Estimation
;

PARAMETER
IRR(E)
;

loop(ITER,

    if (sum(G_HR, y_hr.l(G_HR)) < tolerance,
        display "No investment for DHN";
        break;
    );

    IRR_Estimation = (IRR_Low + IRR_High) / 2;
    NPV_Estimation = - I('DHN') + S('DHN') * (1 - (1 + IRR_Estimation)**(-N('DHN'))) / IRR_Estimation;
    
    display IRR_Estimation, NPV_Estimation;
    
    if (abs(IRR_Low-IRR_High) < tolerance,
        IRR('DHN') = IRR_Estimation;
        display "Convergence reached for DHN";
        break;
    elseif NPV_Estimation > 0,
        IRR_Low = IRR_Estimation;   !! if NPV is positive, the IRR is higher than the estimation
    elseif NPV_Estimation < 0,
        IRR_High = IRR_Estimation;  !! if NPV is negative, the IRR is lower than the estimation
    );

    if (ORD(ITER) = CARD(ITER),
        display "No convergence for DHN";
    );
)
;

* reset
IRR_Low = 0;
IRR_High = 1;

loop(ITER,
    
    if (sum(G_HR, y_hr.l(G_HR)) < tolerance,
        display "No investment for DHN";
        break;
    );

    IRR_Estimation = (IRR_Low + IRR_High) / 2;
    NPV_Estimation = - I('WHS') + S('WHS') * (1 - (1 + IRR_Estimation)**(-N('WHS'))) / IRR_Estimation;
    
    display IRR_Estimation, NPV_Estimation;
    
    if (abs(IRR_Low-IRR_High) < tolerance,
        IRR('WHS') = IRR_Estimation;
        display "Convergence reached for WHS";
        break;
    elseif NPV_Estimation > 0,
        IRR_Low = IRR_Estimation;   !! if NPV is positive, the IRR is higher than the estimation
    elseif NPV_Estimation < 0,
        IRR_High = IRR_Estimation;  !! if NPV is negative, the IRR is lower than the estimation
    );

    if (ORD(ITER) = CARD(ITER),
        display "No convergence for WHS";
    );
)
;

display y_hr.l;
display AF;
DISPLAY I, S, N;


display "Final results";
display IRR;
