# mrbwriter - mruby binary writer

## How to make
### at 1st
```
$ git clone https://github.com/mruby-plato/mruby-plato.git
$ cd mruby-plato
$ git submodule init
$ git submodule update
$ cd mrbwriter
$ make
```
### at 2nd and subsequent
```
$ cd mruby-plato/mrbwriter
$ make
```

## Usage
```
mrbwriter COM MRB
```
- COM: serial port name
- MRB: mruby application binary  

### example
```
$ ./mrbwriter /dev/tty.usbmodem1411 app.mrb
```

----
# binary receiver (receiver.rb)

## Application structure
|order|module|
|:-:|:--|
|1|receiver.rb|
|2|mrbgems (.rb only)|
|3|user application (app.rb)|

## Write operation
1. Compile application and copy binary to microSD card.
2. Insert microSD card to microSD slot on enzi board.
3. Connect PC and enzi board using USB cable.
4. Run **mrbwriter** on PC.
5. Press and hold the BTA switch on WhiteTiger
6. Press enzi's RESET button (with BTA holding)
7. Release BTA switch when writer started.
