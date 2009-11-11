jff2dot
=======
I was taking "Models of Computation" and I had to make a bunch of automata. Typing out the machines as Graphviz files in Vim only lasted so long. I found JFlap's layout system to be a little lacking, and wrote a program to convert JFlap DFAs into dot files. As the class progressed the program got support for PDAs and Turing Machines.

Now I'm in "Theoretical Computer Science", the graduate version of "Models of Computation", and this program is still useful so I'm posting it somewhere.

Requirements
------------
jff2dot requires hpricot installed through RubyGems.

Usage
-----
Run `jff2dot.rb [jflap.jff] > [graphviz.dot]` to convert jflap.jff(a JFlap 4 file) into graphviz.dot(a Graphviz dot file).
