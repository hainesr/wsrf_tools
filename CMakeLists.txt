#
#  The RealityGrid Steering Library WSRF Tools
#
#  Copyright (c) 2002-2009, University of Manchester, United Kingdom.
#  All rights reserved.
#
#  This software is produced by Research Computing Services, University
#  of Manchester as part of the RealityGrid project and associated
#  follow on projects, funded by the EPSRC under grants GR/R67699/01,
#  GR/R67699/02, GR/T27488/01, EP/C536452/1, EP/D500028/1,
#  EP/F00561X/1.
#
#  LICENCE TERMS
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
#    * Neither the name of The University of Manchester nor the names
#      of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written
#      permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
#  Author: Robert Haines

project(REG_WSRF_TOOLS)

# cmake setup boiler-plate
cmake_minimum_required(VERSION 2.6)
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/CMake")

# version numbers
set(REG_WSRF_VERSION_MAJ 3)
set(REG_WSRF_VERSION_MIN 0)
set(REG_WSRF_VERSION_PAT 0)
set(REG_WSRF_VERSION
    "${REG_WRAP_VERSION_MAJ}.${REG_WRAP_VERSION_MIN}.${REG_WRAP_VERSION_PAT}")

# set output directories, or at least hide them.
if(NOT LIBRARY_OUTPUT_PATH)
  set(LIBRARY_OUTPUT_PATH "" CACHE INTERNAL "Hide output directory option for building libraries.")
endif(NOT LIBRARY_OUTPUT_PATH)
mark_as_advanced(LIBRARY_OUTPUT_PATH)
if(NOT EXECUTABLE_OUTPUT_PATH)
  set(EXECUTABLE_OUTPUT_PATH ${REG_WSRF_TOOLS_BINARY_DIR}/bin CACHE INTERNAL "Single output directory for building all executables.")
endif(NOT EXECUTABLE_OUTPUT_PATH)

#
# find the RealityGrid Steering Library and check version and features
#

find_package(RealityGrid REQUIRED)
include(${RealityGrid_USE_FILE})

if(NOT ${REG_LIB_VERSION_MAJ} EQUAL ${REG_WSRF_VERSION_MAJ})
  message(FATAL_ERROR "Steering Library version mismatch. You can not use these tools (version ${REG_WSRF_VERSION}) with the selected Steering Library (version ${REG_STEER_LIB_VERSION}).")
else(NOT ${REG_LIB_VERSION_MAJ} EQUAL ${REG_WSRF_VERSION_MAJ})
  if(NOT ${REG_LIB_VERSION_MIN} EQUAL ${REG_WSRF_VERSION_MIN})
    message("Steering Library version mismatch. You may encounter problems using these tools (version ${REG_WSRF_VERSION}) with the selected Steering Library (version ${REG_STEER_LIB_VERSION}).")
  endif(NOT ${REG_LIB_VERSION_MIN} EQUAL ${REG_WSRF_VERSION_MIN})
endif(NOT ${REG_LIB_VERSION_MAJ} EQUAL ${REG_WSRF_VERSION_MAJ})

include(RealityGridCheckFeatures)
require_module(Steering WSRF)

#
# set up install location
#

# optionally install into the current ReG location
# if not building against a build tree install
if(${RealityGrid_INSTALL_TYPE} MATCHES "install")
  option(REG_WSRF_TOOLS_INSTALL_TO_REG_DIR
    "Install the tools to the same location as the RealityGrid installation that they are being built for?"
    OFF
  )
endif(${RealityGrid_INSTALL_TYPE} MATCHES "install")

if(REG_WSRF_TOOLS_INSTALL_TO_REG_DIR)
  set(CMAKE_INSTALL_PREFIX ${RealityGrid_INSTALL_PREFIX}
    CACHE PATH
    "Install path prefix, prepended onto install directories. The default setting is to install the wrappers to the same location as the RealityGrid installation that they are being built for."
    FORCE
  )

  string(
    REPLACE "${RealityGrid_INSTALL_PREFIX}/" "" REG_WSRF_TOOLS_BIN_INSTALL
    ${RealityGrid_BIN_DIR}
  )
else(REG_WSRF_TOOLS_INSTALL_TO_REG_DIR)
  set(REG_WSRF_TOOLS_BIN_INSTALL "bin")
endif(REG_WSRF_TOOLS_INSTALL_TO_REG_DIR)

#
# build the C tools
#
add_subdirectory(C)
