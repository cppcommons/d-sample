QT += core xml
QT -= gui

TARGET = cos1
TEMPLATE = app
CONFIG += c++14
CONFIG += console
CONFIG -= app_bundle

HEADERS += common.h

SOURCES += cos1.cpp

Release:TARGET = cos1
Release:DESTDIR = $$OUT_PWD
Release:OBJECTS_DIR = $$OUT_PWD/cos1.exe.bin/release/.obj
Release:MOC_DIR = $$OUT_PWD/cos1.exe.bin/release/.moc
Release:RCC_DIR = $$OUT_PWD/cos1.exe.bin/release/.rcc
Release:UI_DIR = $$OUT_PWD/cos1.exe.bin/release/.ui

Debug:TARGET = cos1-d
Debug:DESTDIR = $$OUT_PWD
Debug:OBJECTS_DIR = $$OUT_PWD/cos1.exe.bin/debug/.obj
Debug:MOC_DIR = $$OUT_PWD/cos1.exe.bin/debug/.moc
Debug:RCC_DIR = $$OUT_PWD/cos1.exe.bin/debug/.rcc
Debug:UI_DIR = $$OUT_PWD/cos1.exe.bin/debug/.ui
