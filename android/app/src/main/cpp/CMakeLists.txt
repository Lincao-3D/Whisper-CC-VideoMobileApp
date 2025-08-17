cmake_minimum_required(VERSION 3.10.2)
project(whisper_jni)

# Use C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Detect ABI output dir (Gradle sets ANDROID_ABI automatically)
set(JNI_OUTPUT_DIR ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI})
file(MAKE_DIRECTORY ${JNI_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${JNI_OUTPUT_DIR})

# Sources — if whisper.cpp is not mounted, fall back to stub
set(WHISPER_SRC whisper.cpp ggml.c)
foreach(SRC ${WHISPER_SRC})
    if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${SRC})
        message(WARNING "${SRC} missing — using stub instead")
        list(APPEND SOURCES ${CMAKE_SOURCE_DIR}/../whisper_stub.cpp)
    else()
        list(APPEND SOURCES ${CMAKE_SOURCE_DIR}/${SRC})
    endif()
endforeach()

add_library(whisper SHARED ${SOURCES})

find_library(log-lib log)
target_link_libraries(whisper ${log-lib})
