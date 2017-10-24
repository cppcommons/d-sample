QT += core
QT -= gui

TARGET = dllmain
TEMPLATE = app

CONFIG += c++14
CONFIG += console
CONFIG -= app_bundle

DEFINES += DLLTEST_LIBRARY
DEFINES += DLLTEST_TEST_MAIN

SOURCES += dlltest.cpp

QMAKE_LIBS += -larchive -liconv -llzma -lbz2 -lz -lnettle

DESTDIR = .
