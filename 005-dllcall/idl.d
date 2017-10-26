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
/*before*/
abc;
 //xyz
 /*123*/
 function ();
 function (...);
 function (a: int32);
 procedure (a: int32 dual, b: int64);
 proc (a: int32 dual, b: int64 out);
 func (a: int32, b: int64 out) int32;
 /*
 this function is ...abc!
 this function is ...abc!
 */ 
 tt;/*xyz*/ 
`;

mixin(grammar(`
M2Pkgs:
	Idl				< Def+ eoi
	Keywords		< "function" / Out / Type
	Def				< Prototype / Symbol
	Ident			< (!Keywords identifier)
	Symbol			< Ident :";"
	Prototype		< Function / Procedure
	Function		< ("function" / "func") Parameters ReturnValue? :";"
	Procedure		< ("procedure" / "proc") Parameters :";"
	ReturnValue		< Type
	Parameters		< "(" ParameterList? ")"
	ParameterList	< VarArgs / Parameter (',' Parameter)*
	Parameter		< ParameterName ":" Type Out?
	ParameterName	< identifier
	VarArgs			< "..."
	Out				< "in" / "out" / "dual"
	Type			< Int32 / Int64
	Int32			< "int32"
	Int64			< "int64"
	Comment1		<~ "/*" (!"*/" .)* "*/"
	Comment2		<~ "//" (!endOfLine .)* endOfLine
	Spacing			<- (blank / Comment1 / Comment2)*
`));

void test(out int a)
{
	a = 123;
}

private void cut_unnecessary_nodes(ref ParseTree p, ref string[] names)
{
	import std.algorithm : canFind;
	import std.stdio : writeln;

	if (p.children.length == 0)
		return;

	bool processed = true;
	while (processed)
	{
		processed = false;
		ParseTree [] new_children;
		foreach (ref child; p.children)
		{
			if (!names.canFind(child.name))
			{
				new_children ~= child;
				continue;
			}
			////writeln("Found(A): ", child.name, " ", p.name);
			foreach (ref grand_child; child.children)
			{
				////writeln("  grand_child.name: ", grand_child.name);
				new_children ~= grand_child;
			}
			processed = true;
		}
		p.children = new_children;
	}
	foreach (ref child; p.children)
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

		int v = 11;
		test(v);
		writeln("v=", v);
		writefln("pkgs.length=%d", pkgs.length);
		writefln("pkgs=%s", pkgs);
		if (strip(pkgs) == "")
		{
			writeln("empty pkgs");
			return;
		}
		auto p = M2Pkgs(pkgs);
		writeln(p);
		string[] unnecessary = ["M2Pkgs.Idl", "M2Pkgs.Def", "M2Pkgs.Prototype", "M2Pkgs.Parameters", "M2Pkgs.ParameterList", "M2Pkgs.Type"];
		/*p =*/
		cut_unnecessary_nodes(p, unnecessary);
		writeln(p);
		if (!p.successful)
		{
			writeln("not success!");
			return;
		}
		//cut_unnecessary_nodes(p, unnecessary);
		//writeln(p);
		////writeln(p.matches.length);
		for (int i = 0; i < p.children.length; i++)
		{
			import std.string : replace, splitLines, strip;

			auto child = p.children[i];
			auto description = child.input[child.begin .. child.end];
			description = description.strip();
			//description = description.replace("/*", "");
			//description = description.replace("*/", "");
			//description = description.replace("//", "");
			//writeln(description);
			foreach (line; description.splitLines)
			{
				if (line.strip().length != 0)
					writeln("//IDL: ", line);
			}
			writefln("%d: %s %s", i, child.name, child.matches);
			writeln();
		}
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
