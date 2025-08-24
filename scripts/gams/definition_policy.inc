$ifi %country% == 'DE'  k_inv_p         = 0.5;
$ifi %country% == 'DE'  k_inv_g(G_HR)   = 0.5;
$ifi %country% == 'DE'  PARAMETER SCOP(G);
$ifi %country% == 'DE'  SCOP(G_HR)      = EPS + sum(T, eta_g(T,G_HR))/card(T);  !! Accordding to policy technical factsheet
$ifi %country% == 'DE'  k_op_g(T, G_HR) = MIN(SCOP(G_HR) / (SCOP(G_HR) - 1) * (5.5 - 0.75 * (6.8 - 17/SCOP(G_HR))), 92); !! 9.2 ¢/kWh
$ifi %country% == 'DE'  k_op_g(T, G_HR) = k_op_g(T, G_HR) * (eta_g(T,G_HR) - 1)/eta_g(T,G_HR); !! From MWh-input to MWh-output

$ifi %country% == 'FR'  k_inv_p         = 0.6;
$ifi %country% == 'FR'  k_inv_g(G_HR)   = 0.3;
$ifi %country% == 'FR'  k_op_g(T, G_HR) = EPS + 0.0;

$ifi %country% == 'DK'  k_inv_p         = EPS + 0.0;
$ifi %country% == 'DK'  k_inv_g(G_HR)   = EPS + 0.0;
$ifi %country% == 'DK'  k_op_g(T, G_HR) = EPS + 0.0;
$ifi %country% == 'DK'  pi_h_ceil(G_HR) = 93 * 0.1342 * 3.6; !! 93 DKK/GJ * 0.1342 €/DKK * 3.6 GJ/MWh
