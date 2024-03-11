#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jan 14 15:16:04 2024

@author: julianmittag
"""

#%% Importing Libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

#%%
# Change working directory if run as interactive script
os.chdir(r'C:\Users\jujmo\Github\J4')


#%% 
# --> Read and process danish DH production data

filename = "data/_master-data/district-heating-data_2019-2021_125-method.xlsx"
raw_data = pd.read_excel(filename, sheet_name ="125pct metode", header = 1)

#dropping all rows that are not from 2020 and with "0" values (contains the units)
raw_data = raw_data[raw_data.År.isin([2019,2021])==False]
raw_data = raw_data.drop(0)

# Keeping only names and heat delivery, further cleaning
data_DH = raw_data[['Unnamed: 0', 'Varme_Lev_til_net']]
data_DH = data_DH.rename(columns = {'Unnamed: 0':'Name', 'Varme_Lev_til_net':'Heat delivery'})
data_DH['Heat delivery'] = data_DH['Heat delivery'].astype(float)
data_DH = data_DH[data_DH['Heat delivery'] > 0]


#%% 
# --> Define thresholds for network size classification
threshold_small =  0.5e6
threshold_medium = 5.0e6

#%%
# --> Describe national production data
print(data_DH.head(10))

print(data_DH.describe())

mean    = data_DH['Heat delivery'].mean()
median  = data_DH['Heat delivery'].median()
std     = data_DH['Heat delivery'].std()

data_DH.hist(column='Heat delivery', bins=35*5)
plt.ylim(0, 50) # make easier to see small values
plt.axvline(x=threshold_small, color='r', linestyle='-')
plt.axvline(x=threshold_medium, color='r', linestyle='-')

#%%
# --> Classify by network size and get scaling factor

data_DH["Network size"] = data_DH["Heat delivery"].apply(lambda x: "small" if x <= threshold_small else "medium" if x <= threshold_medium else "large")

mean = data_DH[data_DH['Network size'].isin(['large', 'medium'])]['Heat delivery'].mean()
scaling_factor = mean / data_DH['Heat delivery'].max()

print(f"Scaling factor: {scaling_factor:.2f}")
print(f"Mean heat delivery for large and medium networks: {mean:.2e}")

#%%
# --> Scaling CPH's heat demand data
filename = "data/_master-data/ts-demand-heat-copenhagen.csv"
heat_consumption = pd.read_csv(filename, names=['timesteps', 'heat demand'])

# scale by the scaling factor
heat_consumption['heat demand'] = heat_consumption['heat demand'] * scaling_factor
print(heat_consumption.head(10))

#%%
# --> Save data to file
heat_consumption.to_csv("data/_master-data/ts-demand-heat-copenhagen-scaled.csv", header=False, index=False)

# %%
# --> Size of DCs


WH_capacity = [1, 2, 3, 4, 5, 10, 15]
WHR_eff = 3.6
share_WH = [cap * 8760 / sum(heat_consumption['heat demand']) * 100 for cap in WH_capacity]
share_WHR = [share * WHR_eff for share in share_WH]
# print capacity, share WH and share_WHR element by element like table

for i in range(len(WH_capacity)):
    print(f'Capacity: {WH_capacity[i]} MW, Share: {share_WH[i]:.2f} %, Share WHR: {share_WHR[i]:.2f} %')