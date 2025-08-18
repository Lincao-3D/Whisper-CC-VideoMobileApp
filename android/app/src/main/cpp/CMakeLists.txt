cmake_minimum_required(VERSION 3.10.2)

project(whisper_jni)

# --------------------------------------------------
# C++ Standard
# --------------------------------------------------
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --------------------------------------------------
# Output directories
# --------------------------------------------------
# Gradle sets ANDROID_ABI automatically; we use it to
# place native libs in the correct jniLibs/ABI folder.
set(JNI_OUTPUT_DIR ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI})
file(MAKE_DIRECTORY ${JNI_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${JNI_OUTPUT_DIR})

# --------------------------------------------------
# Source files
# --------------------------------------------------
# If whisper.cpp or ggml.c are missing, fall back to stub.
set(WHISPER_SRC
    whisper.cpp
    ggml.c
)

foreach(SRC ${WHISPER_SRC})
    if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${SRC})
        message(WARNING "${SRC} missing — using stub instead")
        list(APPEND SOURCES ${CMAKE_SOURCE_DIR}/../whisper_stub.cpp)
    else()
        list(APPEND SOURCES ${CMAKE_SOURCE_DIR}/${SRC})
    endif()
endforeach()

# --------------------------------------------------
# Library target
# --------------------------------------------------
add_library(whisper SHARED ${SOURCES})

# --------------------------------------------------
# Link libraries
# --------------------------------------------------
find_library(log-lib log)

target_link_libraries(whisper
    ${log-lib}
)
