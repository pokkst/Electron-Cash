#!/bin/bash
# Run this after a new release to update dependencies

set -e

venv_dir=~/.electron-cash-venv
contrib=$(dirname "$0")

. $contrib/base.sh || { echo "Cannot find base.sh" && exit 1; }

which virtualenv > /dev/null 2>&1 || fail "Please install virtualenv"
python3 -m hashin -h > /dev/null 2>&1 || { python3 -m pip install hashin --user; }
other_python=$(which python3)

for i in '' '-hw' '-binaries'; do
    rm -rf "$venv_dir"
    virtualenv -p $(which python3) $venv_dir

    source $venv_dir/bin/activate

    m="requirements$i"
    info "Installing $m dependencies"

    python -m pip install -r $contrib/requirements/requirements${i}.txt --upgrade

    info "OK."

    requirements=$(pip freeze --all)
    restricted=$(echo $requirements | $other_python $contrib/deterministic-build/find_restricted_dependencies.py)
    requirements="$requirements $restricted"

    info "Generating package hashes..."
    rm $contrib/deterministic-build/requirements${i}.txt
    touch $contrib/deterministic-build/requirements${i}.txt

    for requirement in $requirements; do
        info "  Hashing ${requirement}..."
        $other_python -m hashin -r $contrib/deterministic-build/requirements${i}.txt ${requirement}
    done

    info "OK."
done

info "Done. Updated requirements"
