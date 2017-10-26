import core.thread;
import std.conv : to;
import pegged.grammar;

/+
mixin(grammar(`
M2Pkgs:
    #List     < Elem* / " "*
    #List     < Elem* eoi
    List     < Pkg* eoi
    Elem     < Pkg / :Delim / :Parens
    #Pkg      <- identifier
    Pkg      <~ (Letter+ "/" Letter+) / Letter+
    Letter   <- [a-zA-Z0-9]
    Delim    <- "," / ";"
    Parens   <~ "(" (!")" .)* ")"
    Spacing <- (space / Parens / Delim)*
    # dummy
`));
+/

string pkgs = `
abc;
 //xyz
 /*123*/
 function (a b c); ttt;
`;

mixin(grammar(`
M2Pkgs:
	Idl			< Def+ eoi
	Def			<- Program / Symbol
	Symbol		< (!Keywords identifier) :";"
	Program		< Function
	Function	< "function" FunArgs :";"
	FunArgs		< :"(" identifier* :")"
	Keywords	< "function"
	#Pkg      <- identifier
	#Pkg      <~ (Letter+ "/" Letter+) / Letter+
	#Letter   <- [a-zA-Z0-9]
	Comment1	<~ "/*" (!"*/" .)* "*/"
	Comment2	<~ "//" (!endOfLine .)* endOfLine
	Spacing		<- (blank / Comment1 / Comment2)*
`));

/+
char[] toString(char* s)
{
    import core.stdc.string : strlen;

    return s ? s[0 .. strlen(s)] : cast(char[]) null;
}

// http://forum.dlang.org/post/c6ojg9$c8p$1@digitaldaemon.com
wchar[] toString(wchar* s)
{
    import core.stdc.wchar_;

    return s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
}
+/

/+
private ParseTree cut_unnecessary_nodes(ParseTree p, ref string[] names)
{
	import std.algorithm : canFind;
	import std.stdio : writeln;

	if (names.canFind(p.name) && p.children.length == 1)
	{
		return p.children[0];
	}
	for (int i = 0; i < p.children.length; i++)
	{
		p.children[i] = cut_unnecessary_nodes(p.children[i], names);
	}
	return p;
}
+/

private void cut_unnecessary_nodes(ref ParseTree p, ref string[] names)
{
	import std.algorithm : canFind;
	import std.stdio : writeln;

	bool processed = true;
	while (processed)
	{
		processed = false;
		if (p.children.length == 1)
		{
			ParseTree child = p.children[0];
			if (names.canFind(child.name))
			{
				p.children.length = 0;
				foreach (grand_child; child.children)
				{
					p.children ~= grand_child;
				}
				processed = true;
			}
		}
		for (int i = 0; i < p.children.length; i++)
		{
			auto child = p.children[i];
			if (names.canFind(child.name) && child.children.length == 1)
			{
				p.children[i] = child.children[0];
				processed = true;
			}
		}
	}
	foreach (child; p.children)
	{
		cut_unnecessary_nodes(child, names);
	}
}

void main()
{
	import std.stdio;

	{
		//import core.stdc.stdlib: getenv;
		import std.process : environment;
		import std.string : strip;

		//string pkgs = environment.get("MSYS2_PKGS");
		//string pkgs = "abc,xyz";
		writefln("pkgs.length=%d", pkgs.length);
		writefln("pkgs=%s", pkgs);
		if (strip(pkgs) == "")
		{
			writeln("empty pkgs");
			return;
		}
		auto p = M2Pkgs(pkgs);
		writeln(p);
		string[] unnecessary = ["M2Pkgs.Idl", "M2Pkgs.Def", "M2Pkgs.Program"];
		/*p =*/
		cut_unnecessary_nodes(p, unnecessary);
		if (!p.successful)
		{
			writeln("not success!");
			return;
		}
		writeln(p);
		if (p.end != pkgs.length)
		{
			writeln("length does not match!");
			return;
		}
		writeln(p.matches.length);
		/+
        for (int i = 0; i < p.matches.length; i++)
        {
            writefln("%d: %s", i, p.matches[i]);
        }+/
		//auto root = p.children[0];
		/+
        for (int i = 0; i < root.children.length; i++)
        {
			root.children[i] = root.children[i].children[0];
        }
        for (int i = 0; i < root.children.length; i++)
        {
            writefln("%d: %s %s", i, root.children[i].name, root.children[i].matches);
        }
		for (int i = 0; i < root.children.length; i++)
		{
			writefln("%d: %s %s", i, root.children[i].children[0].name, root.children[i].matches);
		}
		+/
	}

	{
		import std.path;

		string rsrcDir = std.path.expandTilde("~/myresources");
		writeln(rsrcDir);
	}

	// モジュール生成
	asModule("arithmetic", "temp_arithmetic", "Arithmetic:
    Expr     <- Factor AddExpr*
    AddExpr  <- ('+'/'-') Factor
    Factor   <- Primary MulExpr*
    MulExpr  <- ('*'/'/') Primary
    Primary  <- Parens / Number / Variable / '-' Primary

    Parens   <- '(' Expr ')'
    Number   <~ [0-9]+
    Variable <- identifier
");

}

/+
struct ParseTree
{
    string name; /// The node name
    bool successful; /// Indicates whether a parsing was successful or not
    string[] matches; /// The matched input's parts. Some expressions match at more than one place, hence matches is an array.

    string input; /// The input string that generated the parse tree. Stored here for the parse tree to be passed to other expressions, as input.
    size_t begin, end; /// Indices for the matched part (from the very beginning of the first match to the last char of the last match.

    ParseTree[] children; /// The sub-trees created by sub-rules parsing.

    /**
    Basic toString for easy pretty-printing.
    */
    string toString(string tabs = "") const
    {
        string result = name;

        string childrenString;
        bool allChildrenSuccessful = true;

        foreach(i,child; children)
        {
            childrenString ~= tabs ~ " +-" ~ child.toString(tabs ~ ((i < children.length -1 ) ? " | " : "   "));
            if (!child.successful)
                allChildrenSuccessful = false;
        }

        if (successful)
        {
            result ~= " " ~ to!string([begin, end]) ~ to!string(matches) ~ "\n";
        }
        else // some failure info is needed
        {
            if (allChildrenSuccessful) // no one calculated the position yet
            {
                Position pos = position(this);
                string left, right;

                if (pos.index < 10)
                    left = input[0 .. pos.index];
                else
                    left = input[pos.index-10 .. pos.index];
                //left = strip(left);

                if (pos.index + 10 < input.length)
                    right = input[pos.index .. pos.index + 10];
                else
                    right = input[pos.index .. $];
                //right = strip(right);

                result ~= " failure at line " ~ to!string(pos.line) ~ ", col " ~ to!string(pos.col) ~ ", "
                       ~ (left.length > 0 ? "after " ~ left.stringified ~ " " : "")
                       ~ "expected "~ (matches.length > 0 ? matches[$-1].stringified : "NO MATCH")
                       ~ ", but got " ~ right.stringified ~ "\n";
            }
            else
            {
                result ~= " (failure)\n";
            }
        }

        return result ~ childrenString;
    }

    @property string failMsg()
    {
        foreach(i, child; children)
        {
            if (!child.successful)
                return child.failMsg;
        }

        if (!successful)
        {
            Position pos = position(this);
            string left, right;

            if (pos.index < 10)
                left = input[0 .. pos.index];
            else
                left = input[pos.index - 10 .. pos.index];

            if (pos.index + 10 < input.length)
                right = input[pos.index .. pos.index + 10];
            else
                right = input[pos.index .. $];

            return "Failure at line " ~ to!string(pos.line) ~ ", col " ~ to!string(pos.col) ~ ", "
                ~ (left.length > 0 ? "after " ~ left.stringified ~ " " : "")
                ~ "expected " ~ (matches.length > 0 ? matches[$ - 1].stringified : "NO MATCH")
                ~ `, but got ` ~ right.stringified;
        }

        return "Success";
    }

    ParseTree dup() @property
    {
        ParseTree result = this;
        result.matches = result.matches.dup;
        result.children = map!(p => p.dup)(result.children).array();
        return result;
    }
}
+/
