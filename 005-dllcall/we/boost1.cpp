#include <string>
#include <vector>
#include <iostream>
#include <boost/shared_ptr.hpp>
//#include <boost/variant.hpp>

//#include <cstdint>
#include <stdint.h>

using namespace std;

struct MYHANDLE
{
};
void dummy(struct MYHANDLE *handle);

struct MYHANDLE_IMPL : public MYHANDLE
{
	std::string m_s;
	int64_t m_int64;
};

int64_t cos_add2(struct cos_context *context, int *argc, int64_t args[])
{
	if (!context)
	{
		(*argc) = 2;
		return 3;
	}
	//cos_return_clear();
	//cos_push_int32(0, 123);
	//cos_push_int32(1, 456);
	//cos_push_int32(2, 789);
	//return cos_return_multi(3);
	//return args[0];
	//return cos_return_int32(123);
	return 0;
}

struct C_Class1
{
	explicit C_Class1()
	{
		cout << "Constructor" << endl;
	}
	virtual ~C_Class1()
	{
		cout << "Destructor" << endl;
	}
};

/*
enum VariantType
{
	STRING,
	INT64
};*/
struct C_Variant
{
	enum VariantType
	{
		STRING,
		INT64
	};
	VariantType m_type;
	std::string m_s;
	int64_t m_int64;
	C_Variant(const std::string &x)
	{
		//this.m_s = x;
		m_type = C_Variant::VariantType::STRING;
		m_s = x;
	}
	C_Variant(int64_t x)
	{
		m_type = C_Variant::VariantType::INT64;
		//this.m_int64 = x;
		/*this.*/ m_int64 = x;
	}
	C_Variant &C_Variant::operator=(const std::string &x)
	{
		m_type = C_Variant::VariantType::STRING;
		m_s = x;
		return (*this);
	}
};

int main()
{
	typedef boost::shared_ptr<string> StrPtr;
	typedef boost::shared_ptr<C_Class1> ClsPtr;

	StrPtr s = StrPtr(new string("pen"));
	vector<StrPtr> v1;
	// vectorに入れたり。
	v1.push_back(StrPtr(new string("this")));
	v1.push_back(StrPtr(new string("is")));
	v1.push_back(StrPtr(new string("a")));
	v1.push_back(s);

	cout << *s << endl;						 // sをpush_backで他にコピーしたからと言って使えなくなったりしない
	cout << "*s.get()=" << *s.get() << endl; // sをpush_backで他にコピーしたからと言って使えなくなったりしない

	ClsPtr c1 = ClsPtr(new C_Class1());
	ClsPtr c2 = ClsPtr(new C_Class1());
	/*ClsPtr c3 =*/ClsPtr(new C_Class1());
	ClsPtr c4 = c1;

	cout << "c1.use_count()=" << c1.use_count() << endl;

	C_Variant var1 = 123;
	C_Variant var2 = "abc";
	var1 = "xyz";

	return 0;
} // ここで全てdeleteされる。
