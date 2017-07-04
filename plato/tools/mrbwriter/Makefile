APP = mrbwriter
MRUBY = ../../../mruby
MRBC = $(MRUBY)/bin/mrbc
INCDIR = $(MRUBY)/include
LIBDIR = $(MRUBY)/build/host/lib

all: $(MRBC)
	$(MRBC) -Bappbin app.rb
	gcc -I $(INCDIR) -L $(LIBDIR) -o $(APP) $(APP).c app.c -lmruby -lm

clean:
	make -C $(MRUBY) clean
	rm $(APP)

$(MRBC): user.gembox user_build_config.rb
	MRUBY_CONFIG=../plato/tools/mrbwriter/user_build_config.rb make -C $(MRUBY)
