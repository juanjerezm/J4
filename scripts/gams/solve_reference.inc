* Solve optimization for the waste-heat source
solve model_WH_reference  using LP minimizing OPX_WH;

* Solve optimization for the district heating system
solve model_DH using LP minimizing OPX_DH;

* Output results (variables)
execute_unload '%outDir%/output_reference.gdx'  OPX_WH, x_f_wh, x_c, w_q_wh, OPX_DH, x_f_dh, x_h, x_e, w_q_dh;
