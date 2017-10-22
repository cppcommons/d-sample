#include "dlltest.h"


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

void test1()
{
    struct archive *a;
    struct archive_entry *entry;
    int r;

    a = archive_read_new();
    //archive_read_support_filter_all(a);
    archive_read_support_format_zip(a);
    archive_read_support_format_7zip(a);
    r = archive_read_open_filename(a, R"***(E:\d-dev\.binaries\msys2-i686-20161025.7z)***", 10240); // Note 1
    if (r != ARCHIVE_OK)
        exit(1);
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        printf("%s\n",archive_entry_pathname(entry));
        auto entry_size = archive_entry_size(entry);
        //archive_read_data_skip(a);  // Note 2
        std::vector<char> buff(entry_size);
        ssize_t size;
        size = archive_read_data(a, &buff[0], buff.size());
        if (size != (qint64)buff.size()) {
            std::cout << "(size != buff.size())" << std::endl;
            exit(1);
        }
        std::cout << entry_size << std::endl;
    }
    r = archive_read_free(a);  // Note 3
    if (r != ARCHIVE_OK)
        exit(1);
}

#ifdef DLLTEST_TEST_MAIN
#include <QtCore>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    int a = 0b1011 ; // 11
    int b = 0b10000000 ; // 128

    qDebug() << a << b;

    test1();

    qDebug() << "end!";

    //return a.exec();
    return 0;
}
#endif /* #ifdef DLLTEST_TEST_MAIN */
