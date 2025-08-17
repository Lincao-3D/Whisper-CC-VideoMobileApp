cmake_minimum_required(VERSION 3.10.2)
project(whisper)

add_library(whisper SHARED
    whisper.cpp
    ggml.c
)

target_include_directories(whisper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

find_library(log-lib log)
target_link_libraries(whisper ${log-lib})
