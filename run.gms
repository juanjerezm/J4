* ======================================================================
* DESCRIPTION
* ======================================================================
* 
* Written by Juan Jerez, jujmo@dtu.dk, 2024.

* This script orchestrates several gams scripts, each corresponding to a specific step in the model run.
* It is designed to be run from the command line, allowing users to specify various flags that control the model behavior as detailed below.     
* The main steps of the model run are:
* - parameters.gms      : script that reads data files and populates the parameters used in the following steps. 
* - model_reference.gms : an optimization model representing a reference case without waste-heat recovery.
* - model_integrated.gms: an optimization model representing the integrated case with waste-heat recovery.
* - postprocessing.gms  : a script for post-processing and merging results from model_reference and model_integrated.

* It is possible to run this script from the GAMS GUI by defining the control flags in the "DEFAULTS" section below.

* ----- Scenario identifier flag (scenario) -----
* Unique run identifier.

* ----- Data override flag (override) -----
* Selects an override under data/overrides/ to replace default input data ('none' uses defaults only).

* ----- Solving mode flag (solve_mode) -----
* Selects how the model is solved
*  - 'static'       : solves the model once, using fixed WHR's full-load hours. Mainly used for testing.
*  - 'iterative'    : solves the model repeatedly, updating WHR's full-load hours between iterations.

* ----- Country flag (country) -----
* These flags select country-specific data and policy rules. Options are:
*  - 'DE'  : Germany.
*  - 'DK'  : Denmark.
*  - 'FR'  : France.

* --- Policy flag (policytype) ---
* Selects the specific policy regime applied to WHS costs, activating particular constraints in the model. Options are:
*  - 'socioeconomic'    : does not include taxes, tariffs or support schemes.
*  - 'taxation'         : applies common energy/carbon taxes and electricity tariffs.
*  - 'support'          : includes support schemes on top of taxation


* ======================================================================
*  OPTIONS
* ======================================================================
* ----- GAMS Options -----
$eolCom !!
$onEmpty                !! Allows empty sets or parameters
$Offlisting             !! Suppresses listing of input lines
$offSymList             !! Suppresses listing of symbol map
$offInclude             !! Suppresses listing of include-files 
option solprint = off   !! Toggles solution listing
option limRow = 0       !! Maximum number of rows listed in equation block
option limCol = 0       !! Maximum number of columns listed in one variable block
option optcr = 1e-4     !! Relative optimality tolerance
option EpsToZero = on   !! Outputs Eps values as zero
;


* ======================================================================
* LAUNCH METHOD DETECTION
* ======================================================================
* Determines how this script was launched based on whether control flags were provided as command-line arguments.

* manual_run='false'    : All flags provided, launched from Python pipeline or equivalent CLI call
* manual_run='true'     : No flags provided, launched from GAMS GUI or bare CLI "gams run.gms". FLAGS ARE SET TO DEFAULTS BELOW.
* Partial args          : Abort, provide all flags or none.



$ifi     set scenario $ifi     set override $ifi     set solve_mode $ifi     set country $ifi     set policytype $SetGlobal manual_run 'false'
$ifi not set scenario $ifi not set override $ifi not set solve_mode $ifi not set country $ifi not set policytype $SetGlobal manual_run 'true'
$ifi not set manual_run $abort "Partial arguments detected. Provide all flags or none."

$ifi "%manual_run%"=='true'  $log "Launch type: manual (GAMS GUI or bare CLI)"
$ifi "%manual_run%"=='false' $log "Launch type: automated (Python pipeline)"

* ======================================================================
*  DEFAULTS (GAMS GUI FALLBACK)
* ======================================================================
* Control flags can be set here if this script is launched manually.

* ----- Control flag definition -----
$ifi "%manual_run%"=='true' $SetGlobal scenario     'default'
$ifi "%manual_run%"=='true' $SetGlobal override     'none'
$ifi "%manual_run%"=='true' $SetGlobal solve_mode   'static'
$ifi "%manual_run%"=='true' $SetGlobal country      'DK'
$ifi "%manual_run%"=='true' $SetGlobal policytype   'taxation'


* ======================================================================
*  VALIDATION
* ======================================================================
* ----- Validation of control flags -----
$if "%country%"==DE     $goto validCountry
$if "%country%"==DK     $goto validCountry
$if "%country%"==FR     $goto validCountry
$abort "Invalid country."
$label validCountry

$if "%policytype%"==socioeconomic   $goto validPolicy
$if "%policytype%"==taxation        $goto validPolicy
$if "%policytype%"==support         $goto validPolicy
$abort "Invalid policytype."
$label validPolicy

$if "%solve_mode%"==static          $goto validMode
$if "%solve_mode%"==iterative       $goto validMode
$abort "Invalid solving mode."
$label validMode

* ----- Validation of overrides -----
* Ensure reserved override name 'none' is not used for an actual override directory.
$if     "%override%" == 'none' $if     DEXIST './data/overrides/none'       $abort "Override directory 'none' should not exist in ./data/overrides/"

* Ensure that if an override is specified, the corresponding directory exists. (This is a fallback for GAMS GUI users)
$if not "%override%" == 'none' $if NOT DEXIST './data/overrides/%override%' $abort "Override directory not found: ./data/overrides/%override%"

* ----- Listing of override contents -----
* If an override is specified, list its contents in the log for traceability.
$if not "%override%" == 'none' $log  "Override directory contents:"
$if not "%override%" == 'none' $ifi %system.filesys% == unix   $call 'ls -l "./data/overrides/%override%" | tee -a "./results/%scenario%/run.log"'
$if not "%override%" == 'none' $ifi %system.filesys% == msnt   $call   'dir ".\data\overrides\%override%" | tee -a ".\results\%scenario%\run.log"'


* ======================================================================
*  DIRECTORY SETUP
* ======================================================================
* ----- Directory setup -----
* Create output directories, only relevant if running from GAMS GUI.
$ifi %system.filesys% == msnt   $call 'mkdir    ".\results\%scenario%\gdx"';  !! Windows
$ifi %system.filesys% == unix   $call 'mkdir -p "./results/%scenario%/gdx"';  !! Unix

$ifi %system.filesys% == msnt   $call 'mkdir    ".\results\%scenario%\csv"';  !! Windows
$ifi %system.filesys% == unix   $call 'mkdir -p "./results/%scenario%/csv"';  !! Unix


* ======================================================================
*  MODEL EXECUTION
* ======================================================================
* Run each stage in sequence, each script depends on outputs from previous stages.

* ----- parameter script (parameters.gms) -----
$call gams ./scripts/gams/parameters.gms    --scenario="%scenario%" --override="%override%" --country="%country%" --policytype="%policytype%"   o=./results/"%scenario%"/parameters.lst
$eval error_parameters errorLevel
$if not %error_parameters%==0               $abort "parameters.gms did not execute successfully. Errorlevel: %error_parameters%"

* ----- Case without WHR (model_reference.gms) -----
$call gams ./scripts/gams/model_reference   --scenario="%scenario%" --override="%override%" --country="%country%" --policytype="%policytype%"   o=./results/"%scenario%"/model_reference.lst
$eval error_reference errorLevel
$if not %error_reference%==0                $abort "model_reference.gms did not execute successfully. Errorlevel: %error_reference%"

* ----- Case with possible WHR (model_integrated.gms) -----
$call gams ./scripts/gams/model_integrated  --scenario="%scenario%" --override="%override%" --country="%country%" --policytype="%policytype%" --solve_mode="%solve_mode%" o=./results/"%scenario%"/model_integrated.lst  
$eval error_integrated errorLevel
$if not %error_integrated%==0               $abort "model_integrated.gms did not execute successfully. Errorlevel: %error_integrated%"

* ----- post-processing script (postprocessing.gms) -----
$call gams ./scripts/gams/postprocessing    --scenario="%scenario%" --override="%override%" --country="%country%" --policytype="%policytype%"   o=./results/"%scenario%"/post_processing.lst
$eval error_postprocessing errorLevel
$if not %error_postprocessing%==0           $abort "post_processing.gms did not execute successfully. Errorlevel: %error_postprocessing%"

* ======================================================================
* CSV EXPORT (MANUAL RUN ONLY)
* ======================================================================
* GDX to CSV export is handled here for manual runs. For automated runs, the Python pipeline handles exports.
$ifi "%manual_run%"=='true' $include "./scripts/gams/csv_export.inc"  !! If running manually, print results to log for quick inspection.
