/++
This module was automatically generated from the following grammar:

Arithmetic:
    Expr     <- Factor AddExpr*
    AddExpr  <- ('+'/'-') Factor
    Factor   <- Primary MulExpr*
    MulExpr  <- ('*'/'/') Primary
    Primary  <- Parens / Number / Variable / '-' Primary

    Parens   <- '(' Expr ')'
    Number   <~ [0-9]+
    Variable <- identifier


+/
module arithmetic;

public import pegged.peg;
import std.algorithm: startsWith;
import std.functional: toDelegate;

struct GenericArithmetic(TParseTree)
{
    import std.functional : toDelegate;
    import pegged.dynamic.grammar;
    static import pegged.peg;
    struct Arithmetic
    {
    enum name = "Arithmetic";
    static ParseTree delegate(ParseTree)[string] before;
    static ParseTree delegate(ParseTree)[string] after;
    static ParseTree delegate(ParseTree)[string] rules;
    import std.typecons:Tuple, tuple;
    static TParseTree[Tuple!(string, size_t)] memo;
    static this()
    {
        rules["Expr"] = toDelegate(&Expr);
        rules["AddExpr"] = toDelegate(&AddExpr);
        rules["Factor"] = toDelegate(&Factor);
        rules["MulExpr"] = toDelegate(&MulExpr);
        rules["Primary"] = toDelegate(&Primary);
        rules["Parens"] = toDelegate(&Parens);
        rules["Number"] = toDelegate(&Number);
        rules["Variable"] = toDelegate(&Variable);
        rules["Spacing"] = toDelegate(&Spacing);
    }

    template hooked(alias r, string name)
    {
        static ParseTree hooked(ParseTree p)
        {
            ParseTree result;

            if (name in before)
            {
                result = before[name](p);
                if (result.successful)
                    return result;
            }

            result = r(p);
            if (result.successful || name !in after)
                return result;

            result = after[name](p);
            return result;
        }

        static ParseTree hooked(string input)
        {
            return hooked!(r, name)(ParseTree("",false,[],input));
        }
    }

    static void addRuleBefore(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar name
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ ": " ~ ruleSyntax, rules);
        foreach(ruleName,rule; dg.rules)
            if (ruleName != "Spacing") // Keep the local Spacing rule, do not overwrite it
                rules[ruleName] = rule;
        before[parentRule] = rules[dg.startingRule];
    }

    static void addRuleAfter(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar named
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ ": " ~ ruleSyntax, rules);
        foreach(name,rule; dg.rules)
        {
            if (name != "Spacing")
                rules[name] = rule;
        }
        after[parentRule] = rules[dg.startingRule];
    }

    static bool isRule(string s)
    {
		import std.algorithm : startsWith;
        return s.startsWith("Arithmetic.");
    }
    mixin decimateTree;

    alias spacing Spacing;

    static TParseTree Expr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(Factor, pegged.peg.zeroOrMore!(AddExpr)), "Arithmetic.Expr")(p);
        }
        else
        {
            if (auto m = tuple(`Expr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(Factor, pegged.peg.zeroOrMore!(AddExpr)), "Arithmetic.Expr"), "Expr")(p);
                memo[tuple(`Expr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Expr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(Factor, pegged.peg.zeroOrMore!(AddExpr)), "Arithmetic.Expr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(Factor, pegged.peg.zeroOrMore!(AddExpr)), "Arithmetic.Expr"), "Expr")(TParseTree("", false,[], s));
        }
    }
    static string Expr(GetName g)
    {
        return "Arithmetic.Expr";
    }

    static TParseTree AddExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("+", "-"), Factor), "Arithmetic.AddExpr")(p);
        }
        else
        {
            if (auto m = tuple(`AddExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("+", "-"), Factor), "Arithmetic.AddExpr"), "AddExpr")(p);
                memo[tuple(`AddExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree AddExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("+", "-"), Factor), "Arithmetic.AddExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("+", "-"), Factor), "Arithmetic.AddExpr"), "AddExpr")(TParseTree("", false,[], s));
        }
    }
    static string AddExpr(GetName g)
    {
        return "Arithmetic.AddExpr";
    }

    static TParseTree Factor(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(Primary, pegged.peg.zeroOrMore!(MulExpr)), "Arithmetic.Factor")(p);
        }
        else
        {
            if (auto m = tuple(`Factor`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(Primary, pegged.peg.zeroOrMore!(MulExpr)), "Arithmetic.Factor"), "Factor")(p);
                memo[tuple(`Factor`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Factor(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(Primary, pegged.peg.zeroOrMore!(MulExpr)), "Arithmetic.Factor")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(Primary, pegged.peg.zeroOrMore!(MulExpr)), "Arithmetic.Factor"), "Factor")(TParseTree("", false,[], s));
        }
    }
    static string Factor(GetName g)
    {
        return "Arithmetic.Factor";
    }

    static TParseTree MulExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("*", "/"), Primary), "Arithmetic.MulExpr")(p);
        }
        else
        {
            if (auto m = tuple(`MulExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("*", "/"), Primary), "Arithmetic.MulExpr"), "MulExpr")(p);
                memo[tuple(`MulExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree MulExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("*", "/"), Primary), "Arithmetic.MulExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.keywords!("*", "/"), Primary), "Arithmetic.MulExpr"), "MulExpr")(TParseTree("", false,[], s));
        }
    }
    static string MulExpr(GetName g)
    {
        return "Arithmetic.MulExpr";
    }

    static TParseTree Primary(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(Parens, Number, Variable, pegged.peg.and!(pegged.peg.literal!("-"), Primary)), "Arithmetic.Primary")(p);
        }
        else
        {
            if (auto m = tuple(`Primary`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(Parens, Number, Variable, pegged.peg.and!(pegged.peg.literal!("-"), Primary)), "Arithmetic.Primary"), "Primary")(p);
                memo[tuple(`Primary`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Primary(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(Parens, Number, Variable, pegged.peg.and!(pegged.peg.literal!("-"), Primary)), "Arithmetic.Primary")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(Parens, Number, Variable, pegged.peg.and!(pegged.peg.literal!("-"), Primary)), "Arithmetic.Primary"), "Primary")(TParseTree("", false,[], s));
        }
    }
    static string Primary(GetName g)
    {
        return "Arithmetic.Primary";
    }

    static TParseTree Parens(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("("), Expr, pegged.peg.literal!(")")), "Arithmetic.Parens")(p);
        }
        else
        {
            if (auto m = tuple(`Parens`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("("), Expr, pegged.peg.literal!(")")), "Arithmetic.Parens"), "Parens")(p);
                memo[tuple(`Parens`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Parens(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("("), Expr, pegged.peg.literal!(")")), "Arithmetic.Parens")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("("), Expr, pegged.peg.literal!(")")), "Arithmetic.Parens"), "Parens")(TParseTree("", false,[], s));
        }
    }
    static string Parens(GetName g)
    {
        return "Arithmetic.Parens";
    }

    static TParseTree Number(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9'))), "Arithmetic.Number")(p);
        }
        else
        {
            if (auto m = tuple(`Number`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9'))), "Arithmetic.Number"), "Number")(p);
                memo[tuple(`Number`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Number(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9'))), "Arithmetic.Number")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9'))), "Arithmetic.Number"), "Number")(TParseTree("", false,[], s));
        }
    }
    static string Number(GetName g)
    {
        return "Arithmetic.Number";
    }

    static TParseTree Variable(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(identifier, "Arithmetic.Variable")(p);
        }
        else
        {
            if (auto m = tuple(`Variable`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(identifier, "Arithmetic.Variable"), "Variable")(p);
                memo[tuple(`Variable`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Variable(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(identifier, "Arithmetic.Variable")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(identifier, "Arithmetic.Variable"), "Variable")(TParseTree("", false,[], s));
        }
    }
    static string Variable(GetName g)
    {
        return "Arithmetic.Variable";
    }

    static TParseTree opCall(TParseTree p)
    {
        TParseTree result = decimateTree(Expr(p));
        result.children = [result];
        result.name = "Arithmetic";
        return result;
    }

    static TParseTree opCall(string input)
    {
        if(__ctfe)
        {
            return Arithmetic(TParseTree(``, false, [], input, 0, 0));
        }
        else
        {
            forgetMemo();
            return Arithmetic(TParseTree(``, false, [], input, 0, 0));
        }
    }
    static string opCall(GetName g)
    {
        return "Arithmetic";
    }


    static void forgetMemo()
    {
        memo = null;
    }
    }
}

alias GenericArithmetic!(ParseTree).Arithmetic Arithmetic;

