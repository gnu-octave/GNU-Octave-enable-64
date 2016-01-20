################################################################################
##
##  Building GNU Octave with --enable-64 on GNU Linux
##
################################################################################

# location of this Makefile
ROOT_DIR  = ${PWD}
SRC_CACHE = $(ROOT_DIR)/source-cache
BUILD_DIR = $(ROOT_DIR)/build
LIBS_DIR  = $(ROOT_DIR)/libs

# create necessary file structure
IGNORE := $(shell mkdir -p $(SRC_CACHE) $(BUILD_DIR) $(LIBS_DIR))

.PHONY: clean octave-update

all: octave

clean:
	rm -Rf $(BUILD_DIR) $(LIBS_DIR) $(SRC_CACHE)

################################################################################
#
#   OpenBLAS  - http://www.openblas.net
#
#   The OpenBLAS library will be build from a specific version, ensuring
#   64 bit indices.
#
################################################################################

OPENBLAS_VER = 0.2.15

$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip:
	cd $(SRC_CACHE) \
	&& wget https://github.com/xianyi/OpenBLAS/archive/v$(OPENBLAS_VER).zip \
	&& mv v$(OPENBLAS_VER).zip openblas-$(OPENBLAS_VER).zip

$(LIBS_DIR)/lib/libopenblas_Octave64.so: \
  $(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip
	cd $(BUILD_DIR) \
	&& unzip $(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip \
	&& mv OpenBLAS-$(OPENBLAS_VER) openblas
	cd $(BUILD_DIR)/openblas \
	&& $(MAKE) BINARY=64 INTERFACE64=1 LIBNAMESUFFIX=Octave64 \
	&& $(MAKE) install PREFIX=$(LIBS_DIR) LIBNAMESUFFIX=Octave64

openblas: $(LIBS_DIR)/lib/libopenblas_Octave64.so


################################################################################
#
#   SuiteSparse  - http://www.suitesparse.com
#
#   The SuiteSparse library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

SUITESPARSE_VER = 4.4.7

$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz:
	cd $(SRC_CACHE) \
	&& wget http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-$(SUITESPARSE_VER).tar.gz
	cd $(SRC_CACHE) && mv SuiteSparse-$(SUITESPARSE_VER).tar.gz \
	suitesparse-$(SUITESPARSE_VER).tar.gz

$(LIBS_DIR)/lib/libsuitesparseconfig_Octave64.so: \
  $(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz \
  $(LIBS_DIR)/lib/libopenblas_Octave64.so
	# unpack sources
	cd $(BUILD_DIR) \
	&& tar -xf $(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz
	cd $(BUILD_DIR) && mv SuiteSparse suitesparse
	# fix metis stuff
	cd $(BUILD_DIR)/suitesparse \
	&& grep -l -R "^[[:space:]]( cd \$$(METIS_PATH) && \$$(MAKE) )" \
	 | xargs sed -i "/( cd \$$(METIS_PATH) && \$$(MAKE) )/d"
	# fix library name
	cd $(BUILD_DIR)/suitesparse \
	&& grep -R -l "\$(LIBRARY).so" \
	 | xargs sed -i "s/\$$(LIBRARY).so/\$$(LIBRARY)_Octave64.so/g"
	# build and install library
	rm -Rf $(LIBS_DIR)/include/suitesparse
	mkdir -p $(LIBS_DIR)/include/suitesparse
	cd $(BUILD_DIR)/suitesparse \
	&& $(MAKE) LAPACK="" \
	           BLAS="" \
	           UMFPACK_CONFIG="-DLONGBLAS='long'" \
	           CHOLMOD_CONFIG="-DLONGBLAS='long' -DNPARTITION" \
	           SPQR_CONFIG="-DLONGBLAS='long' -DNPARTITION" \
	           LD_LIBRARY_PATH='$(LIBS_DIR)/lib' \
	           LIB="-L$(LIBS_DIR)/lib -lopenblas_Octave64 -lm -lrt" \
	&& $(MAKE) install \
	           INSTALL_LIB=$(LIBS_DIR)/lib \
	           INSTALL_INCLUDE=$(LIBS_DIR)/include/suitesparse

suitesparse: $(LIBS_DIR)/lib/libsuitesparseconfig_Octave64.so


################################################################################
#
#   QRUPDATE  - http://sourceforge.net/projects/qrupdate/
#
#   The QRUPDATE library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

QRUPDATE_VER = 1.1.2

$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz:
	cd $(SRC_CACHE) \
	&& wget http://downloads.sourceforge.net/project/qrupdate/qrupdate/1.2/qrupdate-$(QRUPDATE_VER).tar.gz

$(LIBS_DIR)/lib/libqrupdate_Octave64.so: \
  $(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz \
  $(LIBS_DIR)/lib/libopenblas_Octave64.so
	# unpack sources
	cd $(BUILD_DIR) \
	&& tar -xf $(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz
	cd $(BUILD_DIR) && mv qrupdate-$(QRUPDATE_VER) qrupdate
	# fix library name
	cd $(BUILD_DIR)/qrupdate \
	&& grep -R -l "libqrupdate" \
	 | xargs sed -i "s/libqrupdate/libqrupdate_Octave64/g"
	# build and install library
	cd $(BUILD_DIR)/qrupdate \
	&& $(MAKE) install \
	           LAPACK="" \
	           BLAS="-lopenblas_Octave64" \
	           FFLAGS="-L$(LIBS_DIR)/lib -fdefault-integer-8" \
	           PREFIX=$(LIBS_DIR)

qrupdate: $(LIBS_DIR)/lib/libqrupdate_Octave64.so


################################################################################
#
#   ARPACK  - https://github.com/opencollab/arpack-ng
#
#   The ARPACK library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

ARPACK_VER = 3.3.0

$(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz:
	cd $(SRC_CACHE) \
	&& wget https://github.com/opencollab/arpack-ng/archive/$(ARPACK_VER).tar.gz \
	&& mv $(ARPACK_VER).tar.gz arpack-$(ARPACK_VER).tar.gz

$(LIBS_DIR)/lib/libarpack_Octave64.so: \
  $(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz \
  $(LIBS_DIR)/lib/libopenblas_Octave64.so
	# unpack sources
	cd $(BUILD_DIR) \
	&& tar -xf $(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz
	cd $(BUILD_DIR) && mv arpack-ng-$(ARPACK_VER) arpack
	# fix library name
	cd $(BUILD_DIR)/arpack \
	&& grep -R -l "libarpack" \
	 | xargs sed -i "s/libarpack/libarpack_Octave64/g"
	# build and install library
	rm -f $(LIBS_DIR)/lib64/libarpack_Octave64.*
	cd $(BUILD_DIR)/arpack \
	&& ./bootstrap \
	&& ./configure --prefix=$(LIBS_DIR) \
	               --with-blas='-lopenblas_Octave64' \
	               --with-lapack='' \
	               LT_SYS_LIBRARY_PATH=$(LIBS_DIR)/lib \
	               FFLAGS='-fdefault-integer-8' \
	               LDFLAGS='-L$(LIBS_DIR)/lib' \
	&& $(MAKE) && $(MAKE) install
	# move libraries
	mv -t $(LIBS_DIR)/lib $(LIBS_DIR)/lib64/libarpack_Octave64.a
	mv -t $(LIBS_DIR)/lib $(LIBS_DIR)/lib64/libarpack_Octave64.so*
	rm -Rf $(LIBS_DIR)/lib64

arpack: $(LIBS_DIR)/lib/libarpack_Octave64.so


################################################################################
#
#   GNU Octave  - http://www.gnu.org/software/octave/
#
#   Build development version of GNU Octave using --enable-64 and all
#   requirements.
#
################################################################################

LDSUITESPARSE = '-lamd_Octave64 \
                 -lcamd_Octave64 \
                 -lcolamd_Octave64 \
                 -lccolamd_Octave64 \
                 -lcxsparse_Octave64 \
                 -lumfpack_Octave64 \
                 -lcholmod_Octave64 \
                 -lsuitesparseconfig_Octave64'

OCTAVE_CONFIG_FLAGS = \
  CPPFLAGS='-I$(LIBS_DIR)/include' \
  LDFLAGS='-L$(LIBS_DIR)/lib' \
  LD_LIBRARY_PATH='$(LIBS_DIR)/lib' \
  --enable-64 \
  --with-blas='-lopenblas_Octave64' \
  --with-amd='-lamd_Octave64 -lsuitesparseconfig_Octave64' \
  --with-camd='-lcamd_Octave64 -lsuitesparseconfig_Octave64' \
  --with-colamd='-lcolamd_Octave64 -lsuitesparseconfig_Octave64' \
  --with-ccolamd='-lccolamd_Octave64 -lsuitesparseconfig_Octave64' \
  --with-cholmod=$(LDSUITESPARSE) \
  --with-cxsparse='-lcxsparse_Octave64 -lsuitesparseconfig_Octave64' \
  --with-umfpack=$(LDSUITESPARSE) \
  --with-qrupdate='-lqrupdate_Octave64' \
  --with-arpack='-larpack_Octave64'

$(SRC_CACHE)/octave:
	cd $(SRC_CACHE) && hg clone http://hg.savannah.gnu.org/hgweb/octave
	cd $(SRC_CACHE)/octave && ./bootstrap

octave: $(SRC_CACHE)/octave \
  $(LIBS_DIR)/lib/libopenblas_Octave64.so \
  $(LIBS_DIR)/lib/libsuitesparseconfig_Octave64.so \
  $(LIBS_DIR)/lib/libqrupdate_Octave64.so \
  $(LIBS_DIR)/lib/libarpack_Octave64.so
	# remove previous builds
	rm -Rf $(BUILD_DIR)/octave
	mkdir -p $(BUILD_DIR)/octave
	cd $(BUILD_DIR)/octave \
	&& $(SRC_CACHE)/octave/configure $(OCTAVE_CONFIG_FLAGS) \
	&& export LD_LIBRARY_PATH=$(LIBS_DIR)/lib \
	&& $(MAKE) && $(MAKE) check

octave-update: $(SRC_CACHE)/octave
	cd $(SRC_CACHE)/octave && hg pull && hg update default

