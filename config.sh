# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

# Enable Python fault handler on Pythons >= 3.3.
PYTHONFAULTHANDLER=1

# OpenBLAS version for systems that use it.
OPENBLAS_VERSION=0.2.18

source gfortran-install/gfortran_utils.sh

PCRE_URL=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.38.tar.gz

function build_simple_swig {
    local name=$1
    local version=$2
    local url=$3
    if [ -e "${name}-stamp" ]; then
        return
    fi
    local name_version="${name}-${version}"
    local targz=${name_version}.tar.gz
    fetch_unpack $url/$targz
    (cd $name_version \
        && wget $PCRE_URL \
        && ./Tools/pcre-build.sh \
        && ./configure --prefix=$BUILD_PREFIX \
        && make \
        && make install)
    touch "${name}-stamp"
}

function pre_build {
    # Install the build dependencies
    yum install -y suitesparse-devel
    build_simple_swig swig 3.0.12 http://prdownloads.sourceforge.net/swig/
}

function build_wheel {
    if [ -z "$IS_OSX" ]; then
        build_libs $PLAT
        build_pip_wheel $@
    else
        build_osx_wheel $@
    fi
}

function build_libs {
    if [ -n "$IS_OSX" ]; then return; fi  # No OpenBLAS for OSX
    local plat=${1:-$PLAT}
    local tar_path=$(abspath $(get_gf_lib "openblas-${OPENBLAS_VERSION}" "$plat"))
    (cd / && tar zxf $tar_path)
}

function set_arch {
    local arch=$1
    export CC="clang $arch"
    export CXX="clang++ $arch"
    export CFLAGS="$arch"
    export FFLAGS="$arch"
    export FARCH="$arch"
    export LDFLAGS="$arch"
}

function build_osx_wheel {
    # Build dual arch wheel
    # Standard gfortran won't build dual arch objects, so we have to build two
    # wheels, one for 32-bit, one for 64, then fuse them.
    local repo_dir=${1:-$REPO_DIR}
    local py_ld_flags="-Wall -undefined dynamic_lookup -bundle"

    install_gfortran
    # 64-bit wheel
    local arch="-m64"
    set_arch $arch
    build_libs x86_64
    # Build wheel
    export LDSHARED="$CC $py_ld_flags"
    export LDFLAGS="$arch $py_ld_flags"
    build_pip_wheel "$repo_dir"
}

function run_tests {
    cd ../scikit-umfpack
    py.test
}
