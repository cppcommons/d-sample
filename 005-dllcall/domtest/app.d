import core.sys.windows.windows;
import core.sys.windows.winbase;
import std.windows.registry;

import std.stdio;

import botan.libstate.global_state;
import botan.constructs.cryptobox;
import botan.rng.rng;
import botan.rng.auto_rng;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

immutable(char)[] registryKey = "dlang.dev1";

public void registerString(string section, string key, string value)
{
	Key HKCU = Registry.currentUser;
	Key rootKey = HKCU.createKey(registryKey);
	Key sectionKey = rootKey.createKey(section);
	sectionKey.setValue(key, value);
}

public string retrieveString(string section, string key, string defaultValue = null)
{
	Key HKCU = Registry.currentUser;
	try
	{
		Key rootKey = HKCU.getKey(registryKey);
		Key sectionKey = rootKey.getKey(section);
		Value value = sectionKey.getValue(key);
		if (value.type != REG_SZ)
		{
			return defaultValue;
		}
		return value.value_SZ;
	}
	catch (Exception ex)
	{
		return defaultValue;
	}
}

public void encryptString(string password, string section, string key, string value)
{
	auto state = globalState(); // ensure initialized
	Unique!AutoSeededRNG rng = new AutoSeededRNG;
	string ciphertext = CryptoBox.encrypt(cast(ubyte*) value.ptr, value.length, password, *rng);
	writeln(ciphertext);
	registerString(section, key, ciphertext);
}

public string decryptString(string password, string section, string key, string defaultValue = null)
{
	string ciphertext = retrieveString(section, key, null);
	if (ciphertext is null)
		return defaultValue;
	auto state = globalState(); // ensure initialized
	try
	{
		return CryptoBox.decrypt(ciphertext, password);
	}
	catch (Exception ex)
	{
		return defaultValue;
	}
}

unittest
{
	scope (success)
		writeln("test @", __FILE__, ":", __LINE__, " succeeded.");
	writeln("hello2!");
	Key HKCU = Registry.currentUser;
	assert(HKCU);
	writeln(HKCU);
	// Create a new key
	string unittestKeyName = "Temporary key for a D UnitTest which can be deleted afterwards";
	Key unittestKey = HKCU.createKey(unittestKeyName);
	assert(unittestKey);
	Key cityKey = unittestKey.createKey(
			"CityCollection using foreign names with umlauts and accents: " ~ "öäüÖÄÜàáâß");
	cityKey.setValue("Köln", "Germany"); // Cologne
	cityKey.setValue("Минск", "Belarus"); // Minsk
	cityKey.setValue("北京", "China"); // Bejing
	bool foundCologne, foundMinsk, foundBeijing;
	foreach (Value v; cityKey.values)
	{
		auto vname = v.name;
		auto vvalue_SZ = v.value_SZ;
		if (v.name == "Köln")
		{
			foundCologne = true;
			assert(v.value_SZ == "Germany");
		}
		if (v.name == "Минск")
		{
			foundMinsk = true;
			assert(v.value_SZ == "Belarus");
		}
		if (v.name == "北京")
		{
			foundBeijing = true;
			assert(v.value_SZ == "China");
		}
	}
	assert(foundCologne);
	assert(foundMinsk);
	assert(foundBeijing);
	//writeln(`高知=`, cityKey.getValue("高知")); /**/

	Key stateKey = unittestKey.createKey("StateCollection");
	stateKey.setValue("Germany", ["Düsseldorf", "Köln", "Hamburg"]);
	Value v = stateKey.getValue("Germany");
	string[] actual = v.value_MULTI_SZ;
	assert(actual.length == 3);
	assert(actual[0] == "Düsseldorf");
	assert(actual[1] == "Köln");
	assert(actual[2] == "Hamburg");

	Key numberKey = unittestKey.createKey("Number");
	numberKey.setValue("One", 1);
	Value one = numberKey.getValue("One");
	assert(one.value_SZ == "1");
	assert(one.value_DWORD == 1);

	/+
	unittestKey.deleteKey(numberKey.name);
	unittestKey.deleteKey(stateKey.name);
	unittestKey.deleteKey(cityKey.name);
	HKCU.deleteKey(unittestKeyName);
+/
	//auto e = collectException!RegistryException(HKCU.getKey("cDhmxsX9K23a8Uf869uB"));
	//assert(e.msg.endsWith(" (error 2)"));
}

unittest
{
	scope (success)
		writeln("test @", __FILE__, ":", __LINE__, " succeeded.");
	auto state = globalState(); // ensure initialized
	Unique!AutoSeededRNG rng = new AutoSeededRNG;

	string msg = "Something";
	writeln("Message: ", msg);

	string ciphertext = CryptoBox.encrypt(cast(ubyte*) msg.ptr, msg.length,
			"secret password", *rng);
	writeln(ciphertext);

	string plaintext = CryptoBox.decrypt(ciphertext, "secret password");
	writeln("Recovered: ", plaintext);
	registerString("the section", "the key", "the value");
	writeln(retrieveString("the section", "the key", "default value"));
	writeln(retrieveString("the section", "no key", "default value"));
	encryptString("password", "string section", "string key", "string value");
	writeln(decryptString("password", "string section", "string key", "default value"));
	writeln(decryptString("password2", "string section", "string key", "default value2"));
	writeln(decryptString("password", "string section", "no key", "default value3"));
}
