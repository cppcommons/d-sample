module qiitalib;
//import arsd.dom;
import vibe.data.json;
import dateparser;
import core.sync.rwmutex;
import core.sync.semaphore;
import core.thread;
import core.time;
import std.algorithm;
import std.algorithm.mutation;
import std.algorithm.sorting;
import std.algorithm.setops;
import std.array;
import std.conv;
import std.datetime;
import std.datetime.systime;
import std.file;
import std.format;

//import std.json;
import std.net.curl;
import std.path;
import std.process;
import std.regex;
import std.stdio;
import std.string;
import std.variant;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

public string ql_systime_to_string(SysTime t)
{
	SysTime t_of_sec = SysTime(DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second));
	return t_of_sec.toISOExtString() ~ `+09:00`;
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

class C_QiitaApiHttp
{
	//int code;
	HTTP.StatusLine statusLine;
	string[string] headers;
	ubyte[] data;
	int get(string url)
	{
		//this.code = 0;
		this.headers.clear();
		this.data.length = 0;
		auto http = HTTP(url);
		http.addRequestHeader(`Authorization`, `Bearer 06ade23e3803334f43a0671f2a7c5087305578bd`);
		http.onReceiveStatusLine = (in HTTP.StatusLine statusLine) {
			this.statusLine = statusLine;
		};
		http.onReceiveHeader = (in char[] key, in char[] value) {
			this.headers[key] = to!string(value);
		};
		http.onReceive = (ubyte[] bytes) {
			this.data ~= bytes;
			return bytes.length;
		};
		//this.code = http.perform(No.throwOnError);
		//return this.code;
		return http.perform(No.throwOnError);
	}
}

class C_QiitaApiServie
{
	C_QiitaApiHttp http;
	//JSONValue jsonValue;
	Json jsonValue;
	//long rateRemaining;
	//SysTime rateResetTime;
	this()
	{
		this.http = new C_QiitaApiHttp();
	}

	~this()
	{
		delete this.http;
	}

	int get(string url)
	{
		_loop_a: for (;;)
		{
			this.jsonValue = null;
			int rc = this.http.get(url);
			if (rc != 0)
				return rc;
			writefln("this.http.statusLine.code=%d", this.http.statusLine.code);
			if (this.http.statusLine.code == 403)
			{
				string data = cast(string) this.http.data;
				if (data.canFind(`"rate_limit_exceeded"`))
				{
					long rateRemaining;
					SysTime rateResetTime;
					//this.rateRemaining = -1;
					if ("rate-remaining" in this.http.headers)
						rateRemaining = to!long(this.http.headers["rate-remaining"]);
					long v_rate_reset = 0;
					if ("rate-reset" in this.http.headers)
						v_rate_reset = to!long(this.http.headers["rate-reset"]);
					rateResetTime = SysTime(unixTimeToStdTime(v_rate_reset));
					writeln(`rate_limit_exceeded error!(4)`);
					SysTime currentTime = Clock.currTime();
					writeln(currentTime);
					Duration diff = rateResetTime - currentTime;
					writeln(diff);
					Duration diff2 = diff + dur!`seconds`(60);
					writeln(diff2);
					writeln(`Sleeping for: `, diff2);
					sleepForSeconds(diff2.total!`seconds`);
					continue _loop_a;
				}
				write("\a");
				return -1;
			}
			if (this.http.statusLine.code != 200)
			{
				write("\a");
				return -1;
			}
			if (this.http.headers["content-type"] != "application/json"
					&& this.http.headers["content-type"] != "application/json; charset=utf-8")
			{
				writeln(`not application/json`);
				writeln(this.http.headers);
				//writeln(cast(string) this.http.data);
				//Duration diff1 = dur!`seconds`(10);
				//writeln(`Sleeping for: `, diff1);
				//sleepForSeconds(diff1.total!`seconds`);
				//exit(1);
				//continue _loop_a;
				return -1;
			}
			/+
			this.rateRemaining = -1;
			if ("rate-remaining" in this.http.headers)
				this.rateRemaining = to!long(this.http.headers["rate-remaining"]);
			long v_rate_reset = 0;
			if ("rate-reset" in this.http.headers)
				v_rate_reset = to!long(this.http.headers["rate-reset"]);
			this.rateResetTime = SysTime(unixTimeToStdTime(v_rate_reset));
			+/
			try
			{
				this.jsonValue = parseJsonString(cast(string) this.http.data);
			}
			catch (JSONException ex)
			{
				write("\a");
				writeln(ex);
				return -1;
			}
			/+
			Variant v_type = getJsonObjectProp(this.jsonValue, `type`);
			if (v_type == `rate_limit_exceeded`)
			{
				writeln(`rate_limit_exceeded error!(3)`);
				//long v_rate_reset = to!long(this.http.headers["rate-reset"]);
				//writeln(v_rate_reset);
				//writeln(SysTime(unixTimeToStdTime(v_rate_reset)));
				SysTime currentTime = Clock.currTime();
				writeln(currentTime);
				//SysTime v_reset_time = SysTime(unixTimeToStdTime(v_rate_reset));
				//auto diff = v_reset_time - currentTime;
				Duration diff = this.rateResetTime - currentTime;
				writeln(diff);
				Duration diff2 = diff + dur!`seconds`(60);
				writeln(diff2);
				writeln(diff.total!"minutes");
				writeln(diff.total!"seconds");
				writeln(diff.total!"msecs");
				writeln(`Sleeping for: `, diff2);
				//Thread.sleep(diff2);
				sleepForSeconds(diff2.total!`seconds`);
				continue _loop_a;
			}
			+/
			break _loop_a;
		}
		return 0;
	}
}

public string ql_html_head_insert()
{
	return `<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-110075493-1"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'UA-110075493-1');
</script>
<!-- Google AdSense -->
<script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<script>
  (adsbygoogle = window.adsbygoogle || []).push({
    google_ad_client: "ca-pub-6168511236629369",
    enable_page_level_ads: true
  });
</script>
`;
}
