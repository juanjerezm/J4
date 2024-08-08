from typing import Dict

COUNTRIES = {"DK": "Denmark", "DE": "Germany", "FR": "France"}
POLICIES: Dict[str, str] = {"socioeconomic": "Technical", "taxation": "Taxation", "support": "Support"}

# muted palette
# fuels_data = [
#     {
#         "fuel": "electricity",
#         "plot_name": "Electricity",
#         "color": "#88CCEE",
#         "color_name": "cyan",
#     },
#     {
#         "fuel": "wood chips",
#         "plot_name": "Biomass",
#         "color": "#117733",
#         "color_name": "green",
#     },
#     {
#         "fuel": "wood pellets",
#         "plot_name": "Biomass",
#         "color": "#117733",
#         "color_name": "green",
#     },
#     {
#         "fuel": "wood waste",
#         "plot_name": "Biomass",
#         "color": "#117733",
#         "color_name": "green",
#     },
#     {
#         "fuel": "coal", 
#         "plot_name": "Coal", 
#         "color": "#332288", 
#         "color_name": "indigo",
#         },
#     {
#         "fuel": "municipal waste",
#         "plot_name": "Mun. waste",
#         "color": "#DDCC77",
#         "color_name": "sand",
#     },
#     {
#         "fuel": "natural gas",
#         "plot_name": "Natural gas",
#         "color": "#EE8866",
#         "color_name": "rose",
#     },
#     {
#         "fuel": "fuel oil",
#         "plot_name": "Oil products",
#         "color": "#882255",
#         "color_name": "wine",
#     },
#     {
#         "fuel": "gas oil",
#         "plot_name": "Oil products",
#         "color": "#882255",
#         "color_name": "wine",
#     },
#     {
#         "fuel": "biogas",
#         "plot_name": "Other",
#         "color": "#C7C7C7",
#         "color_name": "grey",
#     },
#     {
#         "fuel": "excess heat",
#         "plot_name": "Other",
#         "color": "#C7C7C7",
#         "color_name": "grey",
#     },
# ]

# pale palette
fuels_data = [
    {
        "fuel": "electricity",
        "plot_name": "Electricity",
        "color": "#EEDD88",
        "color_name": "light yellow",
    },
    {
        "fuel": "wood chips",
        "plot_name": "Biomass",
        "color": "#44BB99",
        "color_name": "mint",
    },
    {
        "fuel": "wood pellets",
        "plot_name": "Biomass",
        "color": "#44BB99",
        "color_name": "mint",
    },
    {
        "fuel": "wood waste",
        "plot_name": "Biomass",
        "color": "#44BB99",
        "color_name": "mint",
    },
    {
        "fuel": "coal", 
        "plot_name": "Coal", 
        "color": "#77AADD", 
        "color_name": "indigo",
        },
    {
        "fuel": "municipal waste",
        "plot_name": "Mun. waste",
        "color": "#99DDFF",
        "color_name": "light cyan",
    },
    {
        "fuel": "natural gas",
        "plot_name": "Natural gas",
        "color": "#FFAABB",
        "color_name": "pink",
    },
    {
        "fuel": "fuel oil",
        "plot_name": "Oil products",
        "color": "#EE8866",
        "color_name": "wine",
    },
    {
        "fuel": "gas oil",
        "plot_name": "Oil products",
        "color": "#EE8866",
        "color_name": "wine",
    },
    {
        "fuel": "biogas",
        "plot_name": "Other",
        "color": "#C7C7C7",
        "color_name": "grey",
    },
    {
        "fuel": "excess heat",
        "plot_name": "Other",
        "color": "#C7C7C7",
        "color_name": "grey",
    },
]

FUEL_NAMES = {item['fuel']: item['plot_name'] for item in fuels_data}
FUEL_COLORS = {item['plot_name']: item['color'] for item in fuels_data} # uses plot_name as key
