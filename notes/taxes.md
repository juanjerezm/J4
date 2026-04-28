
# Tax Notes

## Denmark

The following excise taxes have been considered in this analysis:

1. Electricity tax, levied on electricity consumption.
2. Energy tax, levied on fuel and waste consumption.
3. CO2-tax, levied on fuel consumption based on the carbon content of the fuel.
4. Emission tax, levied on equivalent carbon emissions for plants under EU-ETS, introduced in 2025.

Several taxes differentiate between fuel used for heat production and fuel used for electricity production in CHP units. They can choose between two methods for allocating fuel consumption [(PwC CHP page)](https://www.pwc.dk/da/afgiftsvejledningen/kraftvarmevaerker-og-fjernvarmevaerker.html):

1. Thermal efficiency rule (120%)
2. Electrical efficiency rule (67%)

For this analysis, the first method is chosen and is applied as follows:

> ```text
> Fuel_to_heat = Heat Produced / 1.2
> Fuel_to_electricity = Total Fuel - Fuel_to_heat
> ```

---

### Electricity tax (*elafgift*)

#### Sources

1. **PwC Denmark** (2025). *Tax Guide 2026: Overview of energy tax settlement and reimbursement in Denmark* (Afgiftsvejledning 2026). Available at: [https://www.pwc.dk/da/afgifter](https://www.pwc.dk/da/afgifter).

#### Rates

The electricity tax for 2025 is 0.720 DKK/kWh [(PwC Overview - Annex 1)](https://www.pwc.dk/da/afgiftsvejledningen/godtgorelse-satser.html#bilag-1). However, the effective tax rate for VAT-registered companies corresponds to 0.004 DKK/kWh after reimbursements [(PwC Overview - Annex 5)](https://www.pwc.dk/da/afgiftsvejledningen/godtgorelse-satser.html#bilag-5).

---

### Energy tax (*mineralolie-, kul-, gas-, affaldafgift*)

#### Sources

1. **PwC Denmark** (2025). *Tax Guide 2026: Overview of energy tax settlement and reimbursement in Denmark* (Afgiftsvejledning 2026). Available at: [https://www.pwc.dk/da/afgifter](https://www.pwc.dk/da/afgifter).
2. **Skatteministeriet** (2024). *Electricity and cogeneration production* (El- og kraftvarmeproduktion
Indhold). Available at: [https://info.skat.dk/data.aspx?oid=2061646](https://info.skat.dk/data.aspx?oid=2061646).
3. **Folketinget** (2024). *Act amending the CO₂ tax act, the mineral oil energy tax act, the natural gas and town gas tax act, the coal tax act, and various other acts — implementing parts of the Green Tax Reform for industry* (Lov om ændring af lov om kuldioxidafgift af visse energiprodukter m.fl. — Grøn skattereform for industri mv.). Bill no. L 183, Folketinget 2023-24. Adopted 4 June 2024. Skatteministeriet, Copenhagen. j.nr. 2022-14171. Available at: [https://www.retsinformation.dk/eli/lta/2024/683](https://www.retsinformation.dk/eli/lta/2024/683).

#### Rates

Excise tax rates on various fuels are sourced from [(PwC Overview - Annex 1)](https://www.pwc.dk/da/afgiftsvejledningen/godtgorelse-satser.html#bilag-1).

For waste-incineration plants, two tax elements apply [(PwC - Afgift på affald)](https://www.pwc.dk/da/afgiftsvejledningen/afgift-paa-affald.html):

- *Affaldsvarmeafgift*: charged per unit of output heat.
- *Tillægsafgift*: charged per unit of input energy in fuel

#### Coverage and exemptions

Fuels used for heat production delivered to the district heating network are not eligible for energy tax reimbursement, as this energy is not consumed internally [(PwC - Energiafgifter)](https://www.pwc.dk/da/afgiftsvejledningen/energiafgifter.html).

For CHP plants, the fuel share allocated to electricity production is fully exempt from energy tax [(PwC CHP page)](https://www.pwc.dk/da/afgiftsvejledningen/kraftvarmevaerker-og-fjernvarmevaerker.html).

---

### CO₂ tax on fuels (*CO₂-afgift*)

#### Sources

1. **PwC Denmark** (2025). *Tax Guide 2026: Overview of energy tax settlement and reimbursement in Denmark* (Afgiftsvejledning 2026). Available at: [https://www.pwc.dk/da/afgifter](https://www.pwc.dk/da/afgifter).
2. **Folketinget** (2024). *Act amending the CO₂ tax act, the mineral oil energy tax act, the natural gas and town gas tax act, the coal tax act, and various other acts — implementing parts of the Green Tax Reform for industry* (Lov om ændring af lov om kuldioxidafgift af visse energiprodukter m.fl. — Grøn skattereform for industri mv.). Bill no. L 183, Folketinget 2023-24. Adopted 4 June 2024. Skatteministeriet, Copenhagen. j.nr. 2022-14171. Available at: [https://www.retsinformation.dk/eli/lta/2024/683](https://www.retsinformation.dk/eli/lta/2024/683).
3. **Skatteministeriet** (2024). *CO₂ tax on fuels* (CO₂-afgift på brændstoffer). Available at: [https://info.skat.dk/data.aspx?oid=2061646](https://info.skat.dk/data.aspx?oid=2061646).

#### Rates and coverage

Rates for CO₂ tax on fuels are sourced from [(PwC Overview - Annex 1)](https://www.pwc.dk/da/afgiftsvejledningen/godtgorelse-satser.html#bilag-1). Applicability and reimbursement rates vary by end use and ETS status of the plant.

For waste-incineration plants, the CO₂ tax is levied on the share of non-biodegradable waste used as fuel [(PwC - Afgift på affald)](https://www.pwc.dk/da/afgiftsvejledningen/afgift-paa-affald.html).

**Fuel allocated to heat production** (heat-only and CHP heat share):

- ETS plants: 10% reimbursement [(L183 §9a stk. 2)](https://www.retsinformation.dk/eli/lta/2024/683)
- Non-ETS plants: no reimbursement [(L183 §9e)](https://www.retsinformation.dk/eli/lta/2024/683)

**Fuel allocated to electricity production** (CHP only):

- ETS plants: fully exempt [(CO₂-afgiftsloven §7 stk. 1 nr. 2-3)](https://www.elov.dk/co2-afgiftsloven/paragraf/7/)
- Non-ETS plants: no reimbursement [(CO₂-afgiftsloven §7 stk. 1 nr. 2-3)](https://www.elov.dk/co2-afgiftsloven/paragraf/7/)

---

### Emissions tax (*emissionsafgift*)

#### Sources

1. **PwC Denmark** (2025). *Tax Guide 2026: Overview of energy tax settlement and reimbursement in Denmark* (Afgiftsvejledning 2026). Available at: [https://www.pwc.dk/da/afgifter](https://www.pwc.dk/da/afgifter).
2. **Folketinget** (2024). *Act on taxation of CO₂e emissions from quota-covered sectors (Emissions Tax Act)* (Lov om afgift af CO₂e-emissioner fra kvoteomfattede sektorer — emissionsafgiftsloven). Bill no. L 182, Folketinget 2023-24. Adopted 4 June 2024. Skatteministeriet, Copenhagen. j.nr. 2022-14171. Available at: [https://www.retsinformation.dk/eli/lta/2024/683](https://www.retsinformation.dk/eli/lta/2024/683).

#### Coverage and rates

The emissions tax applies exclusively to ETS-covered plants [(L182 §1-2)](https://www.retsinformation.dk/eli/lta/2024/683). It is levied on actual CO₂ emissions, calculated per ton of CO₂ for which ETS quotas must be surrendered, regardless of whether the fuel is used for heat or electricity production.

Tax rates are sourced from [(PwC overview - Annex 4)](https://www.pwc.dk/da/afgiftsvejledningen/godtgorelse-satser.html#bilag-4).

---

## Germany

The following excise taxes have been considered in this analysis:

1. Electricity tax (*Stromsteuer*)
2. Energy tax (*Energiesteuer*)
3. National carbon pricing (*Brennstoffemissionshandelsgesetz - BEHG*)

The electricity tax and the national carbon pricing are levied on the energy supplier, and passed down to the consumer in the energy price. As this analysis uses fuel/electricity price data that does not reflect the inclusion of these taxes they are included explicitly as taxes on the consumer side.

---

### Electricity tax (*Stromsteuer*)

**Legal basis**: Stromsteuergesetz (StromStG) of 24 March 1999, last amended 22 December 2025 (BGBl. 2025 I Nr. 340).

#### Sources

1. [StromStG (gesetze-im-internet.de)](https://www.gesetze-im-internet.de/stromstg/index.html)
2. [Zoll.de — electricity tax overview](https://www.zoll.de/DE/Fachthemen/Steuern/Verbrauchsteuern/Strom/strom_node.html)

#### Coverage and rate

This tax is levied on all electricity withdrawn from the supply network in Germany by a final consumer. The statutory rate under §3 StromStG is 20.50 €/MWh (2.05 ct/kWh), unchanged since 2003.

#### Exemptions and rebates

The StromStG contains several exemption provisions under §9, but none apply to electricity used for heat production in a district heating context.

#### Relationship to the EU ETS

This tax is entirely separate from the EU ETS. Being inside or outside the EU ETS has no effect on electricity tax liability.

---

### Energy tax (*Energiesteuer*)

**Legal basis**: Energiesteuergesetz (EnergieStG) of 15 July 2006, last amended 22 December 2025 (BGBl. 2025 I Nr. 340). Rates are set in §2 EnergieStG and have been unchanged since 2003.

#### Sources

1. [EnergieStG (gesetze-im-internet.de)](https://www.gesetze-im-internet.de/energiestg/index.html)
2. [Zoll.de — §53 relief guidance](https://www.zoll.de/DE/Fachthemen/Steuern/Verbrauchsteuern/Energie/energie_node.html)

#### Coverage

Of the fuels used in this model, only two are subject to the energy tax:

- *Natural gas*, taxed at the Heizstoff (heating fuel) rate of 5.50 €/MWh under §2 Abs. 3 Satz 1 Nr. 4 EnergieStG.
- *Gas oil*, taxed at the low-sulphur rate of 61.35 €/m3  under §2 Abs. 3 Satz 1 Nr. 1 lit. a EnergieStG.

The remaining fuels are outside the effective scope of the tax:

- *Biogas, wood chips, wood pellets* While the catch-all provision of §2 Abs. 4 EnergieStG nominally applies to unlisted energy products, no real tax liability arises in practice for solid or gaseous biomass used directly in a stationary plant.
- *Municipal waste* — waste delivered to an incineration plant arrives as a disposal stream, not as a purchased fuel commodity. Under §23 EnergieStG, tax liability requires a fuel to be first placed on the market as a heating fuel, which does not occur in the case of waste incineration. No energy tax liability arises for the plant operator on municipal waste.
- *Electricity* covered instead by the Stromsteuergesetz (StromStG).

#### Relationship to the EU ETS

The energy tax and the EU ETS are entirely separate instruments. Liability under the EnergieStG, and eligibility for the §53 CHP rebate, are not affected by whether a plant is covered by the EU ETS. A plant inside the EU ETS pays both systems independently, with no offset between them.

#### CHP exemption — §53 EnergieStG

CHP plants may claim a full rebate of energy tax on the fuel input attributed to electricity generation. The legal definition of what counts as "used for electricity generation" is precise: it covers all fuel that directly participates in the thermodynamic process driving electricity generation — i.e., the entire fuel input to the engine or turbine — regardless of the fact that a portion of the energy exits as useful heat. **This analysis assumes CHP plants are configured such that all fuel passes through the electricity-generating thermodynamic process**.

One condition applies: the §53 rebate on fuel input is not available if the plant simultaneously claims an electricity tax (Stromsteuer) exemption on its electricity output under §9 Abs. 1 Nr. 4, 5, or 6 StromStG. **The CHP plants in this model do not meet the criteria for those Stromsteuer output exemptions, so the §53 fuel-side rebate is available to them without conflict**.

Heat-only boilers receive no equivalent relief; the full statutory rate applies to all fuel consumed.

Sources:[§53 EnergieStG (gesetze-im-internet.de)](https://www.gesetze-im-internet.de/energiestg/__53.html), [Zoll.de — §53 relief guidance](https://www.zoll.de/DE/Fachthemen/Steuern/Verbrauchsteuern/Energie/Steuerbeguenstigung/Steuerentlastung/Stromerzeugung/stromerzeugung_node.html)

---

### National CO₂ Price — Fuel Emissions Trading (*Brennstoffemissionshandelsgesetz - BEHG*)

**Legal basis**: Gesetz über einen nationalen Zertifikatehandel für Brennstoffemissionen (BEHG) of 12 December 2019 (BGBl. I S. 2728), last amended 27 February 2025 (BGBl. 2025 I Nr. 70). The implementing ordinance is the Brennstoffemissionshandelsverordnung (BEHV).

#### Sources

1. [BEHG (gesetze-im-internet.de)](https://www.gesetze-im-internet.de/behg/index.html)
2. [nEHS — understanding the system](https://www.dehst.de/EN/Topics/nEHS/understanding-nEHS/understanding-nehs_node.html)
3. [nEHS — sale and pricing](https://www.dehst.de/EN/Topics/nEHS/Sale-and-auction/sale-auction_node.html)
4. [DEHSt factsheet on nEHS](https://www.dehst.de/SharedDocs/downloads/EN/publications/factsheets/factsheet_nehs.pdf)
5. National carbon pricing overview [Zoll website](https://www.zoll.de/EN/Businesses/Emissions-Trading/emissions-trading_node.html)

#### Structure and liable party

Unlike the EU ETS, the BEHG follows an upstream approach where the liable parties are not the operators who combust the fuels, but those who place them on the market. The CO₂ cost is passed downstream and embedded in the fuel purchase price paid by the DH plant operator. The one exception to this upstream logic is municipal waste: waste incineration plant operators are directly liable under the BEHG for the fossil fraction of waste they combust, since waste does not travel through a conventional fuel supply chain.

#### Interaction with the EU ETS

§7 Abs. 5 BEHG provides that double-loading of fuels used in EU ETS installations must be avoided. Pre-deduction and retroactive compensation mechanisms exist.
Therefore, in this model ETS units do not bear the BEHG costs, except for municipal waste plants as waste incineration is not within the EU ETS scope in germany [Source](https://www.dehst.de/EN/Topics/EU-ETS-1/Stationary/Waste-Incineration/waste-incineration_node.html).

#### Rate

The BEHG fixed-price phase ran from 2021 to 2025, with the certificate price rising annually. The price for 2025 is €55 per tonne of CO₂. From 2026, the fixed-price phase ends and certificates are auctioned within a price corridor of €55–€65/tCO₂. From 2027 onwards the price is fully market-determined.

#### Coverage by fuel

- **Natural gas**: Covered by Anlage 1 BEHG, since 2021.
- **Gas oil**: Covered by Anlage 1 BEHG, since 2021.
- **Biogas**: Falls under the BEHG in principle, but it is assigned an emission factor of 0 gCO₂/kWh, carrying no certificate cost.
- **Wood chips, wood pellets**: Biogenic fuels carry a zero emission factor; no CO₂ cost arises.
- **Municipal waste**: Waste incineration was brought into the BEHG scope from 1 January 2024. Only the CO₂ from the fossil fraction of the waste is priced; the biogenic fraction is exempt.
- **Electricity**: Electricity consumption is not subject to the BEHG.

#### Emission factors

The BEHG certificate price is expressed per tonne of CO₂. To translate this into a cost per unit of fuel consumed, the standard emission factors from the implementing ordinances [EBeV 2030, Anlage 2](https://www.gesetze-im-internet.de/ebev_2030/anlage_2.html) apply. The key values are:

- **Natural gas**: 0.0558 tCO₂/GJ
- **Gas oil**: 0.074 tCO₂/GJ
- **Municipal waste**: 0.0982 tCO₂/GJ, fossil fraction only.

---

## France

French energy taxation for district heating plants is governed by two main instruments. The primary instrument is the **accise sur les énergies**, a unified excise tax on energy products structured into fuel-specific fractions, codified since 2022 in the *Code des impositions sur les biens et services* (CIBS). The second instrument is the **TGAP Déchets**, a tax on waste reception and thermal treatment, still formally grounded in the *Code des douanes* but being progressively migrated to the CIBS.

The carbon component is embedded within the fuel excise rates and there is no separate standalone carbon tax at plant level outside the EU ETS.

### Accise sur les énergies (CIBS)

The accise sur les énergies is an excise tax levied on the consumption of energy products. It is structured into five fractions corresponding to fuel category: natural gas, electricity, petroleum products, coal and solid fuels, and overseas petroleum products. Each fraction carries its own tariff, exemptions, and reduced rates. The tariffs embed a carbon component (composante carbone) frozen at €44.60/tCO₂ since 2019.

#### Sources

1. [Code des impositions sur les biens et services (CIBS)](https://www.legifrance.gouv.fr/codes/texte_lc/LEGITEXT000044595989)
2. [Energy Taxation - Ministry of Ecological Transition](https://www.ecologie.gouv.fr/politiques-publiques/fiscalite-energies)
3. [2025 Guide on Energy Taxation - Ministry of Ecological Transition](https://www.ecologie.gouv.fr/sites/default/files/documents/Guide%202025%20sur%20la%20fiscalit%C3%A9%20des%20%C3%A9nergies.pdf)
4. [Energy Excise Duties](https://www.impots.gouv.fr/accises-sur-les-energies-consommateurs-denergie)
5. [Normal excise duty rates in 2025](https://www.impots.gouv.fr/actualite/consommation-denergie-tarifs-normaux-des-accises-en-2025)

#### Coverage

The accise is paid by the energy supplier upon delivery to the final consumer, and in practice passed through to the consumer on the invoice. For plants that self-supply (e.g. self-produced biogas not injected into the grid, or own electricity generation), the plant itself is the liable party. The tax applies to all fuels consumed as combustible or carburant on French territory. The relevant fractions for this model are:

- **Natural gas** (*accise sur les gaz naturels, ex-TICGN*): applies to natural gas consumed as combustible for heat production.
- **Biogas** (*accise sur les gaz naturels, ex-TICGN*): applies to biomethane injected to the natural gas grid; biogas not injected into the grid is subject to a zero rate (Art. L.312-86 CIBS).
- **Gasoil** (*accise sur les produits énergétiques, ex-TICPE*): applies to petroleum products consumed as combustible for heating.
- **Electricity** (*accise sur l'électricité, ex-TICFE/CSPE*): applies to electricity consumed as a final energy input.
- **Solid biomass** (*accise sur les charbons, Art. L.312-9 CIBS*): Wood chips, wood waste and other forms of waste biomass are not subject to excise tax; wood pellets are therefore assumed to be exempted as well.

#### Relationship to the EU ETS

The accise and the EU ETS are legally independent instruments and in principle both apply simultaneously. However, the embedded carbon component within these excise rates means that ETS-covered installations are effectively subject to a degree of double carbon pricing on their fuel inputs. France has not enacted a formal deduction or offset mechanism to entirely eliminate this overlap, but there are partial rebates for industries under ETS coverage (see next section).

#### Relevant exemptions

##### Cogeneration of electricity

> Natural gas (and by extension other fuels) consumed for the purpose of electricity production in a CHP unit is exempt from the excise tax to avoid double taxation between the combustible input and the electricity output (*Art. L.312-32 CIBS*). The exemption applies to the share of fuel attributable to electricity generation; the share attributable to heat production remains taxable. However, no specific allocation criteria has been found. **For the purpose of this analysis, it is assumed that all fuel for cogeneration is exempt**.

##### Reduced rates for electro-intensive industries

> Consumers may be classified as electro-intensive if they meet certain criteria (*Art. L.312-45-1 CIBS*). In this case, they qualify for a reduced excise rate on electricity (*Art. L.312-65 CIBS*), (*Art. L.312-71 CIBS*). **For the purpose of this analysis, it is assumed that electricity-consuming DH plants meet the electro-intensive criteria**.

##### Reduced rates for energy-intensive industries

> Large energy consumers covered by the EU ETS may benefit from reduced excise rates on coal and natural gas if they meet certain energy intensity thresholds (*Art. L.312-76 CIBS*). **For the purpose of this analysis, it is assumed all DH plants meet those criteria**.

<!-- ##### Reduced rates for energy-efficient industries

> A reduced rate on electricity applies to data centres that meet certain energy efficiency criteria. This rate applies to consumption above 1 GWh/year (*Art. L.312-65 CIBS*), (*Art. L.312-70 CIBS*). -->

#### Rates

Several rate levels applied throughout 2025, due to expiring transitional reduced rates and introduction of other bills.

##### Electricity

> - 20.50 €/MWh (January)
> - 0.50 €/MWh (Feb-Dec, rate for electro-intensive industries)

##### Natural gas

> - 17.16 €/MWh (Jan-Jul, non-ETS rate)
> - 15.43 €/MWh (Aug-Dec, non-ETS rate)
> - 1.52 €/MWh (Jan-Dec, ETS rate)

##### Gasoil

> - 15.62 €/MWh (Jan-Jul, domestic fuel rate)
> - 15.43 €/MWh (Aug-Dec, domestic fuel rate)

---

### TGAP Déchets (Taxe Générale sur les Activités Polluantes)

The TGAP Déchets is a tax on waste reception and thermal treatment, levied per tonne of waste received by an installation. It is designed to discourage landfilling and low-efficiency incineration, and to incentivise high-efficiency energy recovery. The tax applies to the operator of the waste treatment installation. It is currently grounded in *Art. 266 sexies of the Code des douanes* and administered by the DGFiP.

#### Sources

1. [Code des douanes - Article 266 sexies (Legal Basis)](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000051251616/2025-03-01)
2. [Code des douanes - Article 266 nonies (2025 TGAP Tax Rates)](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000048856821/2025-01-01)
3. [BOFiP - BOI-BAREME-000039 (Official Tax Table)](https://bofip.impots.gouv.fr/bofip/12765-PGP.html/identifiant%3DBOI-BAREME-000039-20241218)

#### Coverage

The operator of any installation receiving non-hazardous waste for incineration pays the TGAP on each tonne of waste received, regardless of whether the waste is received free of charge or at a gate fee.

#### Relationship to the EU ETS

There is no formal articulation between the The TGAP Déchets and the EU ETS. Waste-to-energy installations that fall within the EU ETS scope are subject to both simultaneously.

#### Relevant exemptions and rebates

- **High energy-recovery installations**: a reduced rate exists for installations achieving a high energy valorisation with an energy efficiency coefficient *≥ 0.65* (Art. 266 nonies Code des douanes, as amended by Loi de finances 2024, Art. 104). **For the purposes of this analysis, it is assumed that all waste incineration plants meet this criterion**.
- **High-calorific-value residues from high-performance sorting**: a separate reduced rate applies to such residues valorised in a thermal installation with energy efficiency *≥ 0.70*. **For the purposes of this analysis, this rebate is ignored**.
- All other previously existing reduced rates (e.g. for proximity to the waste source, certain sorting criteria) were abolished from 1 January 2025 by Arrêté du 23 octobre 2024.

#### Rates

> - 25 €/tonne (Standard rate)
> - 15 €/tonne (High energy-recovery installations)
> - 7.5 €/tonne (High-calorific-value residues from high-performance sorting)

---
