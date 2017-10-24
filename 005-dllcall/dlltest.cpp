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
#include <io.h>
#include <fcntl.h>

// https://github.com/libarchive/libarchive/wiki/Examples

int test1()
{
    printf("test1() start!\n");
    struct archive *a;
    struct archive_entry *entry;
    int r;

    printf("test1(1)\n");
    a = archive_read_new();
    //archive_read_support_filter_all(a);
    archive_read_support_format_zip(a);
    archive_read_support_format_7zip(a);
#if 0x0
    r = archive_read_open_filename(a, R"***(E:\d-dev\.binaries\msys2-i686-20161025.7z)***", 10240); // Note 1
//r = archive_read_open_filename(a, R"***(C:\Users\Public\qtx\.binaries\msys2-i686-20161025.7z)***", 10240); // Note 1
#else
    //int fd = _wopen(LR"***(E:\d-dev\.binaries\msys2-i686-20161025.7z)***", _O_RDONLY | _O_BINARY);
    FILE *f = _wfopen(LR"***(E:\d-dev\.binaries\msys2-i686-20161025.7z)***", L"rb");
    int fd = fileno(f);
    //printf("f=0x%08x\n", f);
    //r = archive_read_open_FILE(a, f);
    r = archive_read_open_fd(a, fd, 10240);
#endif
    printf("test1(2)\n");
    if (r != ARCHIVE_OK)
        return (10);
    printf("test1(3)\n");
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
    printf("test1(4)\n");
    r = archive_read_free(a); // Note 3
    if (r != ARCHIVE_OK)
        return (30);
    printf("test1(5)\n");
    //fclose(f);
    return 0;
}

int test2()
{
    static TLS_VARIABLE_DECL int loc_var = 123;
    loc_var++;
    return loc_var;
    //return 0;
}

#include <QtCore>

static int argc = 2;
static const char *argv[] = {"dummy1", "dummy2"};
struct MyApp : public QCoreApplication
{
    explicit MyApp(int &argc, char **argv) : QCoreApplication(argc, argv)
    {
        qDebug() << "MyApp::MyApp()";
    }
};
static MyApp app(argc, (char **)argv);

static struct StaticInit
{
    explicit StaticInit()
    {
        qDebug() << "StaticInit::StaticInit(2)!" << app.arguments();
    }
} _init;

struct MyMutex : public QMutex
{
    explicit MyMutex()
    {
        qDebug() << "MyMutex::MyMutex()";
    }
};
static MyMutex mutex;

/* typedef */
typedef long long coint64;
typedef unsigned long long coid;

/* extern */
coid co_bytearray_new(qint64 size = 0, char *type = 0);
coint64 co_bytearray_reserve(coid oid, coint64 reserve);
coint64 co_bytearray_size(coid oid);
coint64 co_bytearray_append(coid oid, const char *data, coint64 size);
coint64 co_bytearray_read_seek(coid oid);                     // Thread Local Seek Pointer
coint64 co_bytearray_read_pos(coid oid);                      // Thread Local Seek Pointer
coint64 co_bytearray_read(coid oid, char *data, coint64 size); // Thread Local Seek Pointer
coint64 co_bytearray_available(coid oid);                     // Thread Local Seek Pointer

coint64 co_link_count(coid oid);
coint64 co_link(coid oid);
coint64 co_unlink(coid oid);
coint64 co_delete(coid oid);

/* internal */
QByteArray &cos_bytearray_pointer(coid oid);

#ifdef DLLTEST_TEST_MAIN
//#include <QtCore>

#include <map>
#include <iostream>
#include <string>

namespace myns
{

struct MyStruct //: public QObject
{
    QVariant var;
    int i;
    QBuffer *buff = NULL;
    operator QString() const
    {
        QString s;
        s.sprintf("i=%d", this->i);
        return s;
    }
    QString toString2() const
    {
        QString s;
        s.sprintf("***MyStruct(i=%d)***", this->i);
        return s;
    }
};
}
Q_DECLARE_METATYPE(myns::MyStruct)

using namespace myns;

static void doDeleteLater(QVariant *obj)
{
    //obj->deleteLater();
    qDebug() << "doDeleteLater()" << *obj;
    delete obj;
}

struct CoVariant
{
    //QVariant value;
    QSharedPointer<QVariant> value2;
    CoVariant()
    {
        this->value2 = QSharedPointer<QVariant>(new QVariant, doDeleteLater);
        //this->value2->clear();
    }
    CoVariant(double x) : CoVariant()
    {
        *(this->value2) = x;
    }
    CoVariant(QVariant &x) : CoVariant()
    {
        *(this->value2) = x;
    }
    CoVariant(MyStruct &x) : CoVariant()
    {
        *(this->value2) = QVariant::fromValue(x);
    }
};

QDebug operator<<(QDebug d, const MyStruct &x)
{
    d << x.toString2();
    return d;
}

QDebug operator<<(QDebug d, const CoVariant &x)
{
    d << "[" << x.value2->typeName() << "]";
    if (x.value2->typeName() == QString("myns::MyStruct"))
    {
        d << "???";
        d << x.value2->value<MyStruct>().toString2();
    }
    else
    {
        d << "!!!";
        d << *(x.value2);
    }
    return d;
}

int main(int argc, char *argv[])
{
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(argv);
    //QCoreApplication app(argc, argv);
    qDebug() << "main()!" << app.arguments();
    qDebug() << "main()!" << QCoreApplication::arguments();
    mutex.lock();
    mutex.unlock();

    int a = 0b1011;     // 11
    int b = 0b10000000; // 128

    qDebug() << a << b;

    //int rc = test1();
    //qDebug() << "rc:test1=" << rc;

    std::map<quint64, std::string> mymap;
    mymap[15] = "abc";
    std::cout << mymap.at(15) << std::endl;
    //std::cout << mymap << std::endl;
    QMap<QString, int> map1;
    QMap<coid, QVariant> map2;
    map2[1] = "xyz";
    map2[2] = 123.4;
    QString temp = "ttt";
    QByteArray ba = temp.toUtf8();
    ba.reserve(1024);
    map2[3] = ba;
    map2[4] = (quint64)123L;
    qDebug() << map2;
    map2.remove(2);
    map2.remove(200);
    qDebug() << map2;
    ba.append("xxx");
    qDebug() << map2;
    map2[3].toByteArray().append("yyy");
    qDebug() << map2;
    map2.clear();
    qDebug() << map2;
    QMap<QByteArray, QVariant> map3;
    map3["abc"] = "xyz";
    map3["abc"] = "uuu";
    map3["#10238"] = "uuu";
    map3["#real"] = (double)123.4;
    QList<QVariant> mylist = {1.2, "abc"};
    map3["#list"] = mylist;
    static QBuffer buff;
    buff.open(QIODevice::ReadWrite);
    MyStruct mystruct;
    mystruct.i = 789;
    mystruct.buff = &buff;
    //mystruct.buff.write("abc");
    QVariant myvar = QVariant::fromValue(mystruct);
    map3["#struct"] = myvar;
    qDebug() << map3;
    qDebug() << map3["#struct"].value<MyStruct>().i;
    map3["#struct"].value<MyStruct>().buff->write("abc");
    qDebug() << buff.data();
    qDebug() << mystruct;
    QMap<quint64, CoVariant> map4;
    CoVariant myvar2;
    //myvar2.value = QVariant::fromValue(mystruct);
    myvar2 = mystruct;
    map4[0] = myvar2;
    CoVariant myvar3;
    myvar3 = 1.23;
    map4[1] = myvar3;
    qDebug() << map4;
    CoVariant myvar4(mystruct);
    map4[2] = mystruct;
    qDebug() << map4;

    qDebug() << "end!";

    //return a.exec();
    return 0;
}
#endif /* #ifdef DLLTEST_TEST_MAIN */
