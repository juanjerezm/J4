# Notes of fuel sources

## Assumptions
- Fuel costs include the fuel price, carbon and energy taxes, CO2-quota price, and electricity tariffs for consumers (not generators).
    - DH generators pay for both tax and quota, according to [Taxing Energy Use 2019: Country Note – Denmark](https://www.oecd.org/tax/tax-policy/taxing-energy-use-denmark.pdf).


## Fuel prices
Fuel prices are obtained from [Analysis prerequisites for Energinet 2023](https://ens.dk/service/fremskrivninger-analyser-modeller/analyseforudsaetninger-til-energinet), [Socio-economic calculation assumptions, 2022](https://ens.dk/service/fremskrivninger-analyser-modeller/samfundsoekonomiske-analysemetoder), [Varmeplan Hovedstaden - Assumptions](https://varmeplanhovedstaden.dk/publikationer/anvendte-ffh50-forudsaetninger-potentialer-og-prognoser/), and [Varmeplan Hovedstaden - Market assumptions for waste energy](https://varmeplanhovedstaden.dk/wp-content/uploads/2023/07/FFH50-Markedsforudsaetninger-for-affaldsenergi_final-fd.pdf).

- Biogas            : Socioeconomic prise at consumption place (Socioeconomic calculations 2022, Table 12, year 2023)
- Coal              : Price for central plants (AF23).
- Fuel oil          : Price for central plants (AF23).
- Gas oil           : Average price for central and decentral plants (AF23).
- Natural gas       : Average price for central and decentral plants (AF23).
- Wood chips        : Average price for central and decentral plants (AF23).
- Wood pellets      : Average price for central and decentral plants (AF23).
- Wood waste        : Price for central plants (VPH - assumptions).
- Municipal waste   : Average price of imported, national, and local waste (VPH - waste assumptions). 

## Carbon emissions and quotas
- Emissions factor are obtained from [Socio-economic calculation assumptions, 2022](https://ens.dk/service/fremskrivninger-analyser-modeller/samfundsoekonomiske-analysemetoder). Tables 13 and 14.
- CO2-quota price is obtained from [Analysis prerequisites for Energinet 2023](https://ens.dk/service/fremskrivninger-analyser-modeller/analyseforudsaetninger-til-energinet), for the year 2023.

## Taxes (TO BE UPDATED TO 2023)
In this analysis, we consider three main taxes: energy tax, CO2 tax, and electricity tax. Other taxes such as methane and NOx taxes are disregarded due to their relatively small impact. Values for taxes are obtained from [Oversigter over godtgørelse og satser m.m. - Overviews of compensation and rates](https://www.pwc.dk/da/afgiftsvejledningen/godtgorelse-satser.html#bilag-6) from PwC; [Energy prices and taxes - Danish Energy Agency](https://ens.dk/service/statistik-data-noegletal-og-kort/energipriser-og-afgifter); [Energy taxes in 2023](https://www.bdo.dk/da-dk/faglig-info/brancher/energi-og-forsyning/energiafgifter-i-2023). All sources are equivalent.

The calculation procedure to reach uniform units [€/MWh] is done in the file ['data/_master-data/fuel data.xlsx'](../data/_master-data/fuel%20data%20-%202023.xlsx) on this repository.


## Electricity tariffs  (TO BE UPDATED TO 2023)

Transmission network tariffs are included and obtained from [Energinet's website (*historiske tarifer*)](https://energinet.dk/el/elmarkedet/tariffer/aktuelle-tariffer/). Consumer-paid tariffs are included, while generator-paid tariffs are disregarded because of their relatively small impact and to keep the model simple.

Distribution network tariffs, which can be obtained from [Radius' website (*Ældre - se tidligere priser*)](https://radiuselnet.dk/elnetkunder/tariffer-og-netabonnement/historiske-tariffer/), are disregarded due to uncertainty about the specific voltage level of WH sources or DH generators.

More details can be found in the file ["dh-size-and-electricity-tariffs.docx"](../data/_master-data/dh-size-and-electricity-tariffs.docx) on this repository.
