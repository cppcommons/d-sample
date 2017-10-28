import pegged.grammar; // https://github.com/PhilippeSigaud/Pegged/wiki

/+
import std.stdio;
import std.string;
import std.datetime;

abstract class Person {
   int birthYear, birthDay, birthMonth;
   string name;

   int getAge() {
      SysTime sysTime = Clock.currTime();
      return sysTime.year - birthYear;
   }
   abstract void print();
}
class Employee : Person {
   int empID;

   override void print() {
      writeln("The employee details are as follows:");
      writeln("Emp ID: ", this.empID);
      writeln("Emp Name: ", this.name);
      writeln("Age: ",this.getAge);
   }
}

void main() {
   Employee emp = new Employee();
   emp.empID = 101;
   emp.birthYear = 1980;
   emp.birthDay = 10;
   emp.birthMonth = 10;
   emp.name = "Emp1";
   emp.print();
}
+/

private abstract class EasyFactory
{
    abstract string className();
    abstract EasyFactory create(pegged.grammar.ParseTree);
    pegged.grammar.ParseTree pt;
}

private class EasyClass : EasyFactory
{
    override string className()
    {
        return typeof(this).stringof;
    }

    override EasyFactory create(pegged.grammar.ParseTree pt)
    {
        auto instance = new EasyClass();
        instance.pt = pt;
        return instance;
    }

    void easy_test() const
    {
        import std.stdio : writeln;

        writeln("easy_test()!");
    }
}

string pkgs = `
/*before*/
 //xyz
 /*123*/
/+
first doc
 doc
 doc.
+/

// comment

 handle archive_t;
 handle handle_t;
 function test() : char*;
 function test(...):real32;
 function test(a char*):int64*;
 procedure test(a: int32 dual, b: int64);
 proc test(a: int32 dual, b: int64 out);
 func test(h: handle archive_t, a: int32, b: char * out) int32;
 func test(json) json;
 func test(msgpack) msgpack;
 func test(a: int32* dual) int32*;
[doc]
doc doc doc
[/doc]
 func test(a: ucstring8 dual, /*ttt*/ b: mbstring in) ucstring32;
 /*
 this function is ...abc!
 this function is ...abc!
 */
[eof]
aaa bbb
xxx
this is end of file.
`;

//
// "EasyIDL.Type"
mixin(grammar(`
EasyIDL:
    _Idl            < (_Def+ "[eof]"i) / (_Def+ eoi)
    EndOfFile       <- "[eof]"i / eoi
    Keywords        < FunctionHead / ProcedureHead / Direction / _Type
    _Def            < Handle / _Prototype / EasyDoc
    Ident           < (!Keywords identifier)
    Handle          < "handle" Name ";"
    _Prototype      < Function / Procedure
    Function        < ;FunctionHead Name Parameters ":"? ReturnValue ";"
    FunctionHead    < ("function" / "func")
    Procedure       < ;ProcedureHead Name Parameters ";"
    ProcedureHead   < ("procedure" / "proc")
    ReturnValue     < _Type
    Parameters      < "(" _ParameterList? ")"
    _ParameterList  < VarArgs / JsonType / MsgpackType / Parameter (',' Parameter)*
    Parameter       < Name ":"? _Type Direction?
    Name            < identifier
    VarArgs         < "..."
    JsonType        < "json"
    MsgpackType     < "msgpack"
    Direction       < "in" / "out" / "dual"
    _Type           < Primitive / ManagedType / MsgpackType / JsonType / HandleType
    Primitive       < ("int32" / "int64" / "byte" / "char" / "wchar" / "real32" / "real64") PointerMark?
    #Pointer        < Primitive ;PointerMark
    PointerMark     < "*"
    ManagedType     < "mbstring" / "ansistring" / "ucstring8" / "ucstring16" / "ucstring32" / "array8" / "array16" / "array32" / "array64" / "object" / "service"
    HandleType      < :"handle" identifier
    EasyDoc         <~ (:"/+" (!"+/" .)* :"+/") / (:"[doc]"i (!"[/doc]"i .)* :"[/doc]"i)
    Comment1        <~ "/*" (!"*/" .)* "*/"
    Comment2        <~ "//" (!endOfLine .)* :endOfLine
    #Spacing        <- (blank / Comment1 / Comment2 / Comment3)*
    Spacing         <- (blank / Comment1 / Comment2)*
`));

private string get_def_type(ref ParseTree p)
{
    import std.string : split;

    return p.name.split(".")[1];
}

private ParseTree[] find_named_children(ref ParseTree p, string def_type)
{
    import std.stdio : writefln, writeln;
    import std.string : split;

    ParseTree[] result;
    foreach (ref child; p.children)
    {
        string child_def_type = child.get_def_type();
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
    string def_type = p.get_def_type();
    switch (def_type)
    {
    case "HandleDef":
        writefln("!struct %s%s;", module_prefix, p.children[0].matches[0]);
        break;
    case "Function":
        writeln("!function");
        ParseTree[] names = find_named_children(p, "Name");
        writeln("!names=", names);
        assert(names.length == 1);
        writeln("!function.name=", names[0].matches[0]);
        ParseTree[] params = find_named_children(p, "Parameter");
        writeln("!params=", params);
        foreach (ref param; params)
        {
            auto param_type = param.children[1];
            string param_type_label = param_type.get_def_type();
            writeln("!param_type_label=", param_type_label);
            switch (param_type_label)
            {
            case "PointerType":
                writefln("!PointerType: %s*", param_type.children[0].matches[0]);
                break;
            default:
                break;
            }
        }
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
    import std.algorithm :  /*+canFind,*/ startsWith;
    import std.stdio : writeln;
    import std.string : indexOf;

    if (p.children.length == 0)
        return;

    bool processed = true;
    while (processed)
    {
        processed = false;
        ParseTree[] new_children;
        foreach (ref child; p.children)
        {
            if (child.name.indexOf("._") == -1 /*!names.canFind(child.name)*/ )
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

void main(string[] args)
{
    import std.stdio;
    import std.array : join;

    foreach(arg; args)
    {
        writeln(arg);
    }

    {
        EasyFactory cl = new EasyClass();
        writeln("typeof(cl).stringof=", typeof(cl).stringof);
        auto cl2 = cast(EasyClass) cl;
        cl2.easy_test();
    }

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
        auto p = EasyIDL(pkgs);
        writeln("(0)", p.name);
        writeln("(1)", p.children[0].name);
        writeln(p);
        string[] unnecessary = [ //"EasyIDL.Idl", "EasyIDL.Def", "EasyIDL.Prototype", /*"EasyIDL.Parameters",*/
        //"EasyIDL.ParameterList", "EasyIDL.FunctionHead", "EasyIDL.ProcedureHead", "EasyIDL.Type"
        ];
        /*p =*/
        cut_unnecessary_nodes(p, unnecessary);
        writeln("(2)", p.name);
        writeln("(3)", p.children[0].name);
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
            foreach (line; description.splitLines)
            {
                if (line.strip().length != 0)
                    writeln("//EasyIDL: ", line);
            }
            writefln("%d: %s ==> %s", i, child.name, child.matches.join(" ").strip());
            //gen_cpp_code("mymodule_", child);
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
    writeln("kanji=漢字");
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
