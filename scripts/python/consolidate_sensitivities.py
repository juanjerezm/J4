
from pathlib import Path
import pandas as pd

METRICS = ['NPV_all', 'HeatProduction', 'HeatRecoveryCapacity']

def main(projects, outdir):
    for metric in METRICS:
        paths = [outdir / project / f"table-{metric}.csv" for project in projects]

        merged_df = pd.DataFrame()
        for project, path in zip(projects, paths):
            df = pd.read_csv(path)
            df.insert(0, 'project', project)
            merged_df = pd.concat([merged_df, df], ignore_index=True)

        output_path = outdir / f"consolidated-table-{metric}.csv"
        merged_df.to_csv(output_path, index=False)
        print(f"-> File saved to {output_path}")
        

if __name__ == "__main__":
    SENSITIVITY = "discount rate"
    # SENSITIVITY = "electricity prices"

    OUTDIR = Path.home() / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article/consolidated results"

    if SENSITIVITY == "discount rate":
        projects = ["SADR00", "SADR02", "SADR04", "SADR06", "SADR08", "SADR10", "SADR12"]
        outdir = OUTDIR / "SADR"

    if SENSITIVITY == "electricity prices":
        projects = ["SAEP_low", "SAEP_base", "SAEP_high"]
        outdir = OUTDIR / "SAEP"

    main(projects, outdir)
