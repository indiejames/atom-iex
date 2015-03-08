# iex package

This package provides Elixir developers with the ability to run an Elixir IEx
(REPL) session in an Atom window. It has only been tested on OS X and is
unlikely to work properly (or at all) on other platforms.

This package is based on the [Term2 Atom package](https://atom.io/packages/term2) with customizations specific to IEx, including key bindings to execute code and tests in the REPL.

## Executing commands
Aside from typing directly in the IEx session, the plugin provides menu actions
to improve workflow:


'Open IEx session in New Tab' -> 'iex:open'
'Open IEx session in Bottom Pane' -> 'iex:open-split-down'
'Open IEx session in Top Pane' -> 'iex:open-split-down'
'Open IEx session in Right Pane' -> 'iex:open-split-down'
'Open IEx session in Left Pane' -> 'iex:open-split-down'
'Run all tests' -> 'iex:run-all-tests'
'Run all tests in file' -> 'iex:run-tests'
  Run all tests in the currently open file
'Run test' -> 'iex:run-test'
  Click in a test definition before selecting this to run that test.
'Execute selected in IEx' -> 'iex:paste'
'Reset' -> 'iex:reset'
  Stops the application, compiles any changed files with mix, then restarts
  the application.

It is _highly suggested_ that you add keybindings for these action (see below).


## Keybindings
Add the following keybindings to your keymap (Atom menu - Open Your Keymap)
(customize these as needed)

    'atom-workspace':
      'ctrl-tab': 'enhanced-tabs:toggle'
      'cmd-alt-l': 'iex:open'
      'cmd-alt-l down': 'iex:open-split-down'
      'cmd-alt-l up': 'iex:open-split-up'
      'cmd-alt-l left': 'iex:open-split-left'
      'cmd-alt-l right': 'iex:open-split-right'
      'cmd-alt-e': 'iex:reset'
      'cmd-alt-a': 'iex:run-all-tests'

    '.editor':
      'cmd-alt-x': 'iex:run-tests'
      'cmd-alt-j': 'iex:run-test'
      'cmd-alt-b': 'iex:pipe'

## Fonts
You can set the font size by adding the following to your Atom stylesheet Atom menu - Open your stylesheet). Change the font, font-size, and heights as desired.

    .iex {
      .terminal {
        font-family: Menlo, Monaco, Inconsolata, monospace;
        font-size: 14px;

         div {
          height: 18px;
          line-height: 18px;

        }
      }
    }
