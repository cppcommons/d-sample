#include "dlltest.h"

#include <stdio.h>

#ifndef _TLSDECL_H_
#define _TLSDECL_H_

#include <windows.h>

#ifdef __GNUC__
#define TLS_VARIABLE_DECL __thread
#else
#define TLS_VARIABLE_DECL __declspec(thread)
#endif

#ifdef __GNUC__
#define TLS_CALLBACK_DECL(SECTION, VAR, FUN) PIMAGE_TLS_CALLBACK VAR __attribute__((section(SECTION))) = FUN;
#else
#ifdef _WIN64
#define TLS_CALLBACK_DECL(SECTION, VAR, FUN)                           \
    __pragma(const_seg(SECTION)) extern const PIMAGE_TLS_CALLBACK VAR; \
    const PIMAGE_TLS_CALLBACK VAR = FUN;                               \
    __pragma(const_seg())
#else
#define TLS_CALLBACK_DECL(SECTION, VAR, FUN)                   \
    __pragma(data_seg(SECTION)) PIMAGE_TLS_CALLBACK VAR = FUN; \
    __pragma(data_seg())
#endif
#endif

#ifdef __GNUC__
#define ALIGNED_ARRAY_DECL(TYPE, VAR, SIZE, ALIGN) TYPE VAR[SIZE] __attribute__((__aligned__(ALIGN)))
#else
#define ALIGNED_ARRAY_DECL(TYPE, VAR, SIZE, ALIGN) __declspec(align(ALIGN)) TYPE VAR[SIZE]
#endif

//#ifdef __GNUC__
//#define UNUSED_PARAMETER(P) {(P) = (P);}
//#else
//#define UNUSED_PARAMETER(P) (P)
//#endif

#define UNUSED_PARAMETER(P) (void)P;

#endif /* _TLSDECL_H_ */

#include <QtCore>

static int argc = 2;
static const char *argv[] = {"dummy1", "dummy2"};
static QCoreApplication qtapp(argc, (char **)argv);

static struct StaticInit
{
    explicit StaticInit()
    {
        qDebug() << "StaticInit::StaticInit(2)!" << qtapp.arguments();
    }
}
_init;

Dlltest::Dlltest()
{
}

int add2(int a, int b)
{
    return a + b;
}

extern "C" {
#include <archive.h>
#include <archive_entry.h>
}

#include <iostream>
#include <string>
#include <vector>

// https://github.com/libarchive/libarchive/wiki/Examples

int test1()
{
    printf("test1() start!\n");
    struct archive *a;
    struct archive_entry *entry;
    int r;

    a = archive_read_new();
    //archive_read_support_filter_all(a);
    archive_read_support_format_zip(a);
    archive_read_support_format_7zip(a);
    r = archive_read_open_filename(a, R"***(E:\d-dev\.binaries\msys2-i686-20161025.7z)***", 10240); // Note 1
    //r = archive_read_open_filename(a, R"***(C:\Users\Public\qtx\.binaries\msys2-i686-20161025.7z)***", 10240); // Note 1
    if (r != ARCHIVE_OK)
        return (10);
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK)
    {
        printf("%s\n", archive_entry_pathname(entry));
        auto entry_size = archive_entry_size(entry);
        //archive_read_data_skip(a);  // Note 2
        std::vector<char> buff(entry_size);
        ssize_t size;
        size = archive_read_data(a, &buff[0], buff.size());
        if (size != (qint64)buff.size())
        {
            std::cout << "(size != buff.size())" << std::endl;
            return (20);
        }
        std::cout << entry_size << std::endl;
    }
    r = archive_read_free(a); // Note 3
    if (r != ARCHIVE_OK)
        return (30);
    return 0;
}

int test2()
{
    static TLS_VARIABLE_DECL int loc_var = 123;
    loc_var++;
    return loc_var;
    //return 0;
}

#ifdef DLLTEST_TEST_MAIN
#include <QtCore>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    int a = 0b1011;     // 11
    int b = 0b10000000; // 128

    qDebug() << a << b;

    test1();

    qDebug() << "end!";

    //return a.exec();
    return 0;
}
#endif /* #ifdef DLLTEST_TEST_MAIN */
