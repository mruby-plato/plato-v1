#include <stdio.h>
#include <stdlib.h>
#include "mruby.h"
#include "mruby/proc.h"
#include "mruby/array.h"
#include "mruby/variable.h"
#include "mruby/string.h"

static void
usage(const char *name)
{
  printf("Usage: %s mrb\n", name);
  puts("  port: Serial(COM) port");
  puts("  mrb:  mruby application binary (MRB)");
  exit(1);
}

static mrb_value
mrb_str_crc16(mrb_state *mrb, mrb_value self)
{
  extern uint16_t calc_crc_16_ccitt(const uint8_t*, size_t, uint16_t);
  return mrb_fixnum_value(calc_crc_16_ccitt((const uint8_t*)RSTRING_PTR(self), RSTRING_LEN(self), 0));
}

int
main(int argc, char *argv[])
{
  extern uint8_t appbin[];
  mrb_state *mrb;
  mrb_value args, v;
  int i;

  if (argc < 3) usage(argv[0]);

  /* open mruby VM */
  mrb = mrb_open();

  /* add String#crc16 */
  mrb_define_method(mrb, mrb_class_get(mrb, "String"), "crc16", mrb_str_crc16, MRB_ARGS_NONE());

  /* set ARGV */
  args = mrb_ary_new(mrb);
  for (i=1; i<argc; i++) {
    mrb_ary_push(mrb, args, mrb_str_new_cstr(mrb, argv[i]));
  }
  mrb_vm_const_set(mrb, mrb_intern_lit(mrb, "ARGV"), args);
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$0"), mrb_str_new_cstr(mrb, argv[0]));

  /* run mrbwriter application */
  v = mrb_load_irep(mrb, appbin);
  if (mrb->exc) {
    mrb_p(mrb, mrb_funcall(mrb, mrb_obj_value(mrb->exc), "inspect", 0));
  }

  mrb_close(mrb);

  return 0;
}
