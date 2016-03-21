################################################################################
##
##  Building GNU Octave with --enable-64 on GNU Linux
##
################################################################################

# build libraries like "libopenblas_Octave64.so"
SONAME_SUFFIX ?= Octave64
# specify root directory (default: current directory)
ROOT_DIR      ?= ${PWD}

# create necessary file structure
SRC_CACHE = $(ROOT_DIR)/source-cache
BUILD_DIR = $(ROOT_DIR)/build
LIBS_DIR  = $(ROOT_DIR)/libs
IGNORE := $(shell mkdir -p $(SRC_CACHE) $(BUILD_DIR) $(LIBS_DIR))

# if no SONAME suffix is wanted, leave everything blank
ifeq ($(strip $(SONAME_SUFFIX)),)
_SONAME_SUFFIX =
else
_SONAME_SUFFIX = _$(SONAME_SUFFIX)
endif

# small helper function to search for a library name pattern for replacing
fix_soname = grep -Rl '$(2)' $(BUILD_DIR)/$(1) | xargs sed -i "s/$(2)/$(3)/g";

.PHONY: clean

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

OPENBLAS_VER = 0.2.17

$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip:
	cd $(SRC_CACHE) \
	&& wget https://github.com/xianyi/OpenBLAS/archive/v$(OPENBLAS_VER).zip \
	&& mv v$(OPENBLAS_VER).zip openblas-$(OPENBLAS_VER).zip

$(LIBS_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip
	cd $(BUILD_DIR) \
	&& unzip $(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip \
	&& mv OpenBLAS-$(OPENBLAS_VER) openblas
	cd $(BUILD_DIR)/openblas \
	&& $(MAKE) BINARY=64 INTERFACE64=1 LIBNAMESUFFIX=$(SONAME_SUFFIX) \
	&& $(MAKE) install PREFIX=$(LIBS_DIR) LIBNAMESUFFIX=$(SONAME_SUFFIX)

openblas: $(LIBS_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so


################################################################################
#
#   SuiteSparse  - http://www.suitesparse.com
#
#   The SuiteSparse library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

SUITESPARSE_VER = 4.5.1

SUITESPARSE_LIBS = amd camd colamd ccolamd csparse cxsparse cholmod umfpack \
	spqr klu rbio ldl btf suitesparseconfig

$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz:
	cd $(SRC_CACHE) \
	&& wget http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-$(SUITESPARSE_VER).tar.gz \
	&& mv SuiteSparse-$(SUITESPARSE_VER).tar.gz \
	      suitesparse-$(SUITESPARSE_VER).tar.gz

$(LIBS_DIR)/lib/libsuitesparseconfig$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz \
	$(LIBS_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so
	# unpack sources
	cd $(BUILD_DIR) \
	&& tar -xf $(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz \
	&& mv SuiteSparse suitesparse
	# fix library names
	$(foreach l,$(SUITESPARSE_LIBS), \
		$(call fix_soname,suitesparse,LIBRARY = lib$(l),LIBRARY = lib$(l)$(_SONAME_SUFFIX)))
	$(foreach l,$(SUITESPARSE_LIBS), \
		$(call fix_soname,suitesparse,\-l$(l)\ ,\-l$(l)$(_SONAME_SUFFIX)\ ))
	$(foreach l,$(SUITESPARSE_LIBS), \
		$(call fix_soname,suitesparse,\-l$(l)$$,\-l$(l)$(_SONAME_SUFFIX)\ ))
	# build and install library
	cd $(BUILD_DIR)/suitesparse \
	&& $(MAKE) library \
	           LAPACK= \
	           BLAS=-lopenblas$(_SONAME_SUFFIX) \
	           UMFPACK_CONFIG=-D'LONGBLAS=long' \
	           CHOLMOD_CONFIG=-D'LONGBLAS=long' \
	           LDFLAGS='-L$(LIBS_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib' \
	&& $(MAKE) install \
	           INSTALL=$(LIBS_DIR) \
	           INSTALL_DOC=/tmp/doc \
	           LAPACK= \
	           BLAS=-lopenblas$(_SONAME_SUFFIX) \
	           LDFLAGS='-L$(LIBS_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib'

suitesparse: $(LIBS_DIR)/lib/libsuitesparseconfig$(_SONAME_SUFFIX).so


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

$(LIBS_DIR)/lib/libqrupdate$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz \
	$(LIBS_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so
	# unpack sources
	cd $(BUILD_DIR) \
	&& tar -xf $(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz \
	&& mv qrupdate-$(QRUPDATE_VER) qrupdate
	# fix library name
	$(call fix_soname,qrupdate,libqrupdate,libqrupdate$(_SONAME_SUFFIX))
	# build and install library
	cd $(BUILD_DIR)/qrupdate \
	&& $(MAKE) install \
	           LAPACK="" \
	           BLAS="-lopenblas$(_SONAME_SUFFIX)" \
	           FFLAGS="-L$(LIBS_DIR)/lib -fdefault-integer-8" \
	           PREFIX=$(LIBS_DIR)

qrupdate: $(LIBS_DIR)/lib/libqrupdate$(_SONAME_SUFFIX).so


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

$(LIBS_DIR)/lib/libarpack$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz \
	$(LIBS_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so
	# unpack sources
	cd $(BUILD_DIR) \
	&& tar -xf $(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz \
	&& mv arpack-ng-$(ARPACK_VER) arpack
	# fix library name
	$(call fix_soname,arpack,libarpack,libarpack$(_SONAME_SUFFIX))
	# build and install library
	cd $(BUILD_DIR)/arpack \
	&& ./bootstrap \
	&& ./configure --prefix=$(LIBS_DIR) \
	               --with-blas='-lopenblas$(_SONAME_SUFFIX)' \
	               --with-lapack='' \
	               LT_SYS_LIBRARY_PATH=$(LIBS_DIR)/lib \
	               FFLAGS='-fdefault-integer-8' \
	               LDFLAGS='-L$(LIBS_DIR)/lib' \
	&& $(MAKE) && $(MAKE) install libdir='$${exec_prefix}/lib'
	rm -f $(LIBS_DIR)/lib/libarpack$(_SONAME_SUFFIX).la

arpack: $(LIBS_DIR)/lib/libarpack$(_SONAME_SUFFIX).so


################################################################################
#
#   GNU Octave  - http://www.gnu.org/software/octave/
#
#   Build development version of GNU Octave using --enable-64 and all
#   requirements.
#
################################################################################

OCTAVE_VER = 4.1.0+

LDSUITESPARSE = \
  '-lamd$(_SONAME_SUFFIX) \
   -lcamd$(_SONAME_SUFFIX) \
   -lcolamd$(_SONAME_SUFFIX) \
   -lccolamd$(_SONAME_SUFFIX) \
   -lcxsparse$(_SONAME_SUFFIX) \
   -lumfpack$(_SONAME_SUFFIX) \
   -lcholmod$(_SONAME_SUFFIX) \
   -lsuitesparseconfig$(_SONAME_SUFFIX)'

OCTAVE_CONFIG_FLAGS = \
  CPPFLAGS='-I$(LIBS_DIR)/include' \
  LDFLAGS='-L$(LIBS_DIR)/lib' \
  LD_LIBRARY_PATH='$(LIBS_DIR)/lib' \
  --enable-64 \
  --with-blas='-lopenblas$(_SONAME_SUFFIX)' \
  --with-amd='-lamd$(_SONAME_SUFFIX) \
              -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-camd='-lcamd$(_SONAME_SUFFIX) \
               -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-colamd='-lcolamd$(_SONAME_SUFFIX) \
                 -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-ccolamd='-lccolamd$(_SONAME_SUFFIX) \
                  -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-cxsparse='-lcxsparse$(_SONAME_SUFFIX) \
                   -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-cholmod=$(LDSUITESPARSE) \
  --with-umfpack=$(LDSUITESPARSE) \
  --with-qrupdate='-lqrupdate$(_SONAME_SUFFIX)' \
  --with-arpack='-larpack$(_SONAME_SUFFIX)'

$(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz:
	$(eval URL := $(shell \
	curl -L --head http://hydra.nixos.org/job/gnu/octave-default/tarball/latest/download/ \
	| grep -o 'http\S\+.tar.gz'))
	cd $(SRC_CACHE) && wget $(URL)

$(BUILD_DIR)/octave/run-octave: $(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz \
	$(LIBS_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so \
	$(LIBS_DIR)/lib/libsuitesparseconfig$(_SONAME_SUFFIX).so \
	$(LIBS_DIR)/lib/libqrupdate$(_SONAME_SUFFIX).so \
	$(LIBS_DIR)/lib/libarpack$(_SONAME_SUFFIX).so
	cd $(BUILD_DIR) \
	&& tar -xf $(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz \
	&& mv octave-$(OCTAVE_VER) octave
	export LD_LIBRARY_PATH=$(LIBS_DIR)/lib
	cd $(BUILD_DIR)/octave \
	&& ./configure $(OCTAVE_CONFIG_FLAGS) && $(MAKE)
	&& $(MAKE) check LD_LIBRARY_PATH='$(LIBS_DIR)/lib'

octave: $(BUILD_DIR)/octave/run-octave
