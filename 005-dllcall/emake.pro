QT += core xml
QT -= gui

TARGET = emake
TEMPLATE = app

CONFIG += c++14
CONFIG += console
CONFIG -= app_bundle

#DESTDIR = .

HEADERS += common.h
SOURCES += emake.cpp

#DEFINES += TEST_BY_QT=1

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

CONFIG(debug, debug|release) {
    TARGET_PATH = $$OUT_PWD/debug
}
CONFIG(release, debug|release) {
    TARGET_PATH = $$OUT_PWD/release
}

#QMAKE_POST_LINK += copy /y "$$shell_path($$TARGET_PATH/emake.exe)" "$$shell_path($$PWD)"
QMAKE_POST_LINK += cp "$$TARGET_PATH/emake.exe" "$$PWD"
