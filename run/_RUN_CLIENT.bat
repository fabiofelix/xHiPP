
REM Browser
SET USE_CHROME=true

REM TCP port where shiny server will works. Change in run.R, as well.
SET SERVER_TCP_PORT=4907

REM ======================================================================

if %USE_CHROME% EQU true (
  start chrome http://127.0.0.1:%SERVER_TCP_PORT%
) ELSE  (
  start firefox http://127.0.0.1:%SERVER_TCP_PORT%
  REM start iexplore http://127.0.0.1:%SERVER_TCP_PORT%
  REM start microsoft-edge:"http://127.0.0.1:%SERVER_TCP_PORT%"
)

