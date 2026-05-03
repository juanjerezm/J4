* ======================================================================
* CSV EXPORT (MANUAL RUN ONLY)
* ======================================================================
* These commands must be kept in sync with the symbols exported to results-postprocessing.gdx
* ----- Economic indicators -----
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=NPV_all         output="./results/%scenario%/csv/NPV_all.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=NPV             output="./results/%scenario%/csv/NPV.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=CAPEX           output="./results/%scenario%/csv/CAPEX.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=OPEX            output="./results/%scenario%/csv/OPEX.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=OPEX_savings    output="./results/%scenario%/csv/OPEX_savings.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=HeatTransaction  output="./results/%scenario%/csv/HeatTransaction.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=IRR             output="./results/%scenario%/csv/IRR.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=PBT             output="./results/%scenario%/csv/PBT.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=FLH             output="./results/%scenario%/csv/FLH.csv"

* ----- Prices -----
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=WasteHeatPrice  output="./results/%scenario%/csv/WasteHeatPrice.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=AskPrice        output="./results/%scenario%/csv/AskPrice.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=BidPrice        output="./results/%scenario%/csv/BidPrice.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=AskMarginal     output="./results/%scenario%/csv/AskMarginal.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=BidMarginal     output="./results/%scenario%/csv/BidMarginal.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=AskFixed        output="./results/%scenario%/csv/AskFixed.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=BidFixed        output="./results/%scenario%/csv/BidFixed.csv"

* ----- Physical flows -----
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=FuelConsumption         output="./results/%scenario%/csv/FuelConsumption.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=HeatProduction          output="./results/%scenario%/csv/HeatProduction.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=ColdProduction          output="./results/%scenario%/csv/ColdProduction.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=ElectricityProduction   output="./results/%scenario%/csv/ElectricityProduction.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=StorageFlow             output="./results/%scenario%/csv/StorageFlow.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=StorageLevel            output="./results/%scenario%/csv/StorageLevel.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=CarbonEmissions         output="./results/%scenario%/csv/CarbonEmissions.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=HeatRecoveryCapacity    output="./results/%scenario%/csv/HeatRecoveryCapacity.csv"

* ----- Policy -----
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=Tariffs   output="./results/%scenario%/csv/Tariffs.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=Taxes     output="./results/%scenario%/csv/Taxes.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=ETSQuota  output="./results/%scenario%/csv/ETSQuota.csv"
$call gdxdump "./results/%scenario%/gdx/results-postprocessing.gdx" format=csv symb=Support   output="./results/%scenario%/csv/Support.csv"
