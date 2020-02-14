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

# specify elevated privileges command to install to INSTALL_DIR
SUDO_INSTALL ?=

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

OPENBLAS_VER ?= 0.3.8

$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip:
	@echo -e "\n>>> Download OpenBLAS $(OPENBLAS_VER) <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://github.com/xianyi/OpenBLAS/archive/v$(OPENBLAS_VER).zip" \
	                && mv v$(OPENBLAS_VER).zip $@

$(INSTALL_DIR)/lib/libopenblas.so: \
	$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip
	@echo -e "\n>>> Unzip OpenBLAS $(OPENBLAS_VER) <<<\n"
	cd $(BUILD_DIR) && unzip -q $< \
	                && mv OpenBLAS-$(OPENBLAS_VER) openblas-$(OPENBLAS_VER)
	cd $(BUILD_DIR)/openblas-$(OPENBLAS_VER) \
	&& $(MAKE) BINARY=64 INTERFACE64=1 DYNAMIC_ARCH=1 CONSISTENT_FPCSR=1 \
	&& $(SUDO_INSTALL) $(MAKE) install PREFIX=$(INSTALL_DIR)

openblas: $(INSTALL_DIR)/lib/libopenblas.so


################################################################################
#
#   SuiteSparse  - http://www.suitesparse.com
#
#   The SuiteSparse library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

SUITESPARSE_VER ?= 5.6.0

$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz:
	@echo -e "\n>>> Download SuiteSparse $(SUITESPARSE_VER) <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v$(SUITESPARSE_VER).tar.gz" \
	                && mv v$(SUITESPARSE_VER).tar.gz $@

$(INSTALL_DIR)/lib/libsuitesparseconfig.so: \
	$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so
	@echo -e "\n>>> Untar SuiteSparse $(SUITESPARSE_VER) <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv SuiteSparse-$(SUITESPARSE_VER) \
	                      suitesparse-$(SUITESPARSE_VER)
	# build and install library
	cd $(BUILD_DIR)/suitesparse-$(SUITESPARSE_VER) \
	&& $(MAKE) library \
	           LAPACK= \
	           BLAS=-lopenblas \
	           UMFPACK_CONFIG=-D'LONGBLAS=long' \
	           CHOLMOD_CONFIG=-D'LONGBLAS=long' \
	           LDFLAGS='-L$(INSTALL_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib' \
	           CMAKE_OPTIONS="-D'CMAKE_INSTALL_PREFIX=$(INSTALL_DIR)' \
	                          -D'CMAKE_INSTALL_BINDIR=$(INSTALL_DIR)/bin' \
	                          -D'CMAKE_INSTALL_LIBDIR=$(INSTALL_DIR)/lib' \
	                          -D'CMAKE_INSTALL_INCLUDEDIR=$(INSTALL_DIR)/include'" \
	&& $(SUDO_INSTALL) $(MAKE) install \
	           INSTALL=$(INSTALL_DIR) \
	           INSTALL_DOC=/tmp/doc \
	           LAPACK= \
	           BLAS=-lopenblas \
	           LDFLAGS='-L$(INSTALL_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib' \
	           CMAKE_OPTIONS="-D'CMAKE_INSTALL_PREFIX=$(INSTALL_DIR)' \
	                          -D'CMAKE_INSTALL_BINDIR=$(INSTALL_DIR)/bin' \
	                          -D'CMAKE_INSTALL_LIBDIR=$(INSTALL_DIR)/lib' \
	                          -D'CMAKE_INSTALL_INCLUDEDIR=$(INSTALL_DIR)/include'"

suitesparse: $(INSTALL_DIR)/lib/libsuitesparseconfig.so


################################################################################
#
#   QRUPDATE  - http://sourceforge.net/projects/qrupdate/
#
#   The QRUPDATE library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

QRUPDATE_VER ?= 1.1.2

QRUPDATE_CONFIG_FLAGS = \
  PREFIX=$(INSTALL_DIR) \
  LAPACK="" \
  BLAS="-lopenblas" \
  FFLAGS="-L$(INSTALL_DIR)/lib -fdefault-integer-8"

$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz:
	@echo -e "\n>>> Download QRUPDATE $(QRUPDATE_VER) <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"http://downloads.sourceforge.net/project/qrupdate/qrupdate/1.2/qrupdate-$(QRUPDATE_VER).tar.gz"

$(INSTALL_DIR)/lib/libqrupdate.so: \
	$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so
	@echo -e "\n>>> Untar QRUPDATE $(QRUPDATE_VER) <<<\n"
	cd $(BUILD_DIR) && tar -xf $<
	# build and install library
	cd $(BUILD_DIR)/qrupdate-$(QRUPDATE_VER) \
	&& $(MAKE) test $(QRUPDATE_CONFIG_FLAGS) \
	&& $(SUDO_INSTALL) $(MAKE) install $(QRUPDATE_CONFIG_FLAGS)

qrupdate: $(INSTALL_DIR)/lib/libqrupdate.so


################################################################################
#
#   ARPACK-NG  - https://github.com/opencollab/arpack-ng
#
#   The ARPACK-NG library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

ARPACK-NG_VER ?= 3.7.0

$(SRC_CACHE)/arpack-ng-$(ARPACK-NG_VER).tar.gz:
	@echo -e "\n>>> Download ARPACK-NG $(ARPACK-NG_VER) <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://github.com/opencollab/arpack-ng/archive/$(ARPACK-NG_VER).tar.gz" \
	                && mv $(ARPACK-NG_VER).tar.gz $@

$(INSTALL_DIR)/lib/libarpack.so: \
	$(SRC_CACHE)/arpack-ng-$(ARPACK-NG_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so
	@echo -e "\n>>> Untar ARPACK-NG $(ARPACK-NG_VER) <<<\n"
	cd $(BUILD_DIR) && tar -xf $<
	# build and install library
	cd $(BUILD_DIR)/arpack-ng-$(ARPACK-NG_VER) \
	&& ./bootstrap \
	&& ./configure --prefix=$(INSTALL_DIR) \
	               --libdir=$(INSTALL_DIR)/lib \
	               --with-blas='-lopenblas' \
	               --with-lapack='' \
	               INTERFACE64=1 \
	               LT_SYS_LIBRARY_PATH=$(INSTALL_DIR)/lib \
	               LDFLAGS='-L$(INSTALL_DIR)/lib' \
	&& $(MAKE) check \
	&& $(SUDO_INSTALL) $(MAKE) install

arpack-ng: $(INSTALL_DIR)/lib/libarpack.so


################################################################################
#
#   (Optional) GLPK  - https://www.gnu.org/software/glpk/
#
#   The GLPK library will be build from a specific version, because Debian
#   systems make SuiteSparse a requirements for GLPK.
#
################################################################################

GLPK_VER ?= 4.65

$(SRC_CACHE)/glpk-$(GLPK_VER).tar.gz:
	@echo -e "\n>>> Download GLPK $(GLPK_VER) <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://ftpmirror.gnu.org/glpk/glpk-$(GLPK_VER).tar.gz"

$(INSTALL_DIR)/lib/libglpk.so: \
	$(SRC_CACHE)/glpk-$(GLPK_VER).tar.gz
	@echo -e "\n>>> Untar GLPK $(GLPK_VER) <<<\n"
	cd $(BUILD_DIR) && tar -xf $<
	# build and install library
	cd $(BUILD_DIR)/glpk-$(GLPK_VER) \
	&& ./configure --with-gmp \
	               --prefix=$(INSTALL_DIR) \
	               --libdir=$(INSTALL_DIR)/lib \
	&& $(MAKE) check \
	&& $(SUDO_INSTALL) $(MAKE) install

glpk: $(INSTALL_DIR)/lib/libglpk.so


################################################################################
#
#   GNU Octave  - http://www.gnu.org/software/octave/
#
#   Build GNU Octave using --enable-64 and all requirements.
#
################################################################################

OCTAVE_VER ?= 5.2.0

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
	cd $(SRC_CACHE) && wget -q \
	"https://ftpmirror.gnu.org/octave/octave-$(OCTAVE_VER).tar.gz"

$(INSTALL_DIR)/bin/octave-$(OCTAVE_VER): \
	$(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas.so \
	$(INSTALL_DIR)/lib/libsuitesparseconfig.so \
	$(INSTALL_DIR)/lib/libqrupdate.so \
	$(INSTALL_DIR)/lib/libarpack.so
	@echo -e "\n>>> Untar GNU Octave $(OCTAVE_VER) <<<\n"
	mkdir -p $(BUILD_DIR)/octave-$(OCTAVE_VER)
	cd $(BUILD_DIR) && tar -xf $<
	@echo -e "\n>>> Configure GNU Octave $(OCTAVE_VER) (1/3) <<<\n"
	cd $(BUILD_DIR)/octave-$(OCTAVE_VER) \
	&& ./configure $(OCTAVE_CONFIG_FLAGS)
	@echo -e "\n>>> Build GNU Octave $(OCTAVE_VER) (2/3) <<<\n"
	cd $(BUILD_DIR)/octave-$(OCTAVE_VER) \
	&& $(SUDO_INSTALL) $(MAKE) install
	@echo -e "\n>>> Check GNU Octave $(OCTAVE_VER) (3/3) <<<\n"
	cd $(BUILD_DIR)/octave-$(OCTAVE_VER) \
	&& $(MAKE) check LD_LIBRARY_PATH='$(INSTALL_DIR)/lib'

octave: $(INSTALL_DIR)/bin/octave-$(OCTAVE_VER)
	@echo -e "\n\n"
	@echo -e " >>> Finished building GNU Octave $(OCTAVE_VER)"
	@echo -e " with 64-bit libraries!!! <<<"
	@echo -e "\n  To start GNU Octave run:\n\n    $<\n\n"
