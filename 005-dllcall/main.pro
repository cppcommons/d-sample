QT += core
QT -= gui

TARGET = main-qt
TEMPLATE = app

CONFIG += c++14
CONFIG += console
CONFIG -= app_bundle

DESTDIR = .

HEADERS += common.h
SOURCES += main.cpp

DEFINES += TEST_BY_QT=1

#QMAKE_LIBS += -larchive -liconv -llzma -lbz2 -lz -lnettle

