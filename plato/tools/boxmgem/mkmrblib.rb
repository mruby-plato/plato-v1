#!/usr/bin/env ruby
#
# mkmrblib.rb - make mrbgems.rb by selected mrbgem list (mrbgems.lst)
#
# Usage: ruby mkmrblib.rb <work-path>
#   work-path: Working directory path.
#
require 'fileutils'
MGEMLIST = 'mrbgems.lst'

WORKPATH = ARGV[0] ? ARGV[0] : '.'

$srcpath = WORKPATH
$dstfile = File.join(WORKPATH, 'mrblib', 'mrbgems.rb')

# $plato_root = File.join(Dir.home, 'plato')
$plato_root = File.join(File.dirname(__FILE__), '..', '..')
$mgem_root = File.join($plato_root, 'mrbgems')

begin
  mgems = File.open(File::join($srcpath, MGEMLIST), 'r') {|f| f.readlines}
rescue => e
  puts e
  exit(-1)
end

# remove target file
FileUtils.rm_f($dstfile)

rbs = mgems.inject([]) {|s, mgem|
  s += Dir.glob(File::join($mgem_root, mgem.chomp, 'mrblib') + '/*.rb')
}
# p rbs

begin
  File.open($dstfile, "w+") {|out|
    mgems.each {|mgem|
      Dir.glob(File::join($mgem_root, mgem.chomp, 'mrblib') + '/*.rb').each {|rb|
        out.write(File.read(rb))
        out.puts ''
      }
    }
  }
rescue => e
  puts e
  exit(-2)
end
