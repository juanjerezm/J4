SCALAR
tolerance       /0.001/
IRR_Low         /0/
IRR_High        /5/
IRR_Estimation
NPV_Estimation
;

PARAMETER
IRR(E)
;

loop(ITER,

    if (sum(G_HR, HeatRecoveryCapacity(G_HR,'integrated')) < tolerance,
        display "No investment for DHN";
        break;
    );

    IRR_Estimation = (IRR_Low + IRR_High) / 2;
    NPV_Estimation = - CAPEX('DHN') + OPEX_Savings('DHN') * (1 - (1 + IRR_Estimation)**(-N('DHN'))) / (IRR_Estimation + D6);
        
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
    
    if (sum(G_HR, HeatRecoveryCapacity(G_HR,'integrated')) < tolerance,
        display "No investment for DHN";
        break;
    );

    IRR_Estimation = (IRR_Low + IRR_High) / 2;
    NPV_Estimation = - CAPEX('WHS') + OPEX_Savings('WHS') * (1 - (1 + IRR_Estimation)**(-N('WHS'))) / (IRR_Estimation + D6);
        
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
