import utilities as ut
import pandas as pd


paths = [
    'results/test_run/results-testrun_integrated.gdx',
    'results/test_run/results-testrun_reference.gdx'
]

data = ut.gdxs_dfs(paths)
print(data.keys())

# for each key in dictionary, save its df in a csv file
for key in data.keys():
    data[key].to_csv(f"results/test_run/csv/{key}.csv", index=False)
    print(f"Saved {key}.csv")
