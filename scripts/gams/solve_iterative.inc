SET IDX     'Iteration index'   /I01*I20/;
SET RECORD  'Auxiliary set'     /'input', 'output'/;

PARAMETERS
log_n(IDX,G, RECORD)    'Log of full load hours over iterations'
tol                     'Relative tolerance for convergence'    /0.001/
;

$ifi %policytype% == 'support' $ifi %country% == 'DK' $goto DK_support_loop
* Normal loop here
loop(IDX,
    log_n(IDX, G_HR, 'input')  = EPS + N(G_HR);
    
    solve mdl_all using mip maximizing NPV_all;
    N(G_HR)                     = EPS + sum((T), x_h.l(T,G_HR))/(y_hr.l(G_HR) + D6);
    log_n(IDX, G_HR, 'output')  = EPS + N(G_HR);

    if (sum(G_HR, abs(log_n(IDX, G_HR, 'output') - log_n(IDX, G_HR, 'input'))) < tol * card(T),
        break;
    elseif (sum(G_HR,N(G_HR)) = 0),
        break;
    );

    FixedBid(G_HR)     = FixedBid(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    FixedAsk(G_HR)     = FixedAsk(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    BidPrice(T,G_HR)   = MarginalBid(T)      - FixedBid(G_HR);
    AskPrice(T,G_HR)   = MarginalAsk(T,G_HR) + FixedAsk(G_HR);

    pi_h(T,G_HR)       = (BidPrice(T,G_HR) + AskPrice(T,G_HR))/2;
    F_a(T,G_HR)$( AskPrice(T,G_HR) GE BidPrice(T,G_HR) ) = 0;
);
$goto end_loop


$label DK_support_loop
loop(IDX,
    log_n(IDX, G_HR, 'input')  = EPS + N(G_HR);
    
    solve mdl_all using mip maximizing NPV_all;
    N(G_HR)                     = EPS + sum((T), x_h.l(T,G_HR))/(y_hr.l(G_HR) + D6);
    log_n(IDX, G_HR, 'output')  = EPS + N(G_HR);

    if (sum(G_HR, abs(log_n(IDX, G_HR, 'output') - log_n(IDX, G_HR, 'input'))) < tol * card(T),
        break;
    elseif (sum(G_HR,N(G_HR)) = 0),
        break;
    );

    FixedBid(G_HR)     = FixedBid(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    FixedAsk(G_HR)     = FixedAsk(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    BidPrice(T,G_HR)   = MarginalBid(T)      - FixedBid(G_HR);
    AskPrice(T,G_HR)   = MarginalAsk(T,G_HR) + FixedAsk(G_HR);

    pi_h(T,G_HR)       = (BidPrice(T,G_HR) + AskPrice(T,G_HR))/2;
    pi_h(T,G_HR)$(pi_h(T,G_HR) GE (pi_h_ceil(G_HR)-FixedBid(G_HR))) = pi_h_ceil(G_HR)-FixedBid(G_HR);
    F_a(T,G_HR)$( AskPrice(T,G_HR) GE BidPrice(T,G_HR) ) = 0;
);
$label end_loop
