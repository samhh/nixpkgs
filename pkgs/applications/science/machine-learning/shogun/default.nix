{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, fetchurl
  # build
, cmake
, ctags
, swig
  # math
, eigen
, blas
, lapack
, glpk
  # data
, protobuf
, json_c
, libxml2
, hdf5
, curl
  # compression
, libarchive
, bzip2
, xz
, snappy
, lzo
  # more math
, nlopt
, lp_solve
, colpack
  # extra support
, pythonSupport ? true
, pythonPackages ? null
, opencvSupport ? false
, opencv ? null
, withSvmLight ? false
}:

assert pythonSupport -> pythonPackages != null;
assert opencvSupport -> opencv != null;

assert (!blas.isILP64) && (!lapack.isILP64);

let
  pname = "shogun";
  version = "6.1.4";

  rxcppVersion = "4.0.0";
  gtestVersion = "1.8.0";

  srcs = {
    toolbox = fetchFromGitHub {
      owner = pname + "-toolbox";
      repo = pname;
      rev = pname + "_" + version;
      sha256 = "05s9dclmk7x5d7wnnj4qr6r6c827m72a44gizcv09lxr28pr9inz";
      fetchSubmodules = true;
    };
    # we need the packed archive
    rxcpp = fetchurl {
      url = "https://github.com/Reactive-Extensions/RxCpp/archive/v${rxcppVersion}.tar.gz";
      sha256 = "0y2isr8dy2n1yjr9c5570kpc9lvdlch6jv0jvw000amwn5d3krsh";
    };
    gtest = fetchurl {
      url = "https://github.com/google/googletest/archive/release-${gtestVersion}.tar.gz";
      sha256 = "1n5p1m2m3fjrjdj752lf92f9wq3pl5cbsfrb49jqbg52ghkz99jq";
    };
  };
in

stdenv.mkDerivation rec {
  inherit pname version;

  src = srcs.toolbox;

  patches = [
    (fetchpatch {
      url = "https://github.com/awild82/shogun/commit/365ce4c4c700736d2eec8ba6c975327a5ac2cd9b.patch";
      sha256 = "158hqv4xzw648pmjbwrhxjp7qcppqa7kvriif87gn3zdn711c49s";
    })
  ] ++ lib.optional (!withSvmLight) ./svmlight-scrubber.patch;

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    eigen
    blas
    lapack
    glpk
    protobuf
    json_c
    libxml2
    hdf5
    curl
    libarchive
    bzip2
    xz
    snappy
    lzo
    nlopt
    lp_solve
    colpack
    ctags
    swig
  ] ++ lib.optionals pythonSupport (with pythonPackages; [ python ply numpy ])
    ++ lib.optional opencvSupport opencv;

  cmakeFlags = let
    enableIf = cond: if cond then "ON" else "OFF";
  in [
    "-DBUILD_META_EXAMPLES=${enableIf doCheck}"
    "-DCMAKE_VERBOSE_MAKEFILE=${enableIf doCheck}"
    "-DENABLE_TESTING=${enableIf doCheck}"
    "-DPythonModular=${enableIf pythonSupport}"
    "-DOpenCV=${enableIf opencvSupport}"
    "-DUSE_SVMLIGHT=${enableIf withSvmLight}"
  ];

  CCACHE_DISABLE="1";
  CCACHE_DIR=".ccache";

  NIX_CFLAGS_COMPILE="-faligned-new";

  # broken
  doCheck = false;

  postUnpack = ''
    mkdir -p $sourceRoot/third_party/{rxcpp,gtest}
    ln -s ${srcs.rxcpp} $sourceRoot/third_party/rxcpp/v${rxcppVersion}.tar.gz
    ln -s ${srcs.gtest} $sourceRoot/third_party/gtest/release-${gtestVersion}.tar.gz
  '';

  postPatch = ''
    # Fix preprocessing SVMlight code
    sed -i \
        -e 's@#ifdef SVMLIGHT@#ifdef USE_SVMLIGHT@' \
        -e '/^#ifdef USE_SVMLIGHT/,/^#endif/ s@#endif@#endif //USE_SVMLIGHT@' \
        src/shogun/kernel/string/CommUlongStringKernel.cpp
    sed -i -e 's/#if USE_SVMLIGHT/#ifdef USE_SVMLIGHT/' src/interfaces/swig/Machine.i
    sed -i -e 's@// USE_SVMLIGHT@//USE_SVMLIGHT@' src/interfaces/swig/Transfer.i
    sed -i -e 's@/\* USE_SVMLIGHT \*/@//USE_SVMLIGHT@' src/interfaces/swig/Transfer_includes.i
  '' + lib.optionalString (!withSvmLight) ''
    # Run SVMlight scrubber
    patchShebangs scripts/light-scrubber.sh
    echo "removing SVMlight code"
    ./scripts/light-scrubber.sh
  '';

  meta = with lib; {
    description = "A toolbox which offers a wide range of efficient and unified machine learning methods";
    homepage = "http://shogun-toolbox.org/";
    license = if withSvmLight then licenses.unfree else licenses.gpl3Plus;
    maintainers = with maintainers; [ edwtjo ];
  };
}
