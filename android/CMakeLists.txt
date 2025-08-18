cmake_minimum_required(VERSION 3.22.1)

project(whisper_jni)

# --------------------------------------------------
# Library target
# --------------------------------------------------
add_library(
    whisper_jni
    SHARED
    whisper.cpp
    ggml.c
)

# --------------------------------------------------
# Link libraries
# --------------------------------------------------
find_library(
    log-lib
    log
)

target_link_libraries(
    whisper_jni
    ${log-lib}
)
