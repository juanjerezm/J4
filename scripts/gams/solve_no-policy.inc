* Solve optimization for the waste-heat source
solve model_WH_integrated using LP maximizing NPV;

* Fixes WHR generation in DH system to the value obtained in the WH source optimization
x_hr.fx(T,G_HR)         = x_hr.l(T,G_HR);

* Solve optimization for the district heating system
solve model_DH using LP minimizing OPX_DH;

* Output results (variables)
execute_unload '%outDir%/output_integrated.gdx' OPX_WH, x_f_wh, x_c, w_q_wh, OPX_DH, x_f_dh, x_h, x_e, w_q_dh, x_hr, Y_hr, NPV;