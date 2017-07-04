<table width="100%"><tr><td align="right"><a href="README-ja.md">日本語</a></td></tr></table>

# Plato - mruby IoT framework
The Plato is mruby application framework for embedded system.


# How to setup Plato

## 0. Advance preparation

Set up the following.

### Windows
- [CRuby](https://rubyinstaller.org/)
- [mruby](https://github.com/mruby/mruby/)
- [MinGW](http://www.mingw.org/)
- [git](https://git-for-windows.github.io/)
- [node.js](https://nodejs.org/)
- [npm](https://www.npmjs.com/)
- [Visual Studio Code](https://code.visualstudio.com/)

### Mac
- [mruby](https://github.com/mruby/mruby/)
- [git](https://git-scm.com/)
- [node.js](https://nodejs.org/)
- [npm](https://www.npmjs.com/)
- [Visual Studio Code](https://code.visualstudio.com/)

## 1. Download Plato project

```bash
$ cd <working directory>
$ git clone --recursive https://github.com/mruby-plato/mruby-plato.git
```

## 2. Setup Plato environment

```bash
$ cd mruby-plato
$ make [lang]
```

|item|remark|value|
|:-:|:--|:--|
|lang|Language for display|en / ja (default: en)|
