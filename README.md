BattleSquare
============

This 2D shooter is made to test out network latency on shooter in general. Its primary purpose is to learn and understand network latency and how you can make a game with it.

How to Compile
--------------

First download and install a D compiler, we use DMD from here: http://dlang.org/download.html
Alternatively sometimes gdc or lcd2 are avaliable from some linux package managers, but these tend to be a few versions behind DMD.

You will need libzmq (version 3), SDL2, and SDL2_image runtime libraries installed.

Then simply:

<pre><code>sh ./build-client.sh</code></pre>

or on windows:

<pre><code>build-client-win32.bat</code></pre>

The binaries appear in the ./build folder.
