#!/bin/bash
# compare_prunes.sh
# Compare Pellets' prune list with Pacman's orphan list,
# exclude optional dependencies of explicit packages,
# and show annotated filtered results.

set -eu

# STEP 1: Pellets prune list
printf "dry\n" | pellets 2>&1 \
    | grep "prune" \
    | awk '{print $2}' \
    | sort -u > /tmp/pellets_prune.txt

# STEP 2: Pacman orphan list
pacman -Qdtq 2>/dev/null | sort -u > /tmp/orphans.txt || true

# STEP 3: Explicit packages
pacman -Qeq | sort -u > /tmp/explicit.txt

# STEP 4: Optional dependency mapping
> /tmp/optional_deps_map.txt
while read -r pkg; do
    pacman -Si "$pkg" 2>/dev/null \
        | sed -n '/^Optional Deps/,/^Conflicts With/{/^Optional Deps/d;/^Conflicts With/d;p}' \
        | sed 's/^[[:space:]]*//' \
        | awk -F':' '{print $1}' | while read -r dep; do
            [ -n "$dep" ] && echo "$dep $pkg" >> /tmp/optional_deps_map.txt
        done
done < /tmp/explicit.txt

# Sort/dedupe
sort -u /tmp/optional_deps_map.txt > /tmp/optional_deps_map.txt.sorted
awk '{print $1}' /tmp/optional_deps_map.txt.sorted | sort -u > /tmp/optional_deps.txt

# STEP 5: Filter out optional deps
grep -v -w -F -f /tmp/optional_deps.txt /tmp/pellets_prune.txt > /tmp/pellets_prune_filtered.txt || true

# STEP 6: Output comparisons
echo "=== STEP 6: Comparisons ==="

echo "--- Packages removed from pellets prune because they're optional dependencies ---"
while read -r pkg; do
    pkgs=$(awk -v dep="$pkg" '$1 == dep {print $2}' /tmp/optional_deps_map.txt.sorted | paste -sd, -)
    echo "$pkg  <- optional for $pkgs"
done < <(comm -12 /tmp/pellets_prune.txt /tmp/optional_deps.txt || true)
echo

echo "--- In BOTH pellets (filtered) and pacman orphan list ---"
comm -12 /tmp/pellets_prune_filtered.txt /tmp/orphans.txt
echo

echo "--- Only in pellets prune (after filtering optionals) ---"
comm -23 /tmp/pellets_prune_filtered.txt /tmp/orphans.txt
echo

echo "--- Only in pacman orphan list ---"
comm -13 /tmp/pellets_prune_filtered.txt /tmp/orphans.txt
echo

echo "Pellets prune BEFORE filtering: $(wc -l < /tmp/pellets_prune.txt)"
echo "Pellets prune AFTER filtering:  $(wc -l < /tmp/pellets_prune_filtered.txt)"
