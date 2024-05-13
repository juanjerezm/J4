#%%
# --> Import libraries and set working directory
import pandas as pd
import matplotlib.pyplot as plt
import os

os.chdir(r'C:\Users\jujmo\Github\J4')


#%%
# ---> Setup of general parameters
quantiles = [0.32, 0.68]
save = True
dpi = 150

colors = ['r', 'g', 'b', 'y', 'm', 'c', 'k']
color_map = {quantile: colors[i] for i, quantile in enumerate(quantiles)}


#%%
# --> Load and inspect data
filename = "data/common/ts-demand-heat.csv"
dataset = pd.read_csv(filename, names=['timesteps', 'heat demand'])
max_demand = dataset['heat demand'].max()
dataset.describe()


#%%
# --> Calculate quantiles for load transition
load_duration_curve = dataset['heat demand'].sort_values(ascending=False).reset_index(drop=True)
quantile_capacity = load_duration_curve.quantile(quantiles)
quantile_capacity



#%% 
# --> Visualize heat demand temporally
dataset['heat demand'].plot(title='Heat consumption in 2020', linewidth=0.3, color='grey', legend=True, label = 'hourly')
dataset['heat demand'].rolling(72).mean().plot(linewidth=1.2, color='r', legend=True, label='3-day mean')
plt.xticks(range(0, 8760+1, 730), [])
plt.xlim(dataset.index.min(), dataset.index.max())
plt.ylim(0, max_demand)
plt.grid(axis='x', linestyle='--', linewidth=0.3)
plt.xlabel('Time')
plt.ylabel('Heat load MW')
if save:
    plt.savefig('notes/source_files/DH-load-temporal.png', dpi=dpi)
plt.show()



# %%
# --> Visualize load duration curve
# ----- Load duration curve -----
load_duration_curve.plot(title='Load duration curve')
for quantile, capacity in quantile_capacity.items():
    plt.axhline(y=capacity, color=color_map[quantile], linestyle='-')

# add legends to the axhline
# create legends from color and handel
legend = [plt.Line2D([0], [0], color=color, lw=2) for color in color_map.values()]
plt.legend(legend, quantile_capacity.keys(), title='Quantiles')
plt.xlim(0, 8760)
plt.ylim(0, load_duration_curve.max())
if save:
    plt.savefig('notes/source_files/DH-load-duration-curve.png', dpi=dpi)
plt.show()

# ----- Load duration curve derivative -----
load_duration_curve_diff = abs(load_duration_curve.diff().rolling(72).mean())
load_duration_curve_diff.plot(title='Load duration curve 1st derivative', linewidth=0.3)
yrange = [0, 0.2]
plt.ylim(yrange)

for quantile in quantiles:
    plt.axvline(x=8760-round(quantile*8760), color=color_map[quantile], linestyle='-')
plt.xlim(0, 8760)
plt.legend(legend, quantile_capacity.keys(), title='Quantiles')
plt.show()

# ----- Load duration curve derivative -----
load_duration_curve_diff_2 = abs(load_duration_curve_diff.diff().rolling(72*2).mean())
load_duration_curve_diff_2.plot(title='Load duration curve 2nd derivative', linewidth=0.3)
yrange = [0, 0.0003]
plt.ylim(yrange)

for quantile in quantiles:
    plt.axvline(x=8760-round(quantile*8760), color=color_map[quantile], linestyle='-')
plt.xlim(0, 8760)
plt.legend(legend, quantile_capacity.keys(), title='Quantiles')
plt.show()

#%% 
# --> Visualize heat distribution along quantiles
plt.hist(dataset[['heat demand']], bins=100, range=(0, max_demand))
for quantile, capacity in quantile_capacity.items():
    plt.axvline(x=capacity, color=color_map[quantile], linestyle='-')

plt.title('Heat load histogram')
plt.xlabel('Heat load MW')
plt.ylabel('Counts of hours')
plt.xlim(0, load_duration_curve.max())
plt.legend(legend, quantile_capacity.keys(), title='Quantiles')
plt.show()

plt.hist(dataset[['heat demand']], bins=100, cumulative=True, density=1, range=(0, max_demand))
for quantile, capacity in quantile_capacity.items():
    plt.axvline(x=capacity, color=color_map[quantile], linestyle='-')

plt.title('Cummulative distribution with quantiles')
plt.xlabel('Heat load MW')
plt.ylabel('Cummulative probability')
plt.xlim(0, load_duration_curve.max())
plt.legend(legend, quantile_capacity.keys(), title='Quantiles')
plt.show()


#%%
# --> Visualize demand temporally with quantiles
load_category_values = [0] + list(quantile_capacity) + [dataset['heat demand'].max()]
load_category_ranges = [load_category_values[i+1] - load_category_values[i] for i in range(len(load_category_values)-1)]

df = pd.DataFrame()
df['RemainingConsumption'] = dataset['heat demand']

for i, load_category_range in enumerate(load_category_ranges):
    df[f'LoadCategory {i}'] = df['RemainingConsumption'].apply(lambda x: min(x, load_category_range))
    df['RemainingConsumption'] = df['RemainingConsumption'] - df[f'LoadCategory {i}']

df = df.drop(columns=['RemainingConsumption'])

#make an area plot of df
df.plot.area(title='Load categories in 2020', linewidth=0)
plt.xlim(0, 8760)
if save:
    plt.savefig('notes/source_files/DH-load-categories', dpi=dpi)
plt.show()


#%%
# --> Summary
print('Quantiles:')
print(quantile_capacity)
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


# %%
