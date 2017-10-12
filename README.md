# xprof
A simple automatic profiling system and code analysis documentation-generator

Usage:

- Instrument your .c code with high-level PAPI C calls. Help yourself by viewing <b>InsSchonauerTriadBenchmark.c</b> as example (base code is <b>SchonauerTriadBenchmark.c</b>;
- Ensure your .c src file is in the main directory
- Benchmark your program by executing <b>gathering.sh NameOfProgram</b> on TARGET machine);
- Afterwards, analyze these runs locally (in a machine equipped with a python(3) and texliveonfly environments, however check <b>.dependencies</b> file) with <b>analyzer.sh NameOfProgram</b>!
