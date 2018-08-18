#!/bin/bash

#Browser
USE_CHROME=false

#TCP port where shiny server will works. Change in run.R, as well.
SERVER_TCP_PORT=4907

#======================================================================

if [ $USE_CHROME == true ]; then
  google-chrome-stable http://127.0.0.1:$SERVER_TCP_PORT
else
  firefox http://127.0.0.1:$SERVER_TCP_PORT
fi;

