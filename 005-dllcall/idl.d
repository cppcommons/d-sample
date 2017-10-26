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
 //xyz
 /*123*/
 handle archive_t;
 handle handle_t;
 function test();
 function test(...);
 function test(a: char*);
 procedure test(a: int32 dual, b: int64);
 proc test(a: int32 dual, b: int64 out);
 func test(h: handle archive_t, a: int32, b: char * out) int32;
 /*
 this function is ...abc!
 this function is ...abc!
 */ 
`;

mixin(grammar(`
M2Pkgs:
	Idl				< Def+ eoi
	Keywords		< FunctionHead / ProcedureHead / Direction / Type
	Def				< HandleDef / Prototype
	Ident			< (!Keywords identifier)
	HandleDef		< "handle" Name ";"
	Prototype		< Function / Procedure
	Function		< FunctionHead Name Parameters ReturnValue? ";"
	FunctionHead	< ("function" / "func")
	Procedure		< ProcedureHead Name Parameters ";"
	ProcedureHead	< ("procedure" / "proc")
	ReturnValue		< Type
	Parameters		< "(" ParameterList? ")"
	ParameterList	< VarArgs / Parameter (',' Parameter)*
	Parameter		< Name ":" Type Direction?
	Name			< identifier
	VarArgs			< "..."
	Direction		< "in" / "out" / "dual"
	Type			< (Primitive PointerMark?) / ManagedType / HandleType
	Primitive		< "int32" / "int64" / "byte" / "char" / "real32" / "real64"
	PointerMark		< "*"
	ManagedType		< "astring" / "ustring" / "wstring" / "buffer8" / "buffer16" / "msgpack" / "json" / "object" / "service"
	HandleType		< :"handle" identifier
	Comment1		<~ "/*" (!"*/" .)* "*/"
	Comment2		<~ "//" (!endOfLine .)* endOfLine
	Spacing			<- (blank / Comment1 / Comment2)*
`));

//private ParseTree*[] find_named_children(ref ParseTree p, string def_type)
private ParseTree[] find_named_children(ref ParseTree p, string def_type)
{
	import std.stdio : writefln, writeln;
	import std.string : split;

	ParseTree[] result;
	foreach (ref child; p.children)
	{
		string child_def_type = child.name.split(".")[1];
		writefln("child_def_type=%s", child_def_type);
		if (child_def_type == def_type)
			result ~= child;
	}
	return result;
}

private void gen_cpp_code(string module_prefix, ref ParseTree p)
{
	import std.stdio : writefln, writeln;
	import std.string : split;

	writeln(p.name);
	writeln(p.name.split(".")[1]);
	string def_type = p.name.split(".")[1];
	switch (def_type)
	{
	case "HandleDef":
		writefln("!struct %s%s;", module_prefix, p.children[0].matches[0]);
		break;
	case "Function":
		writeln("!function");
		ParseTree[] names = find_named_children(p, "Name");
		writeln("!names=", names);
		assert(names.length==1);
		writeln("!function.name=", names[0].matches[0]);
		ParseTree[] params = find_named_children(p, "Parameter");
		writeln("!params=", params);
		break;
	default:
		writefln("%s is not supported!", def_type);
		//break;
		assert(0);
	}

}

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
		ParseTree[] new_children;
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
	import std.array : join;

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
		string[] unnecessary = [
			"M2Pkgs.Idl", "M2Pkgs.Def", "M2Pkgs.Prototype", "M2Pkgs.Parameters",
			"M2Pkgs.ParameterList", "M2Pkgs.FunctionHead", "M2Pkgs.ProcedureHead", "M2Pkgs.Type"
		];
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
			foreach (line; description.splitLines)
			{
				if (line.strip().length != 0)
					writeln("//IDL: ", line);
			}
			writefln("%d: %s ==> %s", i, child.name, child.matches.join(" "));
			gen_cpp_code("mymodule_", child);
			writeln();
		}
	}

	// モジュール生成
	version (none)
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
