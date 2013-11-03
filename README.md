BattleSquare
============

This 2D shooter is made to test out network latency on shooter in general. Its primary purpose is to learn and understand network latency and how you can make a game with it.

How to Compile
--------------

First download and install a D compiler, we use DMD from here: http://dlang.org/download.html
Alternatively sometimes gdc or lcd2 are avaliable from some linux package managers, but these tend to be a few versions behind DMD.

Then simply:

<pre><code>./waf configure
./waf build</code></pre>

or on windows (you'll probably have to install python):

<pre><code>python waf configure
python waf build</code></pre>

