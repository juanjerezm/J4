# Notes of fuel sources


## Assumptions
- Fuel costs include the fuel price, carbon and energy taxes, CO2-quota price, and electricity tariffs for consumers (not generators).
    - DH generators pay for both tax and quota, according to [Taxing Energy Use 2019: Country Note – Denmark](https://www.oecd.org/tax/tax-policy/taxing-energy-use-denmark.pdf).
- We assume a "composite fuel" for biomass baseload: "biomass residues". It is a 75/25 mix of straw and woodwaste. This share is based on the actual share of straw and woodwaste in 2020's DH fuel mix in Denmark.


## Prices
Fuel prices are obtained from [Analysis prerequisites for Energinet 2020](https://ens.dk/service/fremskrivninger-analyser-modeller/analyseforudsaetninger-til-energinet), [Varmeplan Hovedstaden - Assumptions](https://varmeplanhovedstaden.dk/publikationer/anvendte-ffh50-forudsaetninger-potentialer-og-prognoser/), and [Varmeplan Hovedstaden - Market assumptions for waste energy](https://varmeplanhovedstaden.dk/wp-content/uploads/2023/07/FFH50-Markedsforudsaetninger-for-affaldsenergi_final-fd.pdf).

- Biogas            : Production price (VPH - assumptions)
- Coal              : Price for central plants (AF20).
- Fuel oil          : Price for central plants (AF20).
- Gas oil           : Average price for central and decentral plants (AF20).
- Natural gas       : Average price for central and decentral plants (AF20).
- Wood chips        : Average price for central and decentral plants (AF20).
- Wood pellets      : Average price for central and decentral plants (AF20).
- Wood waste        : Price for central plants (VPH - assumptions).
- Municipal waste   : Average price of imported, national, and local waste (VPH - waste assumptions). 
- Biomass residues  : Average price for straw for central and decentral plants(AF20), and 'biomasseaffald' (VPH - waste assumptions).

## Carbon quota
Emissions factor are obtained from [Socio-economic calculation assumptions, 2019](https://ens.dk/service/fremskrivninger-analyser-modeller/samfundsoekonomiske-analysemetoder), for the year 2020. Tables 11 and 12 are used.

CO2-quota price is obtained from [Analysis prerequisites for Energinet 2020](https://ens.dk/service/fremskrivninger-analyser-modeller/analyseforudsaetninger-til-energinet), for the year 2020.

## Taxes
In this analysis, we consider three main taxes: energy tax, CO2 tax, and electricity tax. Other taxes such as methane and NOx taxes are disregarded due to their relatively small impact. Values for taxes are obtained from [Overblik over afgiftssatser i 2019 og 2020 - Overview of tax rates in 2019 and 2020](https://www.pwc.dk/da/publikationer/2019/afgiftssatserne-2019-2020.pdf) from PwC.

The calculation procedure to reach uniform units [€/MWh] is done in the file ['data/_master-data/fuel data.xlsx'](../data/_master-data/fuel%20data.xlsx) on this repository.


## Electricity tariffs

Transmission network tariffs are included and obtained from [Energinet's website (*historiske tarifer*)](https://energinet.dk/el/elmarkedet/tariffer/aktuelle-tariffer/). Consumer-paid tariffs are included, while generator-paid tariffs are disregarded because of their relatively small impact and to keep the model simple.

Distribution network tariffs, which can be obtained from [Radius' website (*Ældre - se tidligere priser*)](https://radiuselnet.dk/elnetkunder/tariffer-og-netabonnement/historiske-tariffer/), are disregarded due to uncertainty about the specific voltage level of WH sources or DH generators.

More details can be found in the file ["dh-size-and-electricity-tariffs.docx"](../data/_master-data/dh-size-and-electricity-tariffs.docx) on this repository.
