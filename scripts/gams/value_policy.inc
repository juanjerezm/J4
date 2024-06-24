$ifi %country% == 'DE'  value_support('DHN') = sum(G_HR, L_p(G_HR) * C_p_inv       * y_hr.l(G_HR) * k_inv_p      ) * AF('DHN');
$ifi %country% == 'DE'  value_support('WHS') = sum(G_HR,             C_g_inv(G_HR) * y_hr.l(G_HR) * k_inv_g(G_HR)) * AF('WHS') + pi_q * sum((T, G_HR), x_h.l(T,G_HR)*CO2_ref(T));

$ifi %country% == 'FR'  value_support('DHN') = sum(G_HR, L_p(G_HR) * C_p_inv       * y_hr.l(G_HR) * k_inv_p      ) * AF('DHN');
$ifi %country% == 'FR'  value_support('WHS') = sum(G_HR,             C_g_inv(G_HR) * y_hr.l(G_HR) * k_inv_g(G_HR)) * AF('WHS');

$ifi %country% == 'DK'  value_support('DHN') = sum(G_HR, L_p(G_HR) * C_p_inv       * y_hr.l(G_HR) * k_inv_p      ) * (AF_og('DHN') - AF('DHN'));
$ifi %country% == 'DK'  value_support('WHS') = 0;
