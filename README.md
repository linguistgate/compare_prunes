# compare_prunes.sh

## Overview

**compare_prunes.sh** is a Bash script for Arch Linux that helps cross-check and refine package cleanup recommendations from **Pellets** (a declarative package manager wrapper) and **Pacman** (Arch's native package manager). It filters out packages that are optional dependencies of explicitly installed packages, ensuring you avoid accidental removal of useful functionality.

The script outputs annotated lists showing which packages are excluded from pruning, which are safe to remove, and where Pellets and Pacman agree/disagree.  
This workflow is ideal for curating a smart package list for **fresh Arch installs** and for safe post-install cleanup.

## Why Use This Script?

Package managers often recommend removing packages (“pruning” or “orphans”) that are technically not required, but some of these are **optional dependencies** needed for extra features in your explicitly installed packages.  
Removing them blindly may break convenient functionalities.

**compare_prunes.sh** addresses this by:
- Excluding optional dependencies from prune candidates.
- Annotating exactly which explicit package(s) required each, for clear auditing.
- Comparing the filtered recommendations of Pellets and Pacman.
- Giving you reliable lists for clean-up or reinstallation.

## How It Works (Step-by-Step)

1. **Gather prune candidates from Pellets:**  
   Runs `pellets` in dry mode to get packages suggested for pruning.

2. **Obtain Pacman orphan package list:**  
   Uses `pacman -Qdtq` to list dependencies with no remaining explicit owners.

3. **List explicitly installed packages:**  
   All top-level packages are listed via `pacman -Qeq`.

4. **Build optional dependency mapping:**  
   For each explicit package, parses the Optional Deps field via `pacman -Si`.  
   Strips trailing colons from dependency names.  
   Records lines of the form:  
        optional_dep explicit_pkg  
   Saves the mapping to a file for annotation and deduplication.

5. **Filter prune candidates:**  
   Removes from the Pellets prune list any package that is an optional dependency for an explicit package.

6. **Comparison and annotation output:**  
   - Annotated list of packages removed from the prune list with the explicit packages that made them optional  
   - Intersection between filtered Pellets prune and Pacman orphans  
   - Pellets-only and Pacman-only lists  
   - Package counts before and after filtering

## Example Output

    === STEP 6: Comparisons ===

    --- Packages removed from pellets prune because they're optional dependencies ---
    go  <- optional for hugo
    python  <- optional for mkdocs,anki

    --- In BOTH pellets (filtered) and pacman orphan list ---
    libfoo
    libbar

    --- Only in pellets prune (after filtering optionals) ---
    extra-lib

    --- Only in pacman orphan list ---
    dev-only-lib

    Pellets prune BEFORE filtering: 15
    Pellets prune AFTER filtering:  12

## Requirements

- Arch Linux or compatible system using `pacman`
- [Pellets](https://github.com/jirutka/pellets) installed and configured
- Standard UNIX tools: bash, grep, awk, sed, sort, comm, paste

## Usage

1. Save the script as `compare_prunes.sh`.  
2. Make it executable:  
        chmod +x compare_prunes.sh  
3. Run the script:  
        ./compare_prunes.sh  
4. Review output and decide what to prune or keep.

## Intended Workflow for Fresh Installs

- On an established Arch system, run the script.  
- Save explicit packages and optional dependencies you want.  
- On a fresh install, reinstall them to keep your system lean but functional.

## Customization

You can extend the script to include optional dep descriptions for even better audit data.

## Troubleshooting

- Ensure Pellets is installed and configured correctly.  
- Keep databases updated: `sudo pacman -Sy`.  
- Watch for typos/missing dependencies.
