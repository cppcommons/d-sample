#!bash -uvx
export PATH=/c/D/dmd2/windows/bin:$PATH
dmd -w -m32       -wi -O -release -noboundscheck -lib -ofpegged-dm32.lib pegged/peg.d pegged/grammar.d pegged/parser.d pegged/introspection.d pegged/dynamic/grammar.d pegged/dynamic/peg.d
dmd -w -m32mscoff -wi -O -release -noboundscheck -lib -ofpegged-ms32.lib pegged/peg.d pegged/grammar.d pegged/parser.d pegged/introspection.d pegged/dynamic/grammar.d pegged/dynamic/peg.d
