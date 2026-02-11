# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(RSSNews LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml QmlXmlListModel Quick QuickControls2 Sql Network Concurrent QuickDialogs2)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(rssnews MACOSX_BUNDLE
    main.cpp
    databaseManager.cpp
    RssReader.cpp
    RssModel.cpp
    RssFilterModel.cpp
    SettingsManager.cpp
)

target_link_libraries(rssnews PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QmlXmlListModel
    Qt6::Sql
    Qt6::Network
    Qt6::Concurrent
    Qt6::QuickDialogs2
)
qt_add_qml_module(rssnews
    URI RssNewsModule
    QML_FILES
        content/BusyIndicator.qml
        content/PasswordDialog.qml
        content/RssFeeds.qml
        content/AddDialog.qml
        content/Sidebar.qml
        content/NewsListContainer.qml
        content/DetailContainer.qml
        content/SettingsDialog.qml
        content/Notification.qml
        Main.qml
        MainEntry.qml
)

install(TARGETS rssnews
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET rssnews
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
