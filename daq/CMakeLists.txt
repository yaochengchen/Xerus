cmake_minimum_required (VERSION 2.6)

project (PicoScope)
# The version number.
set (PicoScope_VERSION_MAJOR 0)
set (PicoScope_VERSION_MINOR 4)

# You need to tell CMake where to find the ROOT installation. This can be done in a number of ways:
#   - ROOT built with classic configure/make use the provided $ROOTSYS/etc/cmake/FindROOT.cmake
#   - ROOT built with CMake. Add in CMAKE_PREFIX_PATH the installation prefix for ROOT
#list(APPEND CMAKE_PREFIX_PATH $ENV{ROOTSYS}/etc/cmake)
list(APPEND CMAKE_MODULE_PATH $ENV{ROOTSYS}/etc/cmake)

#---Locate the ROOT package and defines a number of variables (e.g. ROOT_INCLUDE_DIRS)
find_package(ROOT REQUIRED COMPONENTS MathCore RIO Hist Tree Net)

include_directories(${CMAKE_SOURCE_DIR} ${ROOT_INCLUDE_DIRS})
add_definitions(${ROOT_CXX_FLAGS})

# Project sources and libraries
include_directories ("${PROJECT_SOURCE_DIR}/include")

if (MINGW)
    link_directories("${PROJECT_SOURCE_DIR}/lib")
else()
    # TODO: proper path
    link_directories("/opt/picoscope/lib")
endif (MINGW)
			   
#add_executable(ps6000con src/ps6000con.c)

add_executable(
  ps6000conT4 
  src/ps6000conT4.cpp
  include/TarogeDAQConstant.h
  include/SaveTriggerRate.h
#  include/read_char.h
#  src/read_char.cc 
  include/fileSerial.h 
  src/fileSerial.cc 
  #src/scantty.h
  #src/scantty.cc
  include/checkDate.h
  src/checkDate.cc)


if (MINGW)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libgcc")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")
    set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "${CMAKE_SHARED_LIBRARY_LINK_C_FLAGS} -static-libgcc -s")
    set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS} -static-libgcc -static-libstdc++ -s")
endif (MINGW)

set (EXTRA_LIBS ${EXTRA_LIBS} -lps6000)

#target_link_libraries (ps6000con ${EXTRA_LIBS})
target_link_libraries (ps6000conT4 ${EXTRA_LIBS} ${ROOT_LIBRARIES})
#target_link_libraries (ACM ${EXTRA_LIBS})

# CMAKE_EXECUTABLE_SUFFIX

#install (TARGETS ps6000con DESTINATION bin)
install (TARGETS ps6000conT4 DESTINATION bin)
#install (TARGETS ACM DESTINATION bin)

# CMAKE_CXX_COMPILER=i386-mingw32-g++
