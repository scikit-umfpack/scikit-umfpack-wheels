# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

# Enable Python fault handler on Pythons >= 3.3.
PYTHONFAULTHANDLER=1

function pre_build {
    if [ -n "$IS_OSX" ];
        then brew update; # Update to get suite-sparse formula
    else
        build_openblas
    fi
    # Install the build dependencies
    build_swig
    build_suitesparse
}

function run_tests {
    cd ../scikit-umfpack
    py.test
}
