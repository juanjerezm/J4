import gams.transfer as gt
from pathlib import Path
import pandas as pd
import utilities as ut


def gdx_dfs(paths, variables=None, attributes=["level"]):
    """
    Reads GDX files from the given paths and returns a dictionary of pandas DataFrames.

    Args:
        paths (list): A list of file paths to the GDX files.
        variables (list, optional): A list of variable names to read from the GDX files. If None, all variables will be read.
        attributes (list, optional): A list of attribute names to include in the resulting DataFrames. Defaults to ['level'].

    Returns:
        dict: A dictionary where the keys are variable names and the values are pandas DataFrames containing the data.

    """
    gams_attrs = ["level", "marginal", "lower", "upper", "scale"]

    scenarios = [path.stem.split("_")[-1] for path in paths]

    # read gdx files into containers
    containers = [gt.Container(str(path)) for path in paths]

    data_all = dict()
    for scenario, container in zip(scenarios, containers):
        if variables is None:
            spec_var = container.listVariables()
        else:
            spec_var = variables
        
        for var in spec_var:
        
            df_temp = container[var].records
            df_temp.insert(0, "scenario", scenario)
            df_temp.drop(columns=[col for col in gams_attrs if col not in attributes],inplace=True)

            if var not in data_all:
                data_all[var] = pd.DataFrame()
            data_all[var] = pd.concat([data_all[var], df_temp])

    return data_all


# -------------------------------

portfolio = "test"
policy = "capital-subsidy"

# Create a Path object for the directory
directory = Path(f"results/{portfolio}/{policy}")

# Use the .glob() method to find all .gdx files starting with WH or DH
paths = list(directory.glob("output_*.gdx"))

data = gdx_dfs(paths)

print(data.keys())

print(data['NPV'])
print(data['Y_hr'])
print(data['OPX_WH_int'])
print(data['OPX_WH_ref'])
print(data['x_hr'])
print(data['x_e'])