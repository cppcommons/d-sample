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

msvc {
  QMAKE_CFLAGS_RELEASE -= -MD
  QMAKE_CFLAGS_RELEASE += -MT
  QMAKE_CXXFLAGS_RELEASE -= -MD
  QMAKE_CXXFLAGS_RELEASE += -MT
  QMAKE_CFLAGS_DEBUG -= -MDd
  QMAKE_CFLAGS_DEBUG += -MTd
  QMAKE_CXXFLAGS_DEBUG -= -MDd
  QMAKE_CXXFLAGS_DEBUG += -MTd
}
