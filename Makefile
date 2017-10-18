#
#
#  BLIS    
#  An object-based framework for developing high-performance BLAS-like
#  libraries.
#
#  Copyright (C) 2014, The University of Texas at Austin
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are
#  met:
#   - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   - Neither the name of The University of Texas at Austin nor the names
#     of its contributors may be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

#
# Makefile
#
# Field G. Van Zee
# 
# Top-level makefile for libflame linear algebra library.
#
#

#
# --- Makefile PHONY target definitions ----------------------------------------
#

.PHONY: all libs test install uninstall clean \
        check-env check-env-mk check-env-fragments check-env-make-defs \
        testsuite testsuite-run testsuite-bin \
        install-libs install-headers install-lib-symlinks \
        showconfig \
        cleanlib distclean cleanmk cleanleaves \
        changelog \
        uninstall-libs uninstall-headers uninstall-lib-symlinks \
        uninstall-old


#
# --- Helper functions ---------------------------------------------------------
#

# Define a function to declare pattern-specific CFLAGS variables. This
# function is called from within each make_defs.mk file.
#define pattern-spec-cflags
#$(BASE_OBJ_PATH)/%-$(1).o: CFLAGS := $(CKOPTFLAGS) $(CVECFLAGS) \
#                                     $(CDBGFLAGS) $(CWARNFLAGS) $(CPICFLAGS) \
#                                     $(CTHREADFLAGS) $(CMISCFLAGS) $(CPPROCFLAGS) \
#                                     $(INCLUDE_PATHS) $(VERS_DEF)
#endef

# Define functions that filters a list of filepaths $(1) that contain (or
# omit) an arbitrary substring $(2).
files-that-contain      = $(strip $(foreach f, $(1), $(if $(findstring $(2),$(f)),$(f),)))
files-that-dont-contain = $(strip $(foreach f, $(1), $(if $(findstring $(2),$(f)),,$(f))))

# Define a function that stores the value of a variable to a different
# variable containing a specified suffix (corresponding to a configuration).
define store-var-for
$(strip $(1)).$(strip $(2)) := $($(strip $(1)))
endef

# Define a function that stores the value of all of the variables in a
# make_defs.mk file to other variables with the configuration (the
# argument $(1)) added as a suffix. This function is called once from
# each make_defs.mk. Also, add the configuration to CONFIGS_INCL.
define store-make-defs
$(eval $(call store-var-for,CC,         $(1)))
$(eval $(call store-var-for,CC_VENDOR,  $(1)))
$(eval $(call store-var-for,CPPROCFLAGS,$(1)))
$(eval $(call store-var-for,CMISCFLAGS, $(1)))
$(eval $(call store-var-for,CPICFLAGS,  $(1)))
$(eval $(call store-var-for,CWARNFLAGS, $(1)))
$(eval $(call store-var-for,CDBGFLAGS,  $(1)))
$(eval $(call store-var-for,COPTFLAGS,  $(1)))
$(eval $(call store-var-for,CKOPTFLAGS, $(1)))
$(eval $(call store-var-for,CVECFLAGS,  $(1)))
CONFIGS_INCL += $(1)
endef

# Define a function that retreives the value of a variable for a
# given configuration.
define load-var-for
$($(strip $(1)).$(strip $(2)))
endef




#
# --- Makefile initialization --------------------------------------------------
#

# The base name of the BLIS library that we will build.
BLIS_LIB_BASE_NAME := libblis

# Define the name of the common makefile.
COMMON_MK_FILE     := common.mk

# All makefile fragments in the tree will have this name.
FRAGMENT_MK        := .fragment.mk

# Locations of important files.
CONFIG_DIR         := config
FRAME_DIR          := frame
REFKERN_DIR        := ref_kernels
KERNELS_DIR        := kernels
BUILD_DIR          := build
OBJ_DIR            := obj
LIB_DIR            := lib
TESTSUITE_DIR      := testsuite

# Other kernel-related definitions.
KERNEL_SUFS        := c s S
KERNELS_STR        := kernels
REF_SUF            := ref

# The names of the testsuite binary executable and related default names
# of its input/configuration files.
TESTSUITE_NAME     := test_$(BLIS_LIB_BASE_NAME)
TESTSUITE_CONF_GEN := input.general
TESTSUITE_CONF_OPS := input.operations
TESTSUITE_OUT_FILE := output.testsuite

# CHANGELOG file.
CHANGELOG          := CHANGELOG



#
# --- Include common makefile --------------------------------------------------
#

# Include the configuration file.
-include $(COMMON_MK_FILE)

# Detect whether we actually got the configuration file. If we didn't, then
# it is likely that the user has not yet generated it (via configure).
ifeq ($(strip $(COMMON_MK_INCLUDED)),yes)
COMMON_MK_PRESENT := yes
else
COMMON_MK_PRESENT := no
endif

# Construct paths to the three primary directories of source code:
# general framework code, reference kernel code, and optimized kernel
# code.
CONFIG_PATH            := $(DIST_PATH)/$(CONFIG_DIR)
FRAME_PATH             := $(DIST_PATH)/$(FRAME_DIR)
REFKERN_PATH           := $(DIST_PATH)/$(REFKERN_DIR)
KERNELS_PATH           := $(DIST_PATH)/$(KERNELS_DIR)

# Construct the base object file path for the current configuration.
BASE_OBJ_PATH          := ./$(OBJ_DIR)/$(CONFIG_NAME)

# Construct base object file paths corresponding to the four locations
# of source code.
BASE_OBJ_CONFIG_PATH   := $(BASE_OBJ_PATH)/$(CONFIG_DIR)
BASE_OBJ_FRAME_PATH    := $(BASE_OBJ_PATH)/$(FRAME_DIR)
BASE_OBJ_REFKERN_PATH  := $(BASE_OBJ_PATH)/$(REFKERN_DIR)
BASE_OBJ_KERNELS_PATH  := $(BASE_OBJ_PATH)/$(KERNELS_DIR)

# Construct the base path for the library.
BASE_LIB_PATH          := ./$(LIB_DIR)/$(CONFIG_NAME)



#
# --- Main target variable definitions -----------------------------------------
#


# Construct the architecture-version string, which will be used to name the
# library upon installation.
VERS_CONF              := $(VERSION)-$(CONFIG_NAME)

# --- Library names ---

# Note: These names will be modified later to include the configuration and
# version strings.
BLIS_LIB_NAME          := $(BLIS_LIB_BASE_NAME).a
BLIS_DLL_NAME          := $(BLIS_LIB_BASE_NAME).so

# Append the base library path to the library names.
BLIS_LIB_PATH          := $(BASE_LIB_PATH)/$(BLIS_LIB_NAME)
BLIS_DLL_PATH          := $(BASE_LIB_PATH)/$(BLIS_DLL_NAME)

# --- BLIS framework source and object variable names ---

# These are the makefile variables that source code files will be accumulated
# into by the makefile fragments.
MK_CONFIG_SRC          :=
MK_FRAME_SRC           :=
MK_REFKERN_SRC         :=
MK_KERNELS_SRC         :=

# These hold object filenames corresponding to above.
MK_FRAME_OBJS          :=
MK_REFKERN_OBJS        :=
MK_KERNELS_OBJS        :=

# --- Define install target names for static libraries ---

MK_BLIS_LIB                  := $(BLIS_LIB_PATH)
MK_BLIS_LIB_INST             := $(patsubst $(BASE_LIB_PATH)/%.a, \
                                           $(INSTALL_PREFIX)/lib/%.a, \
                                           $(MK_BLIS_LIB))
MK_BLIS_LIB_INST_W_VERS_CONF := $(patsubst $(BASE_LIB_PATH)/%.a, \
                                           $(INSTALL_PREFIX)/lib/%-$(VERS_CONF).a, \
                                           $(MK_BLIS_LIB))

# --- Define install target names for shared libraries ---

MK_BLIS_DLL                  := $(BLIS_DLL_PATH)
MK_BLIS_DLL_INST             := $(patsubst $(BASE_LIB_PATH)/%.so, \
                                           $(INSTALL_PREFIX)/lib/%.so, \
                                           $(MK_BLIS_DLL))
MK_BLIS_DLL_INST_W_VERS_CONF := $(patsubst $(BASE_LIB_PATH)/%.so, \
                                           $(INSTALL_PREFIX)/lib/%-$(VERS_CONF).so, \
                                           $(MK_BLIS_DLL))

# --- Determine which libraries to build ---

MK_LIBS                           :=
MK_LIBS_INST                      :=
MK_LIBS_INST_W_VERS_CONF          :=

ifeq ($(BLIS_ENABLE_STATIC_BUILD),yes)
MK_LIBS                           += $(MK_BLIS_LIB)
MK_LIBS_INST                      += $(MK_BLIS_LIB_INST)
MK_LIBS_INST_W_VERS_CONF          += $(MK_BLIS_LIB_INST_W_VERS_CONF)
endif

ifeq ($(BLIS_ENABLE_DYNAMIC_BUILD),yes)
MK_LIBS                           += $(MK_BLIS_DLL)
MK_LIBS_INST                      += $(MK_BLIS_DLL_INST)
MK_LIBS_INST_W_VERS_CONF          += $(MK_BLIS_DLL_INST_W_VERS_CONF)
endif

# Strip leading, internal, and trailing whitespace.
MK_LIBS_INST                      := $(strip $(MK_LIBS_INST))
MK_LIBS_INST_W_VERS_CONF          := $(strip $(MK_LIBS_INST_W_VERS_CONF))

# Set the include directory names
MK_INCL_DIR_INST                  := $(INSTALL_PREFIX)/include/blis



#
# --- Include makefile fragments -----------------------------------------------
#

# Initialize our list of directory paths to makefile fragments with the empty
# list. This variable will accumulate all of the directory paths in which
# makefile fragments reside.
FRAGMENT_DIR_PATHS :=


# Construct paths to each of the sub-configurations specified in the
# configuration list. If CONFIG_NAME is not in CONFIG_LIST, include it in
# CONFIG_PATHS since we'll need access to its header files.
ifeq ($(findstring $(CONFIG_NAME),$(CONFIG_LIST)),)
CONFIG_PATHS       := $(addprefix $(CONFIG_PATH)/, $(CONFIG_NAME) $(CONFIG_LIST))
else
CONFIG_PATHS       := $(addprefix $(CONFIG_PATH)/, $(CONFIG_LIST))
endif

# This variable is used by the include statements as they recursively include
# one another. For the 'config' directory, we initialize it to that directory
# in preparation to include the fragments in the configuration sub-directory.
PARENT_PATH        := $(DIST_PATH)/$(CONFIG_DIR)

# Recursively include the makefile fragments in each of the sub-configuration
# directories.
-include $(addsuffix /$(FRAGMENT_MK), $(CONFIG_PATHS))


# Construct paths to each of the kernel sets required by the sub-configurations
# in the configuration list.
KERNEL_PATHS       := $(addprefix $(KERNELS_PATH)/, $(KERNEL_LIST))

# This variable is used by the include statements as they recursively include
# one another. For the 'kernels' directory, we initialize it to that directory
# in preparation to include the fragments in the configuration sub-directory.
PARENT_PATH        := $(DIST_PATH)/$(KERNELS_DIR)

# Recursively include the makefile fragments in each of the kernels sub-
# directories.
-include $(addsuffix /$(FRAGMENT_MK), $(KERNEL_PATHS))


# This variable is used by the include statements as they recursively include
# one another. For the framework and reference kernel source trees (ie: the
# 'frame' and 'ref_kernels' directories), we initialize it to the top-level
# directory since that is its parent. Same for the kernels directory, since it
# resides in the same top-level directory.
PARENT_PATH        := $(DIST_PATH)

# Recursively include all the makefile fragments in the directories for the
# reference kernels and portable framework.
-include $(addsuffix /$(FRAGMENT_MK), $(REFKERN_PATH))
-include $(addsuffix /$(FRAGMENT_MK), $(FRAME_PATH))


# Create a list of the makefile fragments.
MAKEFILE_FRAGMENTS := $(addsuffix /$(FRAGMENT_MK), $(FRAGMENT_DIR_PATHS))

# Detect whether we actually got any makefile fragments. If we didn't, then it
# is likely that the user has not yet generated them (via configure).
ifeq ($(strip $(MAKEFILE_FRAGMENTS)),)
MAKEFILE_FRAGMENTS_PRESENT := no
else
MAKEFILE_FRAGMENTS_PRESENT := yes
endif



#
# --- Compiler include path definitions ----------------------------------------
#

# Expand the fragment paths that contain .h files to attain the set of header
# files present in all fragment paths.
MK_HEADER_FILES := $(foreach frag_path, . $(FRAGMENT_DIR_PATHS), \
                                        $(wildcard $(frag_path)/*.h))

# Strip the leading, internal, and trailing whitespace from our list of header
# files. This makes the "make install-headers" much more readable.
MK_HEADER_FILES := $(strip $(MK_HEADER_FILES))

# Expand the fragment paths that contain .h files, and take the first
# expansion. Then, strip the header filename to leave the path to each header
# location. Notice this process even weeds out duplicates!
MK_HEADER_DIR_PATHS := $(dir $(foreach frag_path, . $(FRAGMENT_DIR_PATHS), \
                                       $(firstword $(wildcard $(frag_path)/*.h))))

# Add -I to each header path so we can specify our include search paths to the
# C compiler.
INCLUDE_PATHS   := $(strip $(patsubst %, -I%, $(MK_HEADER_DIR_PATHS)))



#
# --- Special preprocessor macro definitions -----------------------------------
#

# Define a C preprocessor macro to communicate the current version so that it
# can be embedded into the library and queried later.
VERS_DEF       := -DBLIS_VERSION_STRING=\"$(VERSION)\"



#
# --- Library object definitions -----------------------------------------------
#

# In this section, we will isolate the relevant source code filepaths and
# convert them to lists of object filepaths. Relevant source code falls into
# four categories: configuration source; architecture-specific kernel source;
# reference kernel source; and general framework source.

# $(call gen-obj-paths-from-src file_exts, src_files, base_src_path, base_obj_path)
#gen-obj-paths-from-src = $(foreach ch, $(1), \
#                             $(patsubst $(3)/%.$(ch), \
#                                        $(4)/%.o, \
#                                        $(2) \
#                              ) \
#                          )

# First, identify the source code found in the configuration sub-directories.
MK_CONFIG_C          := $(filter %.c, $(MK_CONFIG_SRC))
MK_CONFIG_S          := $(filter %.s, $(MK_CONFIG_SRC))
MK_CONFIG_SS         := $(filter %.S, $(MK_CONFIG_SRC))
MK_CONFIG_C_OBJS     := $(patsubst $(CONFIG_PATH)/%.c, $(BASE_OBJ_CONFIG_PATH)/%.o, \
                                   $(MK_CONFIG_C) \
                         )
MK_CONFIG_S_OBJS     := $(patsubst $(CONFIG_PATH)/%.s, $(BASE_OBJ_CONFIG_PATH)/%.o, \
                                   $(MK_CONFIG_S) \
                         )
MK_CONFIG_SS_OBJS    := $(patsubst $(CONFIG_PATH)/%.S, $(BASE_OBJ_CONFIG_PATH)/%.o, \
                                   $(MK_CONFIG_SS) \
                         )
MK_CONFIG_OBJS       := $(MK_CONFIG_C_OBJS) \
                        $(MK_CONFIG_S_OBJS) \
                        $(MK_CONFIG_SS_OBJS)

# A more concise but obfuscated way of encoding the above lines.
#MK_CONFIG_OBJS       := $(call gen-obj-paths-from-src c s S,
#                                                      $(MK_CONFIG_SRC),
#                                                      $(CONFIG_PATH),
#                                                      $(BASE_OBJ_CONFIG_PATH)
#                         )

# Now, identify all of the architecture-specific kernel source code. We
# start by filtering only .c and .[sS] files (ignoring any .h files, though
# there shouldn't be any), and then instantiating object file paths from the
# source file paths. Note that MK_KERNELS_SRC is already limited to the
# kernel source corresponding to the kernel sets in KERNEL_LIST. This
# is because the configure script only propogated makefile fragments into
# those specific kernel subdirectories.
MK_KERNELS_C       := $(filter %.c, $(MK_KERNELS_SRC))
MK_KERNELS_S       := $(filter %.s, $(MK_KERNELS_SRC))
MK_KERNELS_SS      := $(filter %.S, $(MK_KERNELS_SRC))
MK_KERNELS_C_OBJS  := $(patsubst $(KERNELS_PATH)/%.c, $(BASE_OBJ_KERNELS_PATH)/%.o, \
                                 $(MK_KERNELS_C) \
                       )
MK_KERNELS_S_OBJS  := $(patsubst $(KERNELS_PATH)/%.s, $(BASE_OBJ_KERNELS_PATH)/%.o, \
                                 $(MK_KERNELS_S) \
                       )
MK_KERNELS_SS_OBJS := $(patsubst $(KERNELS_PATH)/%.S, $(BASE_OBJ_KERNELS_PATH)/%.o, \
                                 $(MK_KERNELS_SS) \
                       )
MK_KERNELS_OBJS    := $(MK_KERNELS_C_OBJS) \
                      $(MK_KERNELS_S_OBJS) \
                      $(MK_KERNELS_SS_OBJS)

# Next, identify all of the reference kernel source code, then filter only
# .c files (ignoring .h files), and finally instantiate object file paths
# from the source files paths once for each sub-configuration in CONFIG_LIST,
# appending the name of the sub-config to the object filename.
MK_REFKERN_C       := $(filter %.c, $(MK_REFKERN_SRC))
MK_REFKERN_OBJS    := $(foreach arch, $(CONFIG_LIST), \
                          $(patsubst $(REFKERN_PATH)/%_$(REF_SUF).c, \
                                     $(BASE_OBJ_REFKERN_PATH)/$(arch)/%_$(arch)_$(REF_SUF).o, \
                                     $(MK_REFKERN_C) \
                           ) \
                       )

# And now, identify all of the portable framework source code, then filter
# only .c files (ignoring .h files), and finally instantiate object file
# paths from the source file paths.
MK_FRAME_C         := $(filter %.c, $(MK_FRAME_SRC))
MK_FRAME_OBJS      := $(patsubst $(FRAME_PATH)/%.c, $(BASE_OBJ_FRAME_PATH)/%.o, \
                                 $(MK_FRAME_C) \
                       )

# Combine all of the object files into some readily-accessible variables.
MK_BLIS_OBJS         := $(MK_CONFIG_OBJS) \
                        $(MK_KERNELS_OBJS) \
                        $(MK_REFKERN_OBJS) \
                        $(MK_FRAME_OBJS)

# Optionally filter out the BLAS and CBLAS compatibility layer object files.
# This is not actually necessary, since each affected file is guarded by C
# preprocessor macros, but it but prevents "empty" object files from being
# added into the library (and reduces compilation time).
BASE_OBJ_BLAS_PATH   := $(BASE_OBJ_FRAME_PATH)/compat
BASE_OBJ_CBLAS_PATH  := $(BASE_OBJ_FRAME_PATH)/compat/cblas
ifeq ($(BLIS_ENABLE_CBLAS),no)
MK_BLIS_OBJS         := $(filter-out $(BASE_OBJ_CBLAS_PATH)/%.o, $(MK_BLIS_OBJS) )
endif
ifeq ($(BLIS_ENABLE_BLAS2BLIS),no)
MK_BLIS_OBJS         := $(filter-out $(BASE_OBJ_BLAS_PATH)/%.o,  $(MK_BLIS_OBJS) )
endif



#
# --- Test suite definitions ---------------------------------------------------
#

# The location of the test suite's general and operations-specific
# input/configuration files.
TESTSUITE_CONF_GEN_PATH := $(DIST_PATH)/$(TESTSUITE_DIR)/$(TESTSUITE_CONF_GEN)
TESTSUITE_CONF_OPS_PATH := $(DIST_PATH)/$(TESTSUITE_DIR)/$(TESTSUITE_CONF_OPS)

# The locations of the test suite source directory and the local object
# directory.
TESTSUITE_SRC_PATH      := $(DIST_PATH)/$(TESTSUITE_DIR)/src
BASE_OBJ_TESTSUITE_PATH := $(BASE_OBJ_PATH)/$(TESTSUITE_DIR)

# Convert source file paths to object file paths by replacing the base source
# directories with the base object directories, and also replacing the source
# file suffix (eg: '.c') with '.o'.
MK_TESTSUITE_OBJS       := $(patsubst $(TESTSUITE_SRC_PATH)/%.c, \
                                      $(BASE_OBJ_TESTSUITE_PATH)/%.o, \
                                      $(wildcard $(TESTSUITE_SRC_PATH)/*.c))

# The test suite binary executable filename.
ifeq ($(CONFIG_NAME),pnacl)
# Linked executable
MK_TESTSUITE_BIN_UNSTABLE := $(BASE_OBJ_TESTSUITE_PATH)/test_libblis.unstable.pexe
# Finalized executable
MK_TESTSUITE_BIN_PNACL    := $(BASE_OBJ_TESTSUITE_PATH)/test_libblis.pexe
# Translated executable (for x86-64)
TESTSUITE_BIN             := test_libblis.x86-64.nexe
else
ifeq ($(CONFIG_NAME),emscripten)
# JS script name.
TESTSUITE_BIN             := test_libblis.js
else
# Binary executable name.
TESTSUITE_BIN             := test_libblis.x
endif # emscripten
endif # pnacl



#
# --- Uninstall definitions ----------------------------------------------------
#

# This shell command grabs all files named "libblis-*.a" or "libblis-*.so" in
# the installation directory and then filters out the name of the library
# archive for the current version/configuration. We consider this remaining set
# of libraries to be "old" and eligible for removal upon running of the
# uninstall-old target.
UNINSTALL_LIBS   := $(shell $(FIND) $(INSTALL_PREFIX)/lib/ -name "$(BLIS_LIB_BASE_NAME)-*.[a|so]" 2> /dev/null | $(GREP) -v "$(BLIS_LIB_BASE_NAME)-$(VERS_CONF).[a|so]" | $(GREP) -v $(BLIS_LIB_NAME))



#
# --- Targets/rules ------------------------------------------------------------
#

# --- Primary targets ---

all: libs

libs: blis-lib

test: testsuite

install: libs install-libs install-headers install-lib-symlinks

uninstall: uninstall-libs uninstall-lib-symlinks uninstall-headers

clean: cleanlib cleantest


# --- General source code / object code rules ---

# Define some functions that return the appropriate CFLAGS for a given
# configuration. This assumes that the make_defs.mk files have already been
# included, which results in those values having been stored to
# configuration-qualified variables.

get-noopt-cflags-for   = $(call load-var-for,CDBGFLAGS,$(1)) \
                         $(call load-var-for,CWARNFLAGS,$(1)) \
                         $(call load-var-for,CPICFLAGS,$(1)) \
                         $(call load-var-for,CMISCFLAGS,$(1)) \
                         $(call load-var-for,CPPROCFLAGS,$(1)) \
                         $(CTHREADFLAGS) \
                         $(INCLUDE_PATHS) $(VERS_DEF)

get-kernel-cflags-for  = $(call load-var-for,CKOPTFLAGS,$(1)) \
                         $(call load-var-for,CVECFLAGS,$(1)) \
                         $(call get-noopt-cflags-for,$(1))

get-refkern-cflags-for = $(call get-kernel-cflags-for,$(1)) \
                         -DBLIS_CNAME=$(1)

get-frame-cflags-for   = $(call load-var-for,COPTFLAGS,$(1)) \
                         $(call load-var-for,CVECFLAGS,$(1)) \
                         $(call get-noopt-cflags-for,$(1))

get-config-cflags-for  = $(call get-kernel-cflags-for,$(1))

get-noopt-text       = "(CFLAGS for no optimization)"
get-kernel-text-for  = "('$(1)' CFLAGS for kernels)"
get-refkern-text-for = "('$(1)' CFLAGS for ref. kernels)"
get-frame-text-for   = "('$(1)' CFLAGS for framework code)"
get-config-text-for  = "('$(1)' CFLAGS for config code)"


# FGVZ: Add support for compiling .s and .S files in 'config'/'kernels'
# directories.
#  - May want to add an extra foreach loop around function eval/call.

# first argument: a configuration name from config_list, used to look up the
# CFLAGS to use during compilation.
define make-config-rule
$(BASE_OBJ_CONFIG_PATH)/$(1)/%.o: $(CONFIG_PATH)/$(1)/%.c $(MK_HEADER_FILES) $(MAKE_DEFS_MK_PATHS)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(CC) $(call get-config-cflags-for,$(1)) -c $$< -o $$@
else
	@echo "Compiling $$@" $(call get-config-text-for,$(1))
	@$(CC) $(call get-config-cflags-for,$(1)) -c $$< -o $$@
endif
endef

# first argument: a configuration name from the union of config_list and
# config_name, used to look up the CFLAGS to use during compilation.
define make-frame-rule
$(BASE_OBJ_FRAME_PATH)/%.o: $(FRAME_PATH)/%.c $(MK_HEADER_FILES) $(MAKE_DEFS_MK_PATHS)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(CC) $(call get-frame-cflags-for,$(1)) -c $$< -o $$@
else
	@echo "Compiling $$@" $(call get-frame-text-for,$(1))
	@$(CC) $(call get-frame-cflags-for,$(1)) -c $$< -o $$@
endif
endef

# first argument: a kernel set (name) being targeted (e.g. haswell).
define make-refkern-rule
$(BASE_OBJ_REFKERN_PATH)/$(1)/%_$(1)_ref.o: $(REFKERN_PATH)/%_ref.c $(MK_HEADER_FILES) $(MAKE_DEFS_MK_PATHS)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(CC) $(call get-refkern-cflags-for,$(1)) -c $$< -o $$@
else
	@echo "Compiling $$@" $(call get-refkern-text-for,$(1))
	@$(CC) $(call get-refkern-cflags-for,$(1)) -c $$< -o $$@
endif
endef

# first argument: a kernel set (name) being targeted (e.g. haswell).
# second argument: the configuration whose CFLAGS we should use in compilation.
# third argument: the kernel file suffix being considered.
#$(BASE_OBJ_KERNELS_PATH)/$(1)/%.o: $(KERNELS_PATH)/$(1)/%.$(3) $(MK_HEADER_FILES) $(MAKE_DEFS_MK_PATHS)
define make-kernels-rule
$(BASE_OBJ_KERNELS_PATH)/$(1)/%.o: $(KERNELS_PATH)/$(1)/%.c $(MK_HEADER_FILES) $(MAKE_DEFS_MK_PATHS)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(CC) $(call get-kernel-cflags-for,$(2)) -c $$< -o $$@
else
	@echo "Compiling $$@" $(call get-kernel-text-for,$(1))
	@$(CC) $(call get-kernel-cflags-for,$(2)) -c $$< -o $$@
endif
endef

# Define functions to choose the correct sub-configuration name for the
# given kernel set. This function is called when instantiating the
# make-kernels-rule.
get-config-for-kset = $(lastword $(subst :, ,$(filter $(1):%,$(KCONFIG_MAP))))

# Instantiate the build rule for files in the configuration directory for
# each of the sub-configurations in CONFIG_LIST with the CFLAGS designated
# for that sub-configuration.
$(foreach conf, $(CONFIG_LIST), $(eval $(call make-config-rule,$(conf))))

# Instantiate the build rule for non-kernel framework files. Use the CFLAGS for
# the configuration family, which exists in the directory whose name is equal to
# CONFIG_NAME. (BTW: If it is a singleton family, then CONFIG_NAME is equal to
# CONFIG_LIST.)
#$(eval $(call make-frame-rule,$(firstword $(CONFIG_NAME))))
$(foreach conf, $(CONFIG_NAME), $(eval $(call make-frame-rule,$(conf))))

# Instantiate the build rule for reference kernels for each of the sub-
# configurations in CONFIG_LIST with the CFLAGS designated for that sub-
# configuration.
$(foreach conf, $(CONFIG_LIST), $(eval $(call make-refkern-rule,$(conf))))

$(info kernel list: $(KERNEL_LIST))
$(info getconfig:   $(call get-config-for-kset,haswell))
# Instantiate the build rule for optimized kernels for each of the kernel
# sets in KERNEL_LIST with the CFLAGS designated for the sub-configuration
# specified by the KCONFIG_MAP.
$(foreach kset, $(KERNEL_LIST), $(eval $(call make-kernels-rule,$(kset),$(call get-config-for-kset,$(kset)))))

# FGVZ: for later, to compile multiple kernel source suffixes.
#$(foreach suf,  $(KERNEL_SUFS), \
#$(foreach kset, $(KERNEL_LIST), $(eval $(call make-kernels-rule,$(kset),$(suf)))))



# --- Environment check rules ---

check-env: check-env-make-defs check-env-fragments check-env-mk

check-env-mk:
ifeq ($(CONFIG_MK_PRESENT),no)
	$(error Cannot proceed: config.mk not detected! Run configure first)
endif

check-env-fragments: check-env-mk
ifeq ($(MAKEFILE_FRAGMENTS_PRESENT),no)
	$(error Cannot proceed: makefile fragments not detected! Run configure first)
endif

check-env-make-defs: check-env-fragments
ifeq ($(ALL_MAKE_DEFS_MK_PRESENT),no)
	$(error Cannot proceed: Some make_defs.mk files not found or mislabeled!)
endif


# --- All-purpose library rule (static and shared) ---

blis-lib: check-env $(MK_LIBS)


# --- Static library archiver rules ---

$(MK_BLIS_LIB): $(MK_BLIS_OBJS)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(AR) $(ARFLAGS) $@ $?
	$(RANLIB) $@
else
	@echo "Archiving $@"
	@$(AR) $(ARFLAGS) $@ $?
	@$(RANLIB) $@
endif


# --- Dynamic library linker rules ---

$(MK_BLIS_DLL): $(MK_BLIS_OBJS)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(LINKER) $(SOFLAGS) $(LDFLAGS) -o $@ $?
else 
	@echo "Dynamically linking $@"
	@$(LINKER) $(SOFLAGS) $(LDFLAGS) -o $@ $?
endif


# --- Test suite rules ---

testsuite: testsuite-run

testsuite-bin: check-env $(TESTSUITE_BIN)

$(BASE_OBJ_TESTSUITE_PATH)/%.o: $(TESTSUITE_SRC_PATH)/%.c
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(CC) $(CFLAGS) -c $< -o $@
else
	@echo "Compiling $<"
	@$(CC) $(CFLAGS) -c $< -o $@
endif

ifeq ($(CONFIG_NAME),pnacl)

# Link executable (produces unstable LLVM bitcode)
$(MK_TESTSUITE_BIN_UNSTABLE): $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(LINKER) $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB) $(LDFLAGS) -o $@
else
	@echo "Linking $@ against '$(MK_BLIS_LIB) $(LDFLAGS)'"
	@$(LINKER) $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB) $(LDFLAGS) -o $@
endif

# Finalize PNaCl executable (i.e. convert from LLVM bitcode to PNaCl bitcode)
$(MK_TESTSUITE_BIN_PNACL): $(MK_TESTSUITE_BIN_UNSTABLE)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(FINALIZER) $(FINFLAGS) -o $@ $<
else
	@echo "Finalizing $@"
	@$(FINALIZER) $(FINFLAGS) -o $@ $<
endif

# Translate PNaCl executable to x86-64 NaCl executable
$(TESTSUITE_BIN): $(MK_TESTSUITE_BIN_PNACL)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(TRANSLATOR) $(TRNSFLAGS) $(TRNSAMD64FLAGS) $< -o $@
else
	@echo "Translating $< -> $@"
	@$(TRANSLATOR) $(TRNSFLAGS) $(TRNSAMD64FLAGS) $< -o $@
endif

else # Non-PNaCl case

ifeq ($(CONFIG_NAME),emscripten)
# Generate JavaScript and embed testsuite resources normally
$(TESTSUITE_BIN): $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB) $(TESTSUITE_CONF_GEN_PATH) $(TESTSUITE_CONF_OPS_PATH)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(LINKER) $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB) $(LDFLAGS) -o $@ \
		--embed-file $(TESTSUITE_CONF_GEN_PATH)@input.general \
		--embed-file $(TESTSUITE_CONF_OPS_PATH)@input.operations
else
	@echo "Linking $@ against '$(MK_BLIS_LIB) $(LDFLAGS)'"
	@$(LINKER) $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB) $(LDFLAGS) -o $@ \
		--embed-file $(TESTSUITE_CONF_GEN_PATH)@input.general \
		--embed-file $(TESTSUITE_CONF_OPS_PATH)@input.operations
endif
else
# Link executable normally
$(TESTSUITE_BIN): $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(LINKER) $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB) $(LDFLAGS) -o $@
else
	@echo "Linking $@ against '$(MK_BLIS_LIB) $(LDFLAGS)'"
	@$(LINKER) $(MK_TESTSUITE_OBJS) $(MK_BLIS_LIB) $(LDFLAGS) -o $@
endif
endif

endif

testsuite-run: testsuite-bin
ifeq ($(CONFIG_NAME),pnacl)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(NACL_SDK_ROOT)/tools/sel_ldr_x86_64 -a -c -q \
	    -B $(NACL_SDK_ROOT)/tools/irt_core_x86_64.nexe -- \
	    $(TESTSUITE_BIN) -g $(TESTSUITE_CONF_GEN_PATH) \
	                     -o $(TESTSUITE_CONF_OPS_PATH) \
                         > $(TESTSUITE_OUT_FILE)
else
	@echo "Running $(TESTSUITE_BIN) with output redirected to '$(TESTSUITE_OUT_FILE)'"
	@$(NACL_SDK_ROOT)/tools/sel_ldr_x86_64 -a -c -q \
	    -B $(NACL_SDK_ROOT)/tools/irt_core_x86_64.nexe -- \
	    $(TESTSUITE_BIN) -g $(TESTSUITE_CONF_GEN_PATH) \
	                     -o $(TESTSUITE_CONF_OPS_PATH) \
                         > $(TESTSUITE_OUT_FILE)
endif
else
ifeq ($(CONFIG_NAME),emscripten)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(JSINT) $(TESTSUITE_BIN)
else
	@echo "Running $(TESTSUITE_BIN)"
	@$(JSINT) $(TESTSUITE_BIN)
endif
else # non-pnacl, non-emscripten case
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	./$(TESTSUITE_BIN) -g $(TESTSUITE_CONF_GEN_PATH) \
	                   -o $(TESTSUITE_CONF_OPS_PATH) \
                        > $(TESTSUITE_OUT_FILE)

else ifeq ($(BLIS_ENABLE_TEST_OUTPUT), yes)
	./$(TESTSUITE_BIN) -g $(TESTSUITE_CONF_GEN_PATH) \
	                   -o $(TESTSUITE_CONF_OPS_PATH) | \
                        tee $(TESTSUITE_OUT_FILE)
else
	@echo "Running $(TESTSUITE_BIN) with output redirected to '$(TESTSUITE_OUT_FILE)'"
	@./$(TESTSUITE_BIN) -g $(TESTSUITE_CONF_GEN_PATH) \
	                    -o $(TESTSUITE_CONF_OPS_PATH) \
                         > $(TESTSUITE_OUT_FILE)
endif
endif # emscripten
endif # pnacl

# --- Install rules ---

install-libs: check-env $(MK_LIBS_INST_W_VERS_CONF)

install-headers: check-env $(MK_INCL_DIR_INST)

$(MK_INCL_DIR_INST): $(MK_HEADER_FILES) $(CONFIG_MK_FILE)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(MKDIR) $(@)
	$(INSTALL) -m 0644 $(MK_HEADER_FILES) $(@)
else
	@$(MKDIR) $(@)
	@echo "Installing C header files into $(@)/"
	@$(INSTALL) -m 0644 $(MK_HEADER_FILES) $(@)
endif

$(INSTALL_PREFIX)/lib/%-$(VERS_CONF).a: $(BASE_LIB_PATH)/%.a $(CONFIG_MK_FILE)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(MKDIR) $(@D)
	$(INSTALL) -m 0644 $< $@
else
	@echo "Installing $(@F) into $(INSTALL_PREFIX)/lib/"
	@$(MKDIR) $(@D)
	@$(INSTALL) -m 0644 $< $@
endif

$(INSTALL_PREFIX)/lib/%-$(VERS_CONF).so: $(BASE_LIB_PATH)/%.so $(CONFIG_MK_FILE)
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(MKDIR) $(@D)
	$(INSTALL) -m 0644 $< $@
else
	@echo "Installing $(@F) into $(INSTALL_PREFIX)/lib/"
	@$(MKDIR) $(@D)
	@$(INSTALL) -m 0644 $< $@
endif


# --- Install-symlinks rules ---

install-lib-symlinks: check-env $(MK_LIBS_INST)

$(INSTALL_PREFIX)/lib/%.a: $(INSTALL_PREFIX)/lib/%-$(VERS_CONF).a
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(SYMLINK) $(<F) $(@F)
	$(MV) $(@F) $(INSTALL_PREFIX)/lib/
else
	@echo "Installing symlink $(@F) into $(INSTALL_PREFIX)/lib/"
	@$(SYMLINK) $(<F) $(@F)
	@$(MV) $(@F) $(INSTALL_PREFIX)/lib/
endif

$(INSTALL_PREFIX)/lib/%.so: $(INSTALL_PREFIX)/lib/%-$(VERS_CONF).so
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	$(SYMLINK) $(<F) $(@F)
	$(MV) $(@F) $(INSTALL_PREFIX)/lib/
else
	@echo "Installing symlink $(@F) into $(INSTALL_PREFIX)/lib/"
	@$(SYMLINK) $(<F) $(@F)
	@$(MV) $(@F) $(INSTALL_PREFIX)/lib/
endif


# --- Query current configuration ---

showconfig: check-env
	@echo "Current configuration family ($(CONFIG_NAME)) supports the following"
	@echo "sub-configurations: $(CONFIG_LIST)"
	@echo "requisite kernels:  $(KERNEL_LIST)"


# --- Clean rules ---

cleanlib: check-env
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(FIND) $(BASE_OBJ_PATH) -name "*.o" | $(XARGS) $(RM_F)
	- $(FIND) $(BASE_LIB_PATH) -name "*.a" | $(XARGS) $(RM_F)
	- $(FIND) $(BASE_LIB_PATH) -name "*.so" | $(XARGS) $(RM_F)
else
	@echo "Removing .o files from $(BASE_OBJ_PATH)."
	@- $(FIND) $(BASE_OBJ_PATH) -name "*.o" | $(XARGS) $(RM_F)
	@echo "Removing .a files from $(BASE_LIB_PATH)."
	@- $(FIND) $(BASE_LIB_PATH) -name "*.a" | $(XARGS) $(RM_F)
	@echo "Removing .so files from $(BASE_LIB_PATH)."
	@- $(FIND) $(BASE_LIB_PATH) -name "*.so" | $(XARGS) $(RM_F)
endif

cleantest: check-env
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(FIND) $(BASE_OBJ_TESTSUITE_PATH) \( -name "*.o" -o -name "*.pexe" \) | $(XARGS) $(RM_F)
	- $(RM_RF) $(TESTSUITE_BIN)
else
	@echo "Removing object files from $(BASE_OBJ_TESTSUITE_PATH)."
	@- $(FIND) $(BASE_OBJ_TESTSUITE_PATH) \( -name "*.o" -o -name "*.pexe" \) | $(XARGS) $(RM_F)
	@echo "Removing $(TESTSUITE_BIN) binary."
	@- $(RM_RF) $(TESTSUITE_BIN)
endif

cleanmk: check-env
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(FIND) $(CONFIG_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
	- $(FIND) $(FRAME_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
	- $(FIND) $(REFKERN_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
	- $(FIND) $(KERNELS_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
else
	@echo "Removing makefile fragments from $(CONFIG_PATH)."
	@- $(FIND) $(CONFIG_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
	@echo "Removing makefile fragments from $(FRAME_PATH)."
	@- $(FIND) $(FRAME_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
	@echo "Removing makefile fragments from $(REFKERN_PATH)."
	@- $(FIND) $(REFERKN_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
	@echo "Removing makefile fragments from $(KERNELS_PATH)."
	@- $(FIND) $(KERNELS_PATH) -name "$(FRAGMENT_MK)" | $(XARGS) $(RM_F)
endif

distclean: check-env cleanmk cleanlib cleantest
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(RM_F) $(CONFIG_MK_FILE)
	- $(RM_RF) $(TESTSUITE_OUT_FILE)
	- $(RM_RF) $(OBJ_DIR)
	- $(RM_RF) $(LIB_DIR)
else
	@echo "Removing $(CONFIG_MK_FILE)."
	@- $(RM_F) $(CONFIG_MK_FILE)
	@echo "Removing $(TESTSUITE_OUT_FILE)."
	@- $(RM_F) $(TESTSUITE_OUT_FILE)
	@echo "Removing $(OBJ_DIR)."
	@- $(RM_RF) $(OBJ_DIR)
	@echo "Removing $(LIB_DIR)."
	@- $(RM_RF) $(LIB_DIR)
endif


# --- CHANGELOG rules ---

changelog: check-env
	@echo "Updating '$(DIST_PATH)/$(CHANGELOG)' via '$(GIT_LOG)'."
	@$(GIT_LOG) > $(DIST_PATH)/$(CHANGELOG) 


# --- Uninstall rules ---

uninstall-old: $(UNINSTALL_LIBS)

uninstall-libs: check-env
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(RM_F) $(MK_LIBS_INST_W_VERS_CONF)
else
	@echo "Removing $(MK_LIBS_INST_W_VERS_CONF)."
	@- $(RM_F) $(MK_LIBS_INST_W_VERS_CONF)
endif

uninstall-lib-symlinks: check-env
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(RM_F) $(MK_LIBS_INST)
else
	@echo "Removing $(MK_LIBS_INST)."
	@- $(RM_F) $(MK_LIBS_INST)
endif

uninstall-headers: check-env
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(RM_RF) $(MK_INCL_DIR_INST)
else
	@echo "Removing $(MK_INCL_DIR_INST)/."
	@- $(RM_RF) $(MK_INCL_DIR_INST)
endif

$(UNINSTALL_LIBS): check-env
ifeq ($(BLIS_ENABLE_VERBOSE_MAKE_OUTPUT),yes)
	- $(RM_F) $@
else
	@echo "Removing $(@F) from $(@D)/."
	@- $(RM_F) $@
endif


