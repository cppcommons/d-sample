#include "vcapp1.h"

#include <iostream>
#include <memory>
using namespace std;
class C
{
public:
	char opcodes[16];
  private:
	std::string name_;
	int age_;

  public:
	C(std::string name, int age) : name_(name), age_(age) {}
	virtual ~C()
	{
		trace(funcsig << name_ << ' '<< age_);
	}
	void doit()
	{
		trace(funcsig << name_ << ' ' << age_);
	}
};

int main(int argc, char const *argv[])
{
	{
		auto a = std::make_shared<C>("Foo", 123);
		a->doit();
		C *b = new C("Foo", 123);
		if ((char *)b == &b->opcodes[0])
		{
			trace("same");
		}
		else
		{
			trace("diff");
		}
		trace("C::opcodes" << offsetof(class C, opcodes));
	}
	// destroy C
	return 0;
}