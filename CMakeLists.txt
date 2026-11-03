cmake_minimum_required(VERSION 3.21)
project(LokiOS VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)

qt_standard_project_setup()

qt_add_executable(lokios
    src/main.cpp
)

qt_add_qml_module(lokios
    URI LokiOS
    VERSION 1.0
    QML_FILES
        src/Main.qml
        src/components/GlassPanel.qml
        src/components/Dock.qml
)

target_link_libraries(lokios PRIVATE Qt6::Quick)

install(TARGETS lokios
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)
