#-------------------------------------------------
#
# Project created by QtCreator 2017-10-22T21:31:04
#
#-------------------------------------------------

QT       -= gui

TARGET = dlltest
TEMPLATE = lib
CONFIG += dll

CONFIG += c++11

DEFINES += DLLTEST_LIBRARY

SOURCES += dlltest.cpp

HEADERS += dlltest.h

QMAKE_LFLAGS += -static

QMAKE_LIBS += -larchive -liconv -llzma -lbz2 -lz -lnettle
