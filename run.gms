* ======================================================================
* DESCRIPTION:
* ======================================================================
* 
* Written by Juan Jerez, jujmo@dtu.dk, 2024.

* This script sets up flags, directories, and filenames for the model runs. 
* It executes an entire model run:
* - the parameter script that reads data and populates the parameters, 
* - the reference case optimisation,
* - the integrated case optimisation,
* - and the post-processing script.


* ----- NOTES / TODO -----


* ======================================================================
*  OPTIONS:
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
*  CONTROL FLAGS:
* ======================================================================
* ----- Identifier flags -----
* Used to set directories and filenames, results will be overwritten if these flags are not unique. 
* DO NOT use spaces or hyphens (-)
* - project: a collection of related scenarios
* - scenario: the name of a specific run

$ifi not setglobal project  $SetGlobal project  'default_prj'
$ifi not setglobal scenario $SetGlobal scenario 'default_scn'


* --- Policy flag ---
* These flags activate specific parameters, constraints and equation terms in the model.
*  - 'socioeconomic' does not include taxes, tariffs or support schemes for the waste-heat source
*  - 'taxation'      includes energy/carbon taxes and electricity tariffs,
*  - 'support'       includes support schemes on top of taxation

* If running directly from GAMS UI (without specifying parameters), the default is as uncommented below

* $ifi not setglobal policytype $SetGlobal policytype 'socioeconomic'
$ifi not setglobal policytype $SetGlobal policytype 'taxation'
* $ifi not setglobal policytype $SetGlobal policytype 'support'


* ----- Country flag -----
* These flags select country-specific parameters and policies

* If running directly from GAMS UI (without specifying parameters), the default is as uncommented below
* $ifi not setglobal country  $SetGlobal country  'DE'
$ifi not setglobal country  $SetGlobal country  'DK'
* $ifi not setglobal country  $SetGlobal country  'FR'


* --- Solving flag ---
* Sets how the model is solved
*   - 'single'      solves the model once, using assumed full-load hours
*   - 'iterative'   solves the model iteratively, updating full-load hours

* If running directly from GAMS UI (without specifying parameters), the default is as uncommented below
$ifi not setglobal mode     $SetGlobal mode 'single'         !! Choose between 'single' and 'iterative'
* $ifi not setglobal mode     $SetGlobal mode 'iterative'         !! Choose between 'single' and 'iterative'


* ======================================================================
*  Directories and Filenames:
* ======================================================================
* ----- Directories, filenames, and scripts -----
* Create directories for output
$ifi %system.filesys% == msnt   $call 'mkdir    .\results\%project%\%scenario%\';   !! Windows
$ifi %system.filesys% == unix   $call 'mkdir -p ./results/%project%/%scenario%/';   !! Unix


* ======================================================================
*  Run the model:
* ======================================================================
* Specific parts of the model can be run by calling the corresponding script.
* Each script requires all previous scripts to be executed.

* parameter script
$call gams ./scripts/gams/parameters.gms        --project=%project% --scenario=%scenario% --policytype=%policytype% --country=%country% o=./results/%project%/%scenario%/parameters.lst
$eval error_parameters errorLevel
$if not %error_parameters%==0               $abort "parameters.gms did not execute successfully. Errorlevel: %error_parameters%"

* reference case
$call gams ./scripts/gams/model_reference   --project=%project% --scenario=%scenario% --policytype=%policytype% --country=%country% o=./results/%project%/%scenario%/model_reference.lst  
$eval error_reference errorLevel
$if not %error_reference%==0                $abort "model_reference.gms did not execute successfully. Errorlevel: %error_reference%"

* integrated case
$call gams ./scripts/gams/model             --project=%project% --scenario=%scenario% --policytype=%policytype% --country=%country% --mode=%mode% o=./results/%project%/%scenario%/model_integrated.lst  
$eval error_integrated errorLevel
$if not %error_integrated%==0               $abort "model.gms did not execute successfully. Errorlevel: %error_integrated%"

* post-processing
$call gams ./scripts/gams/postprocessing   --project=%project% --scenario=%scenario% --policytype=%policytype% --country=%country% o=./results/%project%/%scenario%/post_processing.lst
$eval error_postprocessing errorLevel
$if not %error_postprocessing%==0           $abort "post_processing.gms did not execute successfully. Errorlevel: %error_postprocessing%"
