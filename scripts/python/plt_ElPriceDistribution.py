from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

import utilities_plotting as utils_plot

# ----- Matplotlib settings -----
plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = 8



# File paths
file_paths = [
    "data/SAEP2018/ts-electricity-price.csv",
    "data/SAEP2019/ts-electricity-price.csv",
    "data/SAEP2020/ts-electricity-price.csv",
    "data/SAEP2021/ts-electricity-price.csv",
    "data/SAEP2022/ts-electricity-price.csv",
    "data/SAEP2023/ts-electricity-price.csv",
]

# Read and preprocess data
def process_data(file_paths):
    all_data = []
    for file_path in file_paths:
        year = file_path.split('/')[-2][-4:]  # Extract year from folder name
        df = pd.read_csv(file_path, header=None, names=["Timestamp", "Price"])
        df["Year"] = year
        all_data.append(df[["Price", "Year"]])
    
    combined_data = pd.concat(all_data, ignore_index=True)
    combined_data["Price"] = pd.to_numeric(combined_data["Price"], errors="coerce")
    return combined_data.dropna(subset=["Price"])

# Function to compute summary statistics
def compute_summary_statistics(data):
    summary = data.groupby("Year")["Price"].agg(["min", "max", "mean", "median", "std"]).reset_index()
    summary.columns = ["Year", "Min", "Max", "Mean", "Median", "StdDev"]
    return summary

# Function to plot histograms in separate subplots
def plot_histograms(data, bin_size=10, min_price=0, max_price=500):
    years = sorted(data["Year"].unique())
    num_years = len(years)

    # Clip data to include overflow and underflow bins
    clipped_data = data.copy()
    clipped_data["Price"] = np.clip(clipped_data["Price"], min_price, max_price)

    # Define bin edges
    bin_edges = np.arange(min_price, max_price + bin_size, bin_size)

    # Plot histograms as separate subplots
    fig, axes = plt.subplots(num_years, 1, figsize=(9/2.54, 2/2.54 * num_years), sharex=True, sharey=True)

    for ax, year in zip(axes, years):
        year_data = clipped_data[clipped_data["Year"] == year]["Price"]
        counts, _ = np.histogram(year_data, bins=bin_edges)
        
        # Bar plot with bin edges as ticks between bars
        ax.hist(
            year_data, bins=bin_edges, color="blue", alpha=0.7, edgecolor="none", density=True,
        )

        ax.set_ylabel(f"{year}", fontsize=8, fontweight="bold")
        ax.grid(axis="y", linestyle="--", alpha=0.4)

        # Calculate and mark the mean
        mean_value = year_data.mean()
        ax.axvline(mean_value, color="red", linestyle="--", linewidth=1, label=f"Mean: {mean_value:.0f}")

        # Add legend
        ax.legend(fontsize=7, loc="upper right", frameon=False)


    # Create labels for the specific ticks
    label_ticks = {0, 50, 100, 150, 200, 250, 300}

    xticklabels = [str(int(x)) if (i == 0 or i == len(bin_edges) - 1 or int(x) in label_ticks) else "" for i, x in enumerate(bin_edges)]


    if len(bin_edges) > 1:  # Ensure there are enough ticks
        xticklabels[0] = "-∞"  # type: ignore # Make the last label (Y) empty
        xticklabels[-1] = "+∞"  # type: ignore # Make the last label (Y) empty

    # Set the modified x-tick labels
    axes[-1].set_xticks(bin_edges)
    axes[-1].set_xticklabels(xticklabels, rotation=90)
    axes[-1].set_xlabel("Electricity Price (€/MWh)", fontsize=8, fontweight="bold")
    axes[-1].set_xlim([bin_edges[0], bin_edges[-1]])


    yticks = np.linspace(0, 0.04, 3)
    axes[-1].set_yticks(yticks)
    axes[-1].set_yticklabels([f"{int(y*100)}%" for y in yticks])

    (_, _, x_center), (y_down, _, y_center) = utils_plot.axes_coordinates(axes)

    fig.supylabel("Frequency", fontsize=8, fontweight="bold", y=y_center)

    plt.tight_layout()

    # output
    utils_plot.output_plot(
        show=SHOW, save=SAVE, outdir=OUTDIR, plotname=PLOTNAME, dpi=DPI
    )


# Main execution
if __name__ == "__main__":
    SHOW = False
    SAVE = True
    OUTDIR = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "diagrams"
        / "plots"
    )
    PLOTNAME = "ElectricityPriceDistribution"
    DPI = 900


    data = process_data(file_paths)
    summary_stats = compute_summary_statistics(data)
    print(summary_stats)
    plot_histograms(data, bin_size=10, min_price=-10, max_price=260)
