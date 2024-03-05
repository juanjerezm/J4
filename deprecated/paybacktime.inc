* * ----------------------------------------------------------------
* * This sub-script calculates the discounted payback time of the investment in the heat recovery system.
* * ----------------------------------------------------------------
Set year /Y001*Y100/;  
alias(year, year_alias);

SCALARS
CAPEX
PaybackTime_simplified
PaybackTime_discounted
;

PARAMETERS
CashFlow(year)
CumulativeCashFlow(year)
;

CAPEX = sum(G_HR, C_inv(G_HR) * Y_hr.l(G_HR));

* Calculate discounted cash flows
CashFlow(year)$(ord(year) < lifetime) = (OPX_WH_ref.l - OPX_WH_int.l) / power(1 + dis_rate, ord(year));

* Calculate cumulative discounted cash flows
CumulativeCashFlow(year) = - CAPEX + sum(year_alias$(ord(year_alias) le ord(year)), CashFlow(year_alias));

* Calculate the simplified payback time
PaybackTime_simplified = CAPEX / (OPX_WH_ref.l - OPX_WH_int.l + 1e-6);

* Calculate the discounted payback time, linear approximation in last year
loop(year,
    if(ord(year) > lifetime,
        break;    
    );
    if(CumulativeCashFlow(year) > 0,
        PaybackTime_discounted = ord(year) - CumulativeCashFlow(year)/(CumulativeCashFlow(year) - CumulativeCashFlow(year-1));
        break;
    );
);