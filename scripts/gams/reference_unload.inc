PARAMETERS
lambda_h(T)             'Marginal cost of district heating system - reference case (EUR/MWh)'
;

lambda_h(T)             = EPS + eq_heat_balance.m(T);

execute_unload  '%transDir%/transfer_data.gdx' lambda_h, OPX_WH;
execute 'gdxdump %transDir%/transfer_data.gdx format=csv epsout=0 noheader output=%transDir%/ts-margcost-heat.csv symb=lambda_h';
execute 'gdxdump %transDir%/transfer_data.gdx format=csv epsout=0 noheader output=%transDir%/reference-opex-WH.csv symb=OPX_WH';
