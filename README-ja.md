<table width="100%"><tr><td align="right"><a href="README.md">English</a></td></tr></table>

# Plato - mruby IoT framework
Platoは組込みシステム向けのmrubyアプリケーションフレームワークです。


# Platoのセットアップ

## 0. 事前準備

以下をセットアップして下さい。

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

## 1. Platoのダウンロード

```bash
$ cd <作業ディレクトリ>
$ git clone --recursive https://github.com/mruby-plato/plato.git
```

## 2. Plato環境のセットアップ

```bash
$ cd plato
$ make [lang]
```

|項目|概要|値|
|:-:|:--|:--|
|lang|表示言語|en / ja (デフォルト: en)|
