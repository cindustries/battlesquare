#!/bin/bash
dmd -odbuild -ofbattlesquare-client -debug -g -unittest -Isrc/battlesquare-client/ -Isrc/DerelictSDL2/ -Isrc/DerelictUtil/ src/battlesquare-client/*/* src/Derelict*/*/*/* -L-ldl