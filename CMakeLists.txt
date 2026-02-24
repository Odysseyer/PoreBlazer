cmake_minimum_required(VERSION 3.20)

project(PoreBlazer VERSION 4.0 LANGUAGES Fortran)

option(PB_ENABLE_OPENMP "Enable OpenMP parallelization" ON)
option(PB_ENABLE_NATIVE_OPT "Enable -march=native for Release builds (GNU)" OFF)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(PB_SOURCES
  src/defaults.f90
  src/percolation.f90
  src/utils.f90
  src/matrixops.f90
  src/random.f90
  src/vector.f90
  src/matrix.f90
  src/fundcell.f90
  src/poreblazer.f90
)

add_executable(poreblazer ${PB_SOURCES})

set_target_properties(poreblazer PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/mod"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  target_compile_options(poreblazer PRIVATE -cpp)
  if(PB_ENABLE_NATIVE_OPT)
    target_compile_options(poreblazer PRIVATE "$<$<CONFIG:Release>:-march=native>")
  endif()
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
  target_compile_options(poreblazer PRIVATE -fpp)
endif()

if(PB_ENABLE_OPENMP)
  find_package(OpenMP COMPONENTS Fortran)
  if(OpenMP_Fortran_FOUND)
    target_link_libraries(poreblazer PRIVATE OpenMP::OpenMP_Fortran)
    target_compile_definitions(poreblazer PRIVATE USE_OPENMP)
    message(STATUS "OpenMP support enabled")
  else()
    message(WARNING "PB_ENABLE_OPENMP=ON but OpenMP Fortran was not found. Building without OpenMP.")
  endif()
endif()

install(TARGETS poreblazer RUNTIME DESTINATION bin)
install(FILES src/UFF.atoms DESTINATION share/poreblazer)
