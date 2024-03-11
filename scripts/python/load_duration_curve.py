#%%
# --> Import libraries and set working directory
import pandas as pd
import matplotlib.pyplot as plt
import os

os.chdir(r'C:\Users\jujmo\Github\J4')


#%%
# --> Load and inspect data
filename = "data/common/ts-demand-heat.csv"
dataset = pd.read_csv(filename, names=['timesteps', 'heat demand'])
max_demand = dataset['heat demand'].max()
dataset.describe()


#%%
# --> Define quantiles for load transition
load_duration_curve = dataset['heat demand'].sort_values(ascending=False).reset_index(drop=True)

quantiles = [0.33, 0.66]
quantile_values = load_duration_curve.quantile(quantiles)
quantile_values



#%% 
# --> Visualize heat demand temporally
dataset.plot(title='Heat consumption in 2020', linewidth=0.3)
plt.xlim(dataset.index.min(), dataset.index.max())


# %%
# --> Visualize load duration curve
load_duration_curve.plot(title='Load duration curve')
for quantile in quantile_values:
    plt.axhline(y=quantile, color='r', linestyle='-')
plt.show()


load_duration_curve_diff = abs(load_duration_curve.diff().rolling(72).mean())
load_duration_curve_diff.plot(title='Load duration curve derivative')
yrange = [0, 0.2]
plt.ylim(yrange)

for quantile in quantiles:
    plt.axvline(x=8760-round(quantile*8760), color='r', linestyle='-')

#%% 
# --> Visualize heat distribution along quantiles
plt.hist(dataset[['heat demand']], bins=100, range=(0, max_demand))
for quantile in quantile_values:
    plt.axvline(x=quantile, color='r', linestyle='-')
plt.title('Cummulative distribution with quantiles')
plt.show()

plt.hist(dataset[['heat demand']], bins=100, cumulative=True, density=1, range=(0, max_demand))
for quantile in quantile_values:
    plt.axvline(x=quantile, color='r', linestyle='-')
plt.title('Cummulative distribution with quantiles')
plt.show()




#%%
# --> Visualize demand temporally with quantiles
load_category_values = [0] + list(quantile_values) + [dataset['heat demand'].max()]
load_category_ranges = [load_category_values[i+1] - load_category_values[i] for i in range(len(load_category_values)-1)]

df = pd.DataFrame()
df['RemainingConsumption'] = dataset['heat demand']

for i, load_category_range in enumerate(load_category_ranges):
    df[f'LoadCategory {i}'] = df['RemainingConsumption'].apply(lambda x: min(x, load_category_range))
    df['RemainingConsumption'] = df['RemainingConsumption'] - df[f'LoadCategory {i}']

df = df.drop(columns=['RemainingConsumption'])

#make an area plot of df
df.plot.area(title='Load categories in 2020', linewidth=0)

#%%
# --> Summary
print('Quantiles:')
print(quantile_values)
print('----------------------------------------')
print('Load category ranges:')
print(load_category_values)
print('----------------------------------------')
print('Load category capacity:')
print(load_category_ranges)
print('----------------------------------------')
print('Share of capacity in each load category:')
share_of_capacity = [load_category_range / sum(load_category_ranges) for load_category_range in load_category_ranges]
share_of_capacity = [round(share, 3) for share in share_of_capacity]
print(share_of_capacity)
print('----------------------------------------')
print('Share of total consumption in each load category:')
print(df.sum() / df.sum().sum())

