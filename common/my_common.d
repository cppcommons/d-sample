module my_common;

import core.sys.windows.windows;
import core.sys.windows.winbase;
import std.windows.registry;

import core.time;
import std.array;
import std.datetime;
import std.datetime.systime;
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
	section = section.replace(`/`, `\`);
	Key HKCU = Registry.currentUser;
	Key rootKey = HKCU.createKey(registryKey);
	Key sectionKey = rootKey.createKey(section);
	sectionKey.setValue(key, value);
}

public string retrieveString(string section, string key, string defaultValue = null)
{
	section = section.replace(`/`, `\`);
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
	//writeln(ciphertext);
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

public void sleepForWeeks(long n)
{
	sleepFor(dur!`weeks`(n));
}

public void sleepForDays(long n)
{
	sleepFor(dur!`days`(n));
}

public void sleepForHours(long n)
{
	sleepFor(dur!`hours`(n));
}

public void sleepForMinutes(long n)
{
	sleepFor(dur!`minutes`(n));
}

public void sleepForSeconds(long n)
{
	sleepFor(dur!`seconds`(n));
}

public void sleepFor(Duration duration)
{
	SysTime startTime = Clock.currTime();
	SysTime targetTime = startTime + duration;
	sleepUntil(targetTime);
}

public void sleepUntil(DateTime targetTime)
{
	sleepUntil(SysTime(targetTime));
}

public void sleepUntil(SysTime targetTime)
{
	string systimeToString(SysTime t)
	{
		SysTime t_of_sec = SysTime(DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second));
		return t_of_sec.toISOExtString().replace(`T`, ` `).replace(`-`, `/`);
	}

	string targetTimeStr = systimeToString(targetTime);
	size_t maxWidth = 0;
	for (;;)
	{
		SysTime currTime = Clock.currTime();
		if (currTime >= targetTime)
			break;
		Duration leftTime = targetTime - currTime;
		leftTime = dur!`msecs`(leftTime.total!`msecs`); // 残り時間表示用にミリ秒以下を切り捨て
		string displayStr = format!`Sleeping: until %s (%s left).`(targetTimeStr, leftTime);
		if (displayStr.length > maxWidth)
			maxWidth = displayStr.length;
		displayStr.reserve(maxWidth);
		while (displayStr.length < maxWidth)
			displayStr ~= ` `;
		stderr.writef("%s\r", displayStr);
		stderr.flush();
		Thread.sleep(dur!(`msecs`)(500));
	}
	for (int i = 0; i < maxWidth; i++)
		write(` `);
	stderr.write("\r");
	stderr.write("Sleeping: end.\n");
	stderr.flush();
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
