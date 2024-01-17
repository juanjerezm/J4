#%%
import pandas as pd
import matplotlib.pyplot as plt
import os

#%%
# Change working directory if run as interactive script
os.chdir(r'C:\Users\jujmo\Github\J4')

#%%
# Load data
file_path = 'data/_master-data/heat_consumption_2019-2021.csv'
heat_consumption_data = pd.read_csv(file_path)

#%%
# Prepare data
dataset = heat_consumption_data.copy()
dataset['HourUTC'] = pd.to_datetime(dataset['HourUTC'], dayfirst=True)
dataset.set_index('HourUTC', inplace=True)
dataset['TotalConsumption'] = dataset['TotalConsCTR'] + dataset['TotalConsVEKS']
dataset = dataset[['TotalConsumption']]
dataset = dataset.loc['2020']
# filtered_data = filtered_data[~((filtered_data.index.month == 2) & (filtered_data.index.day == 29))]
dataset = dataset.dropna()

#%%
# Inspect data
dataset.describe()

#%% 
# Explore data visually
dataset.plot(title='Heat consumption in 2020')
dataset.hist(column=['TotalConsumption'], bins=100)
dataset.hist(column=['TotalConsumption'], cumulative=True, density=1, bins=100)

#%% 
# Load duration curve
load_duration_curve = dataset['TotalConsumption'].sort_values(ascending=False).reset_index(drop=True)
load_duration_curve.plot(title='Load duration curve')

#%% 
# Define quantiles
quantiles = [0.71, 0.91]
quantile_values = load_duration_curve.quantile(quantiles)
quantile_values

#%% 
# Plot load distribution with quantile separation
plt.hist(dataset[['TotalConsumption']], bins=100, cumulative=True, density=1)
for quantile in quantile_values:
    plt.axvline(x=quantile, color='r', linestyle='-')
plt.title('Cummulative distribution with quantiles')
plt.show()

load_duration_curve.plot(title='Load duration curve')
for quantile in quantile_values:
    plt.axhline(y=quantile, color='r', linestyle='-')
plt.show()

# %%
# calculate the derivative of the load duration curve with a moving average filter of 24 hours
load_duration_curve_diff = abs(load_duration_curve.diff().rolling(24).mean())
load_duration_curve_diff.plot(title='Load duration curve derivative')
yrange = [0, 1]
plt.ylim(yrange)

for quantile in quantiles:
    plt.axvline(x=round(quantile*8760), color='r', linestyle='-')


#%%
# Calculate the quantile ranges
load_category_values = [0] + list(quantile_values) + [dataset['TotalConsumption'].max()]
load_category_ranges = [load_category_values[i+1] - load_category_values[i] for i in range(len(load_category_values)-1)]

df = pd.DataFrame()
df['RemainingConsumption'] = dataset['TotalConsumption']

for i, load_category_ranges in enumerate(load_category_ranges):
    df[f'LoadCategory {i}'] = df['RemainingConsumption'].apply(lambda x: min(x, load_category_ranges))
    df['RemainingConsumption'] = df['RemainingConsumption'] - df[f'LoadCategory {i}']

df = df.drop(columns=['RemainingConsumption'])

#make an area plot of df
df.plot.area(title='Load categories in 2020', linewidth=0)

#%%
# Summary
print('Quantiles:')
print(quantile_values)
print('----------------------------------------')
print('Load category ranges:')
print(load_category_values)
print('----------------------------------------')
print('Share of total consumption in each load category:')
df.sum() / df.sum().sum()

# %%
