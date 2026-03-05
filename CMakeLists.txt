cmake_minimum_required(VERSION 3.20)

project(PoreBlazer VERSION 4.0 LANGUAGES Fortran)

option(PB_ENABLE_OPENMP "Enable OpenMP parallelization" ON)
option(PB_ENABLE_OPENACC "Enable OpenACC GPU acceleration (requires NVIDIA HPC SDK)" OFF)
option(PB_ENABLE_NATIVE_OPT "Enable -march=native for Release builds (GNU)" OFF)

# OpenACC and OpenMP are mutually exclusive
if(PB_ENABLE_OPENACC AND PB_ENABLE_OPENMP)
  message(FATAL_ERROR "PB_ENABLE_OPENACC and PB_ENABLE_OPENMP are mutually exclusive. Please enable only one.")
endif()

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
  target_compile_options(poreblazer PRIVATE -cpp -ffree-line-length-none)
  if(PB_ENABLE_NATIVE_OPT)
    target_compile_options(poreblazer PRIVATE "$<$<CONFIG:Release>:-march=native>")
  endif()
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
  target_compile_options(poreblazer PRIVATE -fpp)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
  target_compile_options(poreblazer PRIVATE -cpp -Mfreeform)
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

if(PB_ENABLE_OPENACC)
  # Check for NVIDIA HPC SDK (nvfortran compiler)
  if(NOT CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
    message(WARNING "PB_ENABLE_OPENACC=ON but nvfortran (NVIDIA HPC SDK) is recommended. Current compiler: ${CMAKE_Fortran_COMPILER_ID}")
  endif()

  # Add OpenACC compile flags
  target_compile_options(poreblazer PRIVATE -acc -Minfo=accel)

  # Link cuRAND library for GPU random number generation
  target_link_libraries(poreblazer PRIVATE -curand)

  # Define preprocessor macro for conditional compilation
  target_compile_definitions(poreblazer PRIVATE USE_OPENACC)

  # Add cuRAND utils source file
  target_sources(poreblazer PRIVATE src/curand_utils.f90)

  message(STATUS "OpenACC GPU acceleration enabled")
endif()

install(TARGETS poreblazer RUNTIME DESTINATION bin)
install(FILES src/UFF.atoms DESTINATION share/poreblazer)
