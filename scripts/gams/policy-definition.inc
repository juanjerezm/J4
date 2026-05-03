$ifi %country% == 'DE'  psi_k_p(G_HR)   = 0.5;
$ifi %country% == 'DE'  psi_k_g(G_HR)   = 0.5;
$ifi %country% == 'DE'  PARAMETER SCOP(G);                                          !! Seasonal COP needed for policy calculation
$ifi %country% == 'DE'  SCOP(G_HR)      = EPS + sum(T, eta_g(T,G_HR))/card(T);      !! According to policy technical factsheet
$ifi %country% == 'DE'  psi_c_h(T,G_HR) = MIN(SCOP(G_HR) / (SCOP(G_HR) - 1) * (5.5 - 0.75 * (6.8 - 17/SCOP(G_HR))), 92); !! 9.2 ¢/kWhe
$ifi %country% == 'DE'  psi_c_h(T,G_HR) = psi_c_h(T, G_HR) * (1 - 1/eta_g(T,G_HR)); !! From MWh-input to MWh-output

$ifi %country% == 'FR'  psi_k_p(G_HR)   = 0.6;
$ifi %country% == 'FR'  psi_k_g(G_HR)   = 0.3;
$ifi %country% == 'FR'  psi_c_h(T,G_HR) = EPS + 0;

$ifi %country% == 'DK'  psi_k_p(G_HR)   = EPS + 0;
$ifi %country% == 'DK'  psi_k_g(G_HR)   = EPS + 0;
$ifi %country% == 'DK'  psi_c_h(T,G_HR) = EPS + 0;
