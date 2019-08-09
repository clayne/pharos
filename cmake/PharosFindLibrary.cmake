macro(_pfl_create_import)
  set(found "${${PREFIX}_FOUND}")
  if (found)
    set("${PREFIX}_FOUND" TRUE PARENT_SCOPE)
    set("${PREFIX}_INCLUDE_DIRS" "${${PREFIX}_INCLUDE_DIR}" PARENT_SCOPE)
    if (NOT "${PREFIX}_LIBRARIES")
      set("${PREFIX}_LIBRARIES" "${${PREFIX}_LIBRARY}" PARENT_SCOPE)
    endif()
    if (NOT TARGET ${IMPORTNAME})
      add_library("${IMPORTNAME}" UNKNOWN IMPORTED)
      set_target_properties("${IMPORTNAME}" PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${${PREFIX}_INCLUDE_DIR}"
        IMPORTED_LOCATION "${${PREFIX}_LIBRARY}")
    endif()
  endif()
endmacro()

function(pharos_find_library PREFIX IMPORTNAME)
  set(options DYNAMIC STATIC)
  set(oneValueArgs LIBRARY INCLUDE PKGCONFIG)
  cmake_parse_arguments(var "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if (NOT var_LIBRARY)
    message(FATAL_ERROR "pharos_find_library: called without LIBRARY")
  endif()
  if (NOT var_INCLUDE)
    message(FATAL_ERROR "pharos_find_library: called without INCLUDE")
  endif()

  set(prefixes)
  set(normal_search)

  if(${PREFIX}_ROOT)
    set(search_prefix PATHS ${${PREFIX}_ROOT} NO_DEFAULT_PATH)
    list(APPEND prefixes search_prefix)
  else()
    find_package(PkgConfig)
    if (NOT var_PKGCONFIG)
      set(var_PKGCONFIG "${var_LIBRARY}")
    endif()
    pkg_check_modules(pc QUIET "${var_PKGCONFIG}")
    if (var_STATIC AND ((NOT var_DYNAMIC) OR (NOT pc_FOUND)))
      foreach(name FOUND PREFIX)
        set(pc_${name} ${pc_static_${name}})
      endforeach()
    endif()
    if (pc_FOUND)
      set(search_prefix PATHS ${pc_PREFIX} NO_DEFAULT_PATH)
      list(APPEND prefixes search_prefix)
    endif()
  endif()
  list(APPEND prefixes normal_search)

  if(var_STATIC AND var_DYNAMIC)
    set(libname "${var_LIBRARY}")
  elseif(var_STATIC)
    set(libname "${CMAKE_STATIC_LIBRARY_PREFIX}${var_LIBRARY}${CMAKE_STATIC_LIBRARY_SUFFIX}")
    #message(STATUS "pharos_find_library: looking for static library ${libname}")
  elseif(var_DYNAMIC)
    set(libname "${CMAKE_SHARED_LIBRARY_PREFIX}${var_LIBRARY}${CMAKE_SHARED_LIBRARY_SUFFIX}")
    #message(STATUS "pharos_find_library: looking for shared library ${libname}")
  else()
    set(libname "${var_LIBRARY}")
  endif()

  if (NOT "${PREFIX}_INCLUDE_DIR")
    foreach(search ${prefixes})
      find_path("${PREFIX}_INCLUDE_DIR" NAMES "${var_INCLUDE}" ${${search}}
        PATH_SUFFIXES include)
    endforeach()
  endif()

  if (NOT "${PREFIX}_LIBRARY")
    foreach(search ${prefixes})
      find_library("${PREFIX}_LIBRARY" NAMES "${libname}" ${${search}} PATH_SUFFIXES lib)
    endforeach()
  endif()

  mark_as_advanced("${PREFIX}_LIBRARY" "${PREFIX}_INCLUDE_DIR")

  find_package(PackageHandleStandardArgs)
  find_package_handle_standard_args("${PREFIX}"
    DEFAULT_MSG "${PREFIX}_INCLUDE_DIR" "${PREFIX}_LIBRARY")

  _pfl_create_import()

endfunction()