# Metadata for known dimensions used across relabeling, categoricals, and plotting.
DIMENSION_CONFIG = {
    "COUNTRY": {
        "mapping": "countries",
        "categorical": True,
        "legend_title": "Country",
    },
    "POLICY": {
        "mapping": "policies",
        "categorical": True,
        "legend_title": "Policy Scenario",
    },
    "F": {
        "mapping": "fuels",
        "categorical": False,
        "legend_title": "Fuel Category",
    },
    "E": {
        "mapping": "entities",
        "categorical": True,
        "legend_title": "Entity",
    },
    "OVERRIDE": {
        "mapping": "overrides",
        "categorical": True,
        "legend_title": "Sensitivity",
    },
}


def get_legend_title(series_col: str) -> str:
    """
    Get legend title from DIMENSION_CONFIG, if `series_col` is defined and
    has a `legend_title` field. Otherwise, return `series_col` as default.
    """
    return DIMENSION_CONFIG.get(series_col, {}).get("legend_title", series_col.title())
