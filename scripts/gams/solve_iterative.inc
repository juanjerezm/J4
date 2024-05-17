SET IDX     'Iteration index'   /I01*I20/;
SET RECORD  'Auxiliary set'     /'input', 'output'/;

PARAMETERS
log_n(IDX,G, RECORD)    'Log of full load hours over iterations'
;

$ifi %policytype% == 'support' $ifi %country% == 'DK' $goto DK_support_loop
* Normal loop here
loop(IDX,
    log_n(IDX, G_HR, 'input')  = N(G_HR);
    
    solve mdl_all using mip maximizing NPV_all;
    N(G_HR)                     = sum((T), x_h.l(T,G_HR))/(y_hr.l(G_HR)+1e-6);
    log_n(IDX, G_HR, 'output')  = N(G_HR);

    if (sum(G_HR, abs(log_n(IDX, G_HR, 'output') - log_n(IDX, G_HR, 'input'))) < 0.001 * 8760,
        break;
    elseif (sum(G_HR,N(G_HR)) = 0),
        break;
    );

    MU_DH(G_HR)     = MU_DH(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    MU_HR(G_HR)     = MU_HR(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    pi_h(T,G_HR)    = ((MC_DH(T) - MU_DH(G_HR)) + (MC_HR(T,G_HR) + MU_HR(G_HR)))/2;
    F_a(T,G_HR)$((MC_HR(T,G_HR) + MU_HR(G_HR)) GE (MC_DH(T) - MU_DH(G_HR))) = 0;
);
$goto end_loop


$label DK_support_loop
loop(IDX,
    log_n(IDX, G_HR, 'input')  = N(G_HR);
    
    solve mdl_all using mip maximizing NPV_all;
    N(G_HR)                     = sum((T), x_h.l(T,G_HR))/(y_hr.l(G_HR)+1e-6);
    log_n(IDX, G_HR, 'output')  = N(G_HR);

    if (sum(G_HR, abs(log_n(IDX, G_HR, 'output') - log_n(IDX, G_HR, 'input'))) < 0.001 * 8760,
        break;
    elseif (sum(G_HR,N(G_HR)) = 0),
        break;
    );

    MU_DH(G_HR)     = MU_DH(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    MU_HR(G_HR)     = MU_HR(G_HR) * log_n(IDX,G_HR,'input')/log_n(IDX,G_HR,'output');
    pi_h(T,G_HR)    = ((MC_DH(T) - MU_DH(G_HR)) + (MC_HR(T,G_HR) + MU_HR(G_HR)))/2;
    pi_h(T,G_HR)$(pi_h(T,G_HR) GE (pi_h_ceil(G_HR)-MU_DH(G_HR))) = pi_h_ceil(G_HR)-MU_DH(G_HR);
    F_a(T,G_HR)$((MC_HR(T,G_HR) + MU_HR(G_HR)) GE (MC_DH(T) - MU_DH(G_HR))) = 0;
);
$label end_loop
