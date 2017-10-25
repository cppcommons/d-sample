#include "vcapp1.h"

#include <iostream>
#include <memory>
using namespace std;
class C
{
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
	}
	// destroy C
	return 0;
}