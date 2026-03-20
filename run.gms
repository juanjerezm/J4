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
* - model.gms           : an optimization model representing the integrated case with waste-heat recovery.
* - postprocessing.gms  : a script for post-processing and merging results from model_reference and model_integrated.


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
* # TODO: check GAMS output contents what to keep what to suppress, and adjust these options accordingly.
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
*  DEFAULTS (GAMS GUI FALLBACK)
* ======================================================================
* When run from GAMS GUI, parameters are not passed via command line. In such case, control flags are defined here.

* ----- Control flag definition -----
$ifi not setglobal scenario     $SetGlobal scenario     'default_scn'
$ifi not setglobal override     $SetGlobal override     'none'
$ifi not setglobal solve_mode   $SetGlobal solve_mode   'iterative'
$ifi not setglobal country      $SetGlobal country      'DK'
$ifi not setglobal policytype   $SetGlobal policytype   'taxation'


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

* ----- Case with possible WHR (model.gms) -----
$call gams ./scripts/gams/model             --scenario="%scenario%" --override="%override%" --country="%country%" --policytype="%policytype%" --solve_mode="%solve_mode%" o=./results/"%scenario%"/model_integrated.lst  
$eval error_integrated errorLevel
$if not %error_integrated%==0               $abort "model.gms did not execute successfully. Errorlevel: %error_integrated%"

* ----- post-processing script (postprocessing.gms) -----
$call gams ./scripts/gams/postprocessing    --scenario="%scenario%" --override="%override%" --country="%country%" --policytype="%policytype%"   o=./results/"%scenario%"/post_processing.lst
$eval error_postprocessing errorLevel
$if not %error_postprocessing%==0           $abort "post_processing.gms did not execute successfully. Errorlevel: %error_postprocessing%"
