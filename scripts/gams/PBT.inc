SCALAR
CummulativeSavings
;

PARAMETER
PBT(E)
;

* DHN
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

    CummulativeSavings = CummulativeSavings + OPEX_Savings('DHN')/(1+r('DHN'))**ORD(ITER);

    if (CummulativeSavings > CAPEX('DHN'),
        PBT('DHN') = EPS + ORD(ITER) - (CummulativeSavings - CAPEX('DHN'))/OPEX_Savings('DHN');
        break;
    );
)
;

* WHS
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

    CummulativeSavings = CummulativeSavings + OPEX_Savings('WHS')/(1+r('WHS'))**ORD(ITER);

    if (CummulativeSavings > CAPEX('WHS'),
        PBT('WHS') = EPS + ORD(ITER) - (CummulativeSavings - CAPEX('WHS'))/OPEX_Savings('WHS');
        break;
    );
)
;
