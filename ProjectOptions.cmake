include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(bew_cpp_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(bew_cpp_setup_options)
  option(bew_cpp_ENABLE_HARDENING "Enable hardening" ON)
  option(bew_cpp_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    bew_cpp_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    bew_cpp_ENABLE_HARDENING
    OFF)

  bew_cpp_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR bew_cpp_PACKAGING_MAINTAINER_MODE)
    option(bew_cpp_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(bew_cpp_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(bew_cpp_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(bew_cpp_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(bew_cpp_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(bew_cpp_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(bew_cpp_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(bew_cpp_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(bew_cpp_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(bew_cpp_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(bew_cpp_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(bew_cpp_ENABLE_PCH "Enable precompiled headers" OFF)
    option(bew_cpp_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(bew_cpp_ENABLE_IPO "Enable IPO/LTO" ON)
    option(bew_cpp_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(bew_cpp_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(bew_cpp_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(bew_cpp_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(bew_cpp_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(bew_cpp_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(bew_cpp_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(bew_cpp_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(bew_cpp_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(bew_cpp_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(bew_cpp_ENABLE_PCH "Enable precompiled headers" OFF)
    option(bew_cpp_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      bew_cpp_ENABLE_IPO
      bew_cpp_WARNINGS_AS_ERRORS
      bew_cpp_ENABLE_USER_LINKER
      bew_cpp_ENABLE_SANITIZER_ADDRESS
      bew_cpp_ENABLE_SANITIZER_LEAK
      bew_cpp_ENABLE_SANITIZER_UNDEFINED
      bew_cpp_ENABLE_SANITIZER_THREAD
      bew_cpp_ENABLE_SANITIZER_MEMORY
      bew_cpp_ENABLE_UNITY_BUILD
      bew_cpp_ENABLE_CLANG_TIDY
      bew_cpp_ENABLE_CPPCHECK
      bew_cpp_ENABLE_COVERAGE
      bew_cpp_ENABLE_PCH
      bew_cpp_ENABLE_CACHE)
  endif()

  bew_cpp_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (bew_cpp_ENABLE_SANITIZER_ADDRESS OR bew_cpp_ENABLE_SANITIZER_THREAD OR bew_cpp_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(bew_cpp_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(bew_cpp_global_options)
  if(bew_cpp_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    bew_cpp_enable_ipo()
  endif()

  bew_cpp_supports_sanitizers()

  if(bew_cpp_ENABLE_HARDENING AND bew_cpp_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR bew_cpp_ENABLE_SANITIZER_UNDEFINED
       OR bew_cpp_ENABLE_SANITIZER_ADDRESS
       OR bew_cpp_ENABLE_SANITIZER_THREAD
       OR bew_cpp_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${bew_cpp_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${bew_cpp_ENABLE_SANITIZER_UNDEFINED}")
    bew_cpp_enable_hardening(bew_cpp_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(bew_cpp_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(bew_cpp_warnings INTERFACE)
  add_library(bew_cpp_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  bew_cpp_set_project_warnings(
    bew_cpp_warnings
    ${bew_cpp_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(bew_cpp_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(bew_cpp_options)
  endif()

  include(cmake/Sanitizers.cmake)
  bew_cpp_enable_sanitizers(
    bew_cpp_options
    ${bew_cpp_ENABLE_SANITIZER_ADDRESS}
    ${bew_cpp_ENABLE_SANITIZER_LEAK}
    ${bew_cpp_ENABLE_SANITIZER_UNDEFINED}
    ${bew_cpp_ENABLE_SANITIZER_THREAD}
    ${bew_cpp_ENABLE_SANITIZER_MEMORY})

  set_target_properties(bew_cpp_options PROPERTIES UNITY_BUILD ${bew_cpp_ENABLE_UNITY_BUILD})

  if(bew_cpp_ENABLE_PCH)
    target_precompile_headers(
      bew_cpp_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(bew_cpp_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    bew_cpp_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(bew_cpp_ENABLE_CLANG_TIDY)
    bew_cpp_enable_clang_tidy(bew_cpp_options ${bew_cpp_WARNINGS_AS_ERRORS})
  endif()

  if(bew_cpp_ENABLE_CPPCHECK)
    bew_cpp_enable_cppcheck(${bew_cpp_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(bew_cpp_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    bew_cpp_enable_coverage(bew_cpp_options)
  endif()

  if(bew_cpp_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(bew_cpp_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(bew_cpp_ENABLE_HARDENING AND NOT bew_cpp_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR bew_cpp_ENABLE_SANITIZER_UNDEFINED
       OR bew_cpp_ENABLE_SANITIZER_ADDRESS
       OR bew_cpp_ENABLE_SANITIZER_THREAD
       OR bew_cpp_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    bew_cpp_enable_hardening(bew_cpp_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
