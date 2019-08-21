################################################################################
##
##  Building GNU Octave with 64-bit libraries on GNU Linux
##
################################################################################

# specify root directory (default: current directory)
ROOT_DIR ?= ${PWD}

# create necessary file structure
SRC_CACHE   ?= $(ROOT_DIR)/source-cache
BUILD_DIR   ?= $(ROOT_DIR)/build
INSTALL_DIR ?= $(ROOT_DIR)/install

LD_LIBRARY_PATH = $(INSTALL_DIR)/lib
IGNORE := $(shell mkdir -p $(SRC_CACHE) $(BUILD_DIR) $(INSTALL_DIR))

.PHONY: clean

.EXPORT_ALL_VARIABLES:

all: octave

clean:
	rm -Rf $(BUILD_DIR) $(INSTALL_DIR) $(SRC_CACHE)

################################################################################
#
#   OpenBLAS  - https://www.openblas.net/
#
#   The OpenBLAS library will be build from a specific version, ensuring
#   64 bit indices.
#
################################################################################

OPENBLAS_VER = 0.3.7

$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip:
	@echo -e "\n>>> Download OpenBLAS <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://github.com/xianyi/OpenBLAS/archive/v$(OPENBLAS_VER).zip" \
	                && mv v$(OPENBLAS_VER).zip $@

$(INSTALL_DIR)/lib/libopenblas.so: \
	$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip
	@echo -e "\n>>> Unzip to $(BUILD_DIR)/openblas <<<\n"
	cd $(BUILD_DIR) && unzip -q $< \
	                && mv OpenBLAS-$(OPENBLAS_VER) openblas
	cd $(BUILD_DIR)/openblas \
	&& $(MAKE) BINARY=64 INTERFACE64=1 DYNAMIC_ARCH=1 CONSISTENT_FPCSR=1 \
	&& $(MAKE) install PREFIX=$(INSTALL_DIR)

openblas: $(INSTALL_DIR)/lib/libopenblas.so


################################################################################
#
#   SuiteSparse  - http://www.suitesparse.com
#
#   The SuiteSparse library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

SUITESPARSE_VER = 5.4.0

$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz:
	@echo -e "\n>>> Download SuiteSparse <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-$(SUITESPARSE_VER).tar.gz" \
	                && mv SuiteSparse-$(SUITESPARSE_VER).tar.gz $@

$(INSTALL_DIR)/lib/libsuitesparseconfig.so: \
	$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/suitesparse <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv SuiteSparse suitesparse
	# build and install library
	cd $(BUILD_DIR)/suitesparse \
	&& $(MAKE) library \
	           LAPACK= \
	           BLAS=-lopenblas \
	           UMFPACK_CONFIG=-D'LONGBLAS=long' \
	           CHOLMOD_CONFIG=-D'LONGBLAS=long' \
	           LDFLAGS='-L$(INSTALL_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib' \
	           CMAKE_OPTIONS=-D'CMAKE_INSTALL_PREFIX=$(INSTALL_DIR)' \
	&& $(MAKE) install \
	           INSTALL=$(INSTALL_DIR) \
	           INSTALL_DOC=/tmp/doc \
	           LAPACK= \
	           BLAS=-lopenblas \
	           LDFLAGS='-L$(INSTALL_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib'

suitesparse: $(INSTALL_DIR)/lib/libsuitesparseconfig.so


################################################################################
#
#   QRUPDATE  - http://sourceforge.net/projects/qrupdate/
#
#   The QRUPDATE library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

QRUPDATE_VER = 1.1.2

QRUPDATE_CONFIG_FLAGS = \
  PREFIX=$(INSTALL_DIR) \
  LAPACK="" \
  BLAS="-lopenblas" \
  FFLAGS="-L$(INSTALL_DIR)/lib -fdefault-integer-8"

$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz:
	@echo -e "\n>>> Download QRUPDATE <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"http://downloads.sourceforge.net/project/qrupdate/qrupdate/1.2/qrupdate-$(QRUPDATE_VER).tar.gz"

$(INSTALL_DIR)/lib/libqrupdate.so: \
	$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/qrupdate <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv qrupdate-$(QRUPDATE_VER) qrupdate
	# build and install library
	cd $(BUILD_DIR)/qrupdate \
	&& $(MAKE) test    $(QRUPDATE_CONFIG_FLAGS) \
	&& $(MAKE) install $(QRUPDATE_CONFIG_FLAGS)

qrupdate: $(INSTALL_DIR)/lib/libqrupdate.so


################################################################################
#
#   ARPACK  - https://github.com/opencollab/arpack-ng
#
#   The ARPACK library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

ARPACK_VER = 3.7.0

$(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz:
	@echo -e "\n>>> Download ARPACK <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://github.com/opencollab/arpack-ng/archive/$(ARPACK_VER).tar.gz" \
	                && mv $(ARPACK_VER).tar.gz $@

$(INSTALL_DIR)/lib/libarpack.so: \
	$(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/arpack <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv arpack-ng-$(ARPACK_VER) arpack
	# build and install library
	cd $(BUILD_DIR)/arpack \
	&& ./bootstrap \
	&& ./configure --prefix=$(INSTALL_DIR) \
	               --libdir=$(INSTALL_DIR)/lib \
	               --with-blas='-lopenblas' \
	               --with-lapack='' \
	               INTERFACE64=1 \
	               LT_SYS_LIBRARY_PATH=$(INSTALL_DIR)/lib \
	               LDFLAGS='-L$(INSTALL_DIR)/lib' \
	&& $(MAKE) check \
	&& $(MAKE) install

arpack: $(INSTALL_DIR)/lib/libarpack.so


################################################################################
#
#   GNU Octave  - http://www.gnu.org/software/octave/
#
#   Build GNU Octave using --enable-64 and all requirements.
#
################################################################################

OCTAVE_VER ?= 5.1.0

OCTAVE_CONFIG_FLAGS = \
  CPPFLAGS='-I$(INSTALL_DIR)/include' \
  LDFLAGS='-L$(INSTALL_DIR)/lib' \
  F77_INTEGER_8_FLAG='-fdefault-integer-8' \
  LD_LIBRARY_PATH='$(INSTALL_DIR)/lib' \
  --prefix=$(INSTALL_DIR) \
  --libdir='$(INSTALL_DIR)/lib' \
  --enable-64 \
  --with-blas='-lopenblas'

$(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz:
	@echo -e "\n>>> Download GNU Octave $(OCTAVE_VER) <<<\n"
ifeq ($(OCTAVE_VER), stable)
	cd $(SRC_CACHE) && wget -q \
	  "https://octave.mround.de/octave-stable.tar.gz"
else
	cd $(SRC_CACHE) && wget -q \
	  "https://ftp.gnu.org/gnu/octave/octave-$(OCTAVE_VER).tar.gz"
endif

$(INSTALL_DIR)/bin/octave-$(OCTAVE_VER): \
	$(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so \
	$(INSTALL_DIR)/lib/libsuitesparseconfig.so \
	$(INSTALL_DIR)/lib/libqrupdate.so \
	$(INSTALL_DIR)/lib/libarpack.so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/octave-$(OCTAVE_VER) <<<\n"
	mkdir -p $(BUILD_DIR)/octave-$(OCTAVE_VER)
	cd $(BUILD_DIR) && tar -xf $< -C octave-$(OCTAVE_VER) \
	                       --strip-components 1
	@echo -e "\n>>> Octave: configure (1/3) <<<\n"
	cd $(BUILD_DIR)/octave-$(OCTAVE_VER) && ./configure $(OCTAVE_CONFIG_FLAGS)
	@echo -e "\n>>> Octave: build (2/3) <<<\n"
	cd $(BUILD_DIR)/octave-$(OCTAVE_VER) && $(MAKE) install
	@echo -e "\n>>> Octave: check (3/3) <<<\n"
	cd $(BUILD_DIR)/octave-$(OCTAVE_VER) && $(MAKE) check \
	                          LD_LIBRARY_PATH='$(INSTALL_DIR)/lib'

octave: $(INSTALL_DIR)/bin/octave-$(OCTAVE_VER)
	@echo -e "\n\n"
	@echo -e " >>> Finished building GNU Octave $(OCTAVE_VER)"
	@echo -e " with 64-bit libraries!!! <<<"
	@echo -e "\n  To start GNU Octave run:\n\n    $<\n\n"
