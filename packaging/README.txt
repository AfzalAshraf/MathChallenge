Cognitive Trainer (MathChallenge)
=================================

An offline brain-training suite for Windows: arithmetic drills, Vedic maths
tricks, Sudoku, Stroop, Schulte tables, Speed Grid and N-Back.

Everything runs locally. No installer, no admin rights, no network access, no
account, and nothing is written to disk - your scores live only for the current
session.


WHAT'S IN THIS ZIP
------------------
Extracting the zip gives you a single folder (MathChallenge-<version>) holding:

  MathChallenge.exe          Standalone app - double-click to play. (Recommended)
  Launch-MathChallenge.bat   Fallback launcher, runs the .ps1 script below.
  MathChallenge.ps1          The original PowerShell/WPF source.
  README.txt                 This file.
  LICENSE                    Apache License 2.0.


HOW TO RUN
----------
Option A (recommended)
  Double-click MathChallenge.exe.

Option B (if the .exe is blocked or will not start)
  Double-click Launch-MathChallenge.bat. This runs the .ps1 directly with
  PowerShell, which is useful for reading any error message.

Option C (manual)
  Right-click MathChallenge.ps1 > Run with PowerShell
  - or, from a terminal in this folder:
      powershell -ExecutionPolicy Bypass -File .\MathChallenge.ps1


REQUIREMENTS
------------
  * Windows 10 or 11 (64-bit). Windows 7/8.1 generally work but are untested.
  * .NET Framework 4.7.2 or newer (preinstalled on Windows 10 1803 and later).
  * Windows PowerShell 5.1 (built into Windows) for Options B and C.
  * A screen of about 1280x720 or larger. The window opens at 1160x820 and
    resizes from 1000x700 up to full screen.


"WINDOWS PROTECTED YOUR PC"
---------------------------
The .exe is not code-signed, so SmartScreen may warn about it on first run.
Choose "More info" > "Run anyway". To verify the download instead, compare its
SHA-256 against the checksums file published with this release:

    certutil -hashfile MathChallenge.exe SHA256


WINDOW
------
  Drag any empty area, or the title bar  Move the window
  Drag a window edge or corner           Resize (resize arrows appear at edges)
  Double-click the title bar             Maximize / restore
  Red / yellow / green dots              Close / minimize / maximize
  Right-click the window                 Reset scores, About, Exit


KEYBOARD SHORTCUTS
------------------
  Enter          Submit an answer (arithmetic, Vedic maths, brain teasers)
  D1-D9 / Numpad Fill the selected Sudoku cell (or toggle a pencil note)
  Arrow keys     Move the Sudoku selection
  N              Toggle Sudoku notes (pencil) mode
  Z              Undo the last Sudoku move
  Delete/Back    Erase the selected Sudoku cell
  Escape         Stop the current game and return to the menu


GAMES
-----
  Brain training   Schulte 5x5 and 7x7, Color Stroop, Speed Grid, N-Back (N=2)
  Vedic maths      11 Sandwich, Ghost Base, Sparkle Square, Last Stand,
                   Vedic Speed (all tricks, 60 seconds)
  Brain teasers    Water Jugs, Weight Balance, Coin Puzzle, Math Tricks
                   (120 seconds each, with hints and worked solutions)
  Sudoku           Easy (45+ clues), Medium (35 clues), Hard (25 clues);
                   3 mistakes ends the board

Answer streaks multiply your points (x2 at 5, x3 at 10, x4 at 15, x5 at 20) and
every 5 correct answers in a game levels you up.


SOURCE AND BUGS
---------------
  https://github.com/AfzalAshraf/MathChallenge
Source is Apache-2.0 licensed; see LICENSE.
