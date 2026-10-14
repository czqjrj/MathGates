cmake_minimum_required(VERSION 3.20)
project(godot_math_tex LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()

# Godot 编辑器/导出会扫描工程内所有文件；构建依赖与中间产物目录很大，用 .gdignore
# 让编辑器跳过（否则第三方源码与 .obj 会被打进导出包）。这些目录本身不入库。
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/.gdignore "")
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/build/.gdignore "")
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/build-android/.gdignore "")

# Godot-cpp target: template_debug (matches windows.x86_64.debug in the
# .gdextension). The editor runs are debug builds.
set(GODOTCPP_TARGET template_debug CACHE STRING "godot-cpp target" FORCE)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/godot-cpp godot-cpp)

# Android: prebuilt cross-compiled static deps (freetype + tinyxml2 for arm64).
# MicroTeX links tinyxml2 by bare name through pkg-config, so its lib dir must
# be on the linker search path before the MicroTeX target is created.
if(ANDROID)
	set(MT_ANDROID_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/android_deps/install/arm64)
	link_directories(${MT_ANDROID_PREFIX}/lib)
	# MicroTeX compiles against <tinyxml2.h> but links tinyxml2 by bare name via
	# pkg-config, so its include dir is not propagated automatically.
	include_directories(${MT_ANDROID_PREFIX}/include)
endif()

# MicroTeX 的 CMakeLists 只有 QT/SKIA/WIN32/UNIX 四个平台分支，没有 ANDROID；
# NDK 交叉编译时 CMake 会把 UNIX 置为真，MicroTeX 便会 require GTK/Fontconfig 而配置失败。
# Android 下把 UNIX 置假，让它落到「unknown platform」中性分支（不引入任何平台源码）。
if(ANDROID)
	set(UNIX OFF)
endif()

# MicroTeX builds the LaTeX static library.
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/MicroTeX MicroTeX)
# The WIN32 sample executable is not needed; only build LaTeX.
if(TARGET LaTeXWin32Sample)
	set_target_properties(LaTeXWin32Sample PROPERTIES EXCLUDE_FROM_ALL TRUE)
endif()

find_package(PkgConfig REQUIRED)
pkg_check_modules(MTDEPS REQUIRED tinyxml2 freetype2)

add_library(godot_math_tex SHARED
	src/register_types.cpp
	src/math_tex.cpp
	src/backend.cpp
	src/font_ft.cpp
	src/surface.cpp
)

target_include_directories(godot_math_tex PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/src
	${CMAKE_CURRENT_SOURCE_DIR}/../third_party/MicroTeX/src
	${MTDEPS_INCLUDE_DIRS}
)

# Fully static link (no non-system DLL dependencies). Godot 4.4 loads
# GDExtensions with LOAD_LIBRARY_SEARCH_DEFAULT_DIRS, under which MinGW
# dependency DLLs (libstdc++-6.dll, libfreetype-6.dll, ...) are NOT found
# even when placed next to the extension DLL (Error 126). Linking the C/C++
# runtimes and all third-party libs statically removes every non-system
# dependency.
#
# Static FreeType chain (order-sensitive, from: pkgconf --libs --static freetype2).
# Explicit archive paths so CMake cannot resolve the names to .dll.a import libs.
set(MT_MINGW_ARCHIVES
	C:/msys64/mingw64/lib/libfreetype.a
	C:/msys64/mingw64/lib/libbz2.a
	C:/msys64/mingw64/lib/libpng16.a
	C:/msys64/mingw64/lib/libz.a
	C:/msys64/mingw64/lib/libharfbuzz.a
	C:/msys64/mingw64/lib/libusp10.a
	C:/msys64/mingw64/lib/libgdi32.a
	C:/msys64/mingw64/lib/librpcrt4.a
	C:/msys64/mingw64/lib/libuser32.a
	C:/msys64/mingw64/lib/libdwrite.a
	C:/msys64/mingw64/lib/libglib-2.0.a
	C:/msys64/mingw64/lib/libintl.a
	C:/msys64/mingw64/lib/libws2_32.a
	C:/msys64/mingw64/lib/libole32.a
	C:/msys64/mingw64/lib/libwinmm.a
	C:/msys64/mingw64/lib/libshlwapi.a
	C:/msys64/mingw64/lib/libuuid.a
	C:/msys64/mingw64/lib/libatomic.a
	C:/msys64/mingw64/lib/libpcre2-8.a
	C:/msys64/mingw64/lib/libgraphite2.a
	C:/msys64/mingw64/lib/libbrotlidec.a
	C:/msys64/mingw64/lib/libbrotlicommon.a
	C:/msys64/mingw64/lib/libtinyxml2.a
)

if(ANDROID)
	# Cross-compiled static deps for arm64 (freetype + tinyxml2). The C++ runtime
	# stays dynamic (libc++_shared.so) to match the Godot 4.4 export template,
	# which is built with NDK r23c (same libc++ ABI).
	target_link_libraries(godot_math_tex PRIVATE
		godot-cpp
		LaTeX
		${MT_ANDROID_PREFIX}/lib/libfreetype.a
		${MT_ANDROID_PREFIX}/lib/libtinyxml2.a
	)
else()
	target_link_libraries(godot_math_tex PRIVATE
		godot-cpp
		LaTeX
		${MT_MINGW_ARCHIVES}
	)
endif()

if(WIN32 AND NOT ANDROID)
	# CRT/C++/winpthread runtimes static; forces -Bstatic so every -l above
	# resolves to its .a archive instead of the DLL import library.
	target_link_options(godot_math_tex PRIVATE
		-static-libgcc
		-static-libstdc++
		-static
	)
endif()

if(WIN32)
	set_target_properties(godot_math_tex PROPERTIES
		OUTPUT_NAME "godot_math_tex.windows.debug.x86_64")
elseif(ANDROID)
	if(ANDROID_ABI STREQUAL "arm64-v8a")
		set(GODOT_ARCH arm64)
	elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
		set(GODOT_ARCH arm32)
	elseif(ANDROID_ABI STREQUAL "x86_64")
		set(GODOT_ARCH x86_64)
	else()
		set(GODOT_ARCH x86_32)
	endif()
	if(CMAKE_BUILD_TYPE STREQUAL "Release")
		set(GODOT_CFG release)
	else()
		set(GODOT_CFG debug)
	endif()
	# Android 要求原生库文件名以 "lib" 开头（Godot 导出会校验）。
	set_target_properties(godot_math_tex PROPERTIES
		OUTPUT_NAME "libgodot_math_tex.android.${GODOT_CFG}.${GODOT_ARCH}")
endif()

set_target_properties(godot_math_tex PROPERTIES
	PREFIX ""
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
	ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
)