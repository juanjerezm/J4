import argparse
import sys
from pathlib import Path

import pandas as pd
import utilities_plotting as utils_plot

METRICS = ["NPV_all", "HeatProduction", "HeatRecoveryCapacity"]


def main(analysis: str) -> None:
    info = utils_plot.fetch_projects(analysis)
    projects = info["projects"]
    outdir = Path("results-consolidated") / info["name"]

    for metric in METRICS:
        paths = [outdir / project / f"table-{metric}.csv" for project in projects]

        merged_df = pd.DataFrame()
        for project, path in zip(projects, paths, strict=True):
            df = pd.read_csv(path)
            df.insert(0, "project", project)
            merged_df = pd.concat([merged_df, df], ignore_index=True)

        output_path = outdir / f"consolidated-table-{metric}.csv"
        merged_df.to_csv(output_path, index=False)
        print(f"-> File saved to {output_path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--analysis", required=True, help="Type of analysis")
    return parser.parse_args()


QUICKRUN_ARGS = {"analysis": "SAEP"}

if __name__ == "__main__":
    if len(sys.argv) == 1:
        main(**QUICKRUN_ARGS)
    else:
        args = parse_args()
        main(analysis=args.analysis)
