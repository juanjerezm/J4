from pathlib import Path
from typing import Dict

import pandas as pd
import utilities as utils
from utilities import Scenario

cfg = {
    "base_path": Path.cwd()
}

def export_to_csv(scenario: Scenario, data: Dict[str, pd.DataFrame]) -> None:
    csv_dir = scenario.outdir / "csv"
    csv_dir.mkdir(parents=True, exist_ok=True)
    for key in data.keys():
        data[key].to_csv(csv_dir / f"{key}.csv", index=False)
        print(f"--> Saved {key}.csv")
    pass


def main(file):
    scenarios = utils.read_scenarios(file)
    utils.print_line()
    for scenario in scenarios:
        print(f"Processing scenario: {scenario.name}")
        gdx_path = scenario.outdir / f"results-{scenario.name}-postprocessing.gdx"
        results = utils.gdxdf_postprocess(gdx_path)
        export_to_csv(scenario, results)

if __name__ == "__main__":
    PROJECT = "MAIN"
    scenario_parameters = f'data/{PROJECT}/scenario_parameters.csv'
    main(scenario_parameters)
