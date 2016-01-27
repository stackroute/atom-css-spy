#CSS-SPY
###(In Beta)
A package to suggest CSS classes in HTML projects


CSS-SPY goes through CSS files linked in open HTML files within Atom, identifies classes and uses these to auto-suggest the appropriate class in HTML. CSS-SPY automatically rebuilds its list of classes to be suggested either when the CSS files are edited or if a change in the linked files is made. Suggestions are available only in HTML files. CSS-SPY is a service provider to and builds on the capabilities of auto complete plus. When CSS-SPY is turned off, auto-complete plus is given a higher priority.

## Installation

* In Atom, open *Preferences* (*Settings* on Windows)
* Go to *Install* section
* Search for `css-spy` package. Once it found, click `Install` button to install package.

### Manual installation

You can install the latest CSS-SPY version manually from console:

```bash
cd ~/.atom/packages
git clone https://github.com/stackroute/atom-css-spy
cd atom-css-spy
npm install
```

Then restart Atom editor.

##Key bindings:

CTRL-ALT-Y : toggles CSS-SPY on or off.
