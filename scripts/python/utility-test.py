import utilities as ut
import pandas as pd
from pathlib import Path

paths = [
    'results/testeo/results-testeo-integrated.gdx',
    'results/testeo/results-testeo-reference.gdx'
]

# get variables from "testeo" run out of gdx files
data = ut.gdxdf_var(paths)

# save each variable to a csv file
Path("results/testeo/csv").mkdir(parents=True, exist_ok=True)
for key in data.keys():
    data[key].to_csv(f"results/testeo/csv/{key}.csv", index=False)
    print(f"Saved {key}.csv")

# let's work with the "x_h" variable
df = data['x_h']

# Observe the df
print(df.head(10))

# rename some columns. The new names need to be used in the rest of the script
rename_columns = {'G': 'generator', 'level': 'value'}
df = ut.rename_columns(df, rename_columns)

# rename some values. The new values need to be used in the rest of the script
rename_values = {'generator': {'AMV1': 'Amagerværket1', 'AVV1': 'Avedøreværket1'}, 'scenario': {'reference': 'baseline'}}
df = ut.rename_values(df, rename_values)

# exclude generator 'AVV2' from the dataframe
exclude = {'generator': ['AVV2']}
df = ut.filter(df, exclude=exclude)

# aggregate 'value' column by scenario and generator
df = ut.aggregate(df, ['scenario', 'generator'], ['value'])

# calculate the difference in the 'value' column with respect to 'baseline' in the 'scenario' column 
df = ut.diff(df, 'scenario', 'baseline', 'value')

# Observe the condensed df
print(df.head(10))

# Let's get some parameters from the gdx files
pars = ut.gdxdf_par(paths, ['beta_b', 'beta_v'])

print(pars['beta_b'].head(10))
print(pars['beta_v'].head(10))
