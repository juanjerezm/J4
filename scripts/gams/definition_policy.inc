$ifi %country% == 'DE' k_inv_p          = 0.5;

$ifi %country% == 'FR' k_inv_p          = 0.6;
$ifi %country% == 'FR' k_inv_g(G_HR)    = 0.3;

$ifi %country% == 'DK'  PARAMETER AF_og(E);
$ifi %country% == 'DK'  AF_og(E)        = AF(E); 
$ifi %country% == 'DK'  r('DHN')        = 0.031;
$ifi %country% == 'DK'  AF(E)           = r(E) * (1 + r(E)) ** lifetime(E) / ((1 + r(E)) ** lifetime(E) - 1);
$ifi %country% == 'DK'  pi_h_ceil(G_HR) = 93 * 0.1342 * 3.6; !! 93 DKK/GJ * 0.1342 €/DKK * 3.6 GJ/MWh
* $ifi %country% == 'DK'  pi_h(T,G_HR)$(pi_h(T,G_HR) GE (pi_h_ceil(G_HR)-MU_DH(G_HR))) = pi_h_ceil(G_HR)-MU_DH(G_HR);
