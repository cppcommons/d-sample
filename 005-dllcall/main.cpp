#include <QtCore>
#include <QtXml>

#include <windows.h>
#include <stdio.h>

#include "common.h"

#include <iostream>
#include <string>
#include <vector>

QDomElement createElementWithAttr1(QDomDocument &doc, QString elem_name, QString attr_name, QString attr_value)
{
    QDomElement result =doc.createElement(elem_name);
    result.setAttribute(attr_name, attr_value);
    return result;
}

QDomElement createElementWithAttr2(QDomDocument &doc, QString elem_name,
                                   QString attr1_name, QString attr1_value,
                                   QString attr2_name, QString attr2_value)
{
    QDomElement result =doc.createElement(elem_name);
    result.setAttribute(attr1_name, attr1_value);
    result.setAttribute(attr2_name, attr2_value);
    return result;
}

QDomElement createElementWithAttr3(QDomDocument &doc, QString elem_name,
                                   QString attr1_name, QString attr1_value,
                                   QString attr2_name, QString attr2_value,
                                   QString attr3_name, QString attr3_value)
{
    QDomElement result =doc.createElement(elem_name);
    result.setAttribute(attr1_name, attr1_value);
    result.setAttribute(attr2_name, attr2_value);
    result.setAttribute(attr3_name, attr3_value);
    return result;
}

QDomElement createOptElement1(QDomDocument &doc, QString name, QString value)
{
    QDomElement result = createElementWithAttr1(doc, "Option", name, value);
    return result;
}

QDomElement createOptElement2(QDomDocument &doc,
                              QString name1, QString value1,
                              QString name2, QString value2)
{
    QDomElement result = createElementWithAttr2(doc, "Option", name1, value1, name2, value2);
    return result;
}

QDomElement createOptElement3(QDomDocument &doc,
                              QString name1, QString value1,
                              QString name2, QString value2,
                              QString name3, QString value3)
{
    QDomElement result = createElementWithAttr3(doc, "Option", name1, value1, name2, value2, name3, value3);
    return result;
}

void setElementOption1(QDomDocument &doc, QDomElement &elem, QString name, QString value)
{
    elem.appendChild(createOptElement1(doc, name, value));
}

void setElementOption2(QDomDocument &doc, QDomElement &elem,
                       QString name1, QString value1,
                       QString name2, QString value2)
{
    elem.appendChild(createOptElement2(doc, name1, value1, name2, value2));
}

void setElementOption3(QDomDocument &doc, QDomElement &elem,
                       QString name1, QString value1,
                       QString name2, QString value2,
                       QString name3, QString value3)
{
    elem.appendChild(createOptElement3(doc, name1, value1, name2, value2, name3, value3));
}

int main()
{
    QString g_title = "cbtest2";

    QDomDocument doc;

    QDomElement root = doc.createElement("CodeBlocks_project_file");
    doc.appendChild(root);

    QDomElement fileVersion = doc.createElement("FileVersion");
    fileVersion.setAttribute("major", "1"); // <FileVersion major="1" minor="6" />
    fileVersion.setAttribute("minor", "6"); // <FileVersion major="1" minor="6" />
    root.appendChild(fileVersion);

    QDomElement project = doc.createElement("Project");
    root.appendChild(project);

    QDomElement optTitle = doc.createElement("Option");

    ////project.appendChild(createOptElement(doc, "title", g_title)); // <Option title="cbtest2" />

    setElementOption1(doc, project, "title", g_title); // <Option title="cbtest2" />
    setElementOption1(doc, project, "pch_mode", "2"); // <Option pch_mode="2" />
    setElementOption1(doc, project, "compiler", "dmc"); // <Option compiler="dmc" />

    QDomElement build = doc.createElement("Build");
    project.appendChild(build);

    /* <Target title="Debug"> */
    QDomElement targetDebug = createElementWithAttr1(doc, "Target", "title", "Debug");
    build.appendChild(targetDebug);

    // <Option output="bin/Release/cbtest2" prefix_auto="1" extension_auto="1" />
    setElementOption3(doc, targetDebug,
                      "output", "bin/Release/cbtest2",
                      "prefix_auto", "1",
                      "extension_auto", "1");

    // <Option object_output="obj/Debug/" />
    setElementOption1(doc, targetDebug,
                      "object_output", "obj/Debug/");


    QDomElement hoge = doc.createElement("opamp");//opampという要素を生成
    QDomElement piyo = doc.createElement("number");//numberという要素を生成
    QDomText number = doc.createTextNode("10");//numberに登録するTextを生成。テキストの内容は"10"

    //QDomAttr attr = doc.createAttribute("title");
    piyo.setAttribute("title", "1234ABC");
    //number.attributes().setNamedItem()

    root.appendChild(hoge);//root要素にhoge(つまりopamp)を追加
    hoge.appendChild(piyo); //hogeにpiyoを追加。(つまりnumber)
    piyo.appendChild(number);//piyoにテキストを追加(number)

    QFile file("emake.xml");//保存するファイルを設定
    file.open(QIODevice::WriteOnly);

    QTextStream out(&file);//ストリームを開いて
    out << R"***(<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>)***";
    out << "\n";
    doc.save(out,4);//save関数を呼び出す。4はインデント。無難に4にしたけど適当に設定していい。
	return 0;
}

