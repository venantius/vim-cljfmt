# vim-cljfmt

vim-cljfmt is a vim plugin for [cljfmt](https://github.com/weavejester/cljfmt), the code formatting tool for Clojure. Rather than invoking the plugin by shelling out to Leiningen, it uses a [vim-fireplace](https://github.com/tpope/vim-fireplace/) REPL connection to only format the current file. This has the advantage of sidestepping Leiningen's startup time and keeping Vim from hanging, though the first time you use it with a given REPL server there will be a slight delay as it loads the cljfmt namespace.

Demo below:

![](doc/demo.gif)

## Configuration and Usage

vim-cljfmt allows you to format the file in the current buffer with the following:

```vim
:Cljfmt
```

Of course, manually formatting files is for people who aren't lazy. So, by default, vim-cljfmt automatically does the formatting when you save. If you want to turn this off, add the following line to your `.vimrc`:

```vim
let g:clj_fmt_autosave = 0
```
Occasionally vim-cljfmt might need to be reloaded (for example, if the fireplace REPL connection is reset). Reload vim-cljfmt with the following:

```vim
:CljfmtRequire
```

## Installation

### Requirements

You'll want to have [cljfmt](https://github.com/weavejester/cljfmt) and [vim-fireplace](https://github.com/tpope/vim-fireplace/) installed, and you'll need to make sure Cljfmt is somewhere on your project's classpath. I'd recommend adding the following to your `~/.lein/profiles.clj`:

```clojure
:dependencies [[cljfmt "0.1.10"]]
```

You'll also need to have a REPL connection open through fireplace.

After that, the rest should take care of itself.

### Installing with Pathogen

Assuming you already have [Pathogen](https://github.com/tpope/vim-pathogen) installed, you should be good to go with the following:

```
cd ~/.vim/bundle && \
git clone https://github.com/venantius/vim-cljfmt.git
```

### Installing with Vundle

To install vim-cljfmt with [Vundle](https://github.com/gmarik/Vundle.vim), add the following line to your `.vimrc`:
```
Bundle 'venantius/vim-cljfmt'
```

## Other Vim + Clojure Plugins

If you like this, you should check out [vim-eastwood](https://github.com/venantius/vim-eastwood)!

## License

Copyright (c) 2015 W. David Jarvis.

Licensed under the Eclipse Public License, the same as Clojure.
