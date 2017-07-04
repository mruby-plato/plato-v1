#!/usr/bin/env ruby
#
# mkenv.rb - Make 'Plato' environment image
#
# Usage: ruby mkenv.rb <lang> [instdir]
#   lang:     Language ID (en|ja)
#   instdir:  'Plato' install directory (default:'./plato')
#

require 'fileutils'

def _cp(src, dst)
  FileUtils.cp_r(src, dst, {:remove_destination => true})
rescue => e
  puts "warning: #{e}"
end

PLATO_UI = 'plato-ui'

srcroot = File.join(File.dirname($0), '..', '..')
instdir = ARGV[1]

lang = ARGV[0].to_s.downcase
unless lang == 'en' || lang == 'ja'
  puts "Unsupport language #{lang.inspect}" unless lang.empty?
  puts <<"EOS"
Usage: ruby #{$0} <lang> [instdir]
  lang: Language ID (en|ja)
  Instdir: 'Plato' install directory
EOS
  exit(1)
end

# Get platform
$platform = case RUBY_PLATFORM.downcase
when /mswin(?!ce)|mingw|cygwin|bccwin/
  :windows
when /darwin/
  :mac
when /linux/
  :linux
else
  :other
end
$exe = $platform == :windows ? '.exe' : ''

if instdir.nil? || instdir.empty?
  if $platform == :windows
    instdir = 'c:/plato'
  else
    instdir = File.join(Dir.home, 'plato')
  end
end

FileUtils.mkdir_p(instdir)

# make sub projects
## mrbwriter
puts 'make mrbwriter...'
`make -C #{File.join(srcroot, 'plato', 'tools', 'mrbwriter')}`
## Plato UI
puts 'build Plato UI...'
`ruby #{File.join(srcroot, PLATO_UI, 'build.rb')} #{lang}`

# $PLATO/.plato
#   plato.sh
#   plato.bat
puts 'copy shells...'
[ File.join(srcroot, 'plato', 'plato.bat'),
  File.join(srcroot, 'plato', 'plato.sh')
].each {|file|
  _cp(file, File.join(instdir, File.basename(file)))
}

# $PLATO/.plato/tools
#   boxmrbgem.rb
#   enzic
#   enzic.exe
#   mkmrblib.rb
#   mrbwriter.rb
#   mrbwriter.exe / mrbwriter
#   mrbwriter.cfg
#   prjmaker.rb
#   receiver.rb
puts 'copy tools...'
_plato_dir = File.join(instdir, '.plato')
tools_dir = File.join(_plato_dir, 'tools')
FileUtils.rm_rf(tools_dir)
FileUtils.mkdir_p(tools_dir)
[ File.join(srcroot, 'plato', 'tools', 'boxmgem', 'boxmrbgem.rb'),
  File.join(srcroot, 'plato', 'tools', 'boxmgem', 'mkmrblib.rb'),
  File.join(srcroot, 'plato', 'tools', 'mrbwriter', 'mrbwriter.rb'),
  File.join(srcroot, 'plato', 'tools', 'mrbwriter', 'mrbwriter' + $exe),
  File.join(srcroot, 'plato', 'tools', 'mrbwriter', 'mrbwriter.cfg'),
  File.join(srcroot, 'plato', 'tools', 'mrbwriter', 'receiver.rb'),
  File.join(srcroot, 'plato', 'tools', 'prjmaker', 'prjmaker.rb'),
  File.join(srcroot, 'plato', 'tools', 'bin', 'enzic' + $exe)
].each {|file|
  _cp(file, File.join(tools_dir, File.basename(file)))
}
# tools/mgemlist
_cp(File.join(srcroot, 'plato', 'tools', 'boxmgem', 'mgemlist'), File.join(tools_dir, 'mgemlist'))

# $PLATO/.plato/prjbase
#   Rakefile
#   *.erb
#   user_build_config.rb
puts 'copy skelton files...'
prjbase_src = File.join(srcroot, 'plato', 'tools', 'prjmaker', 'prjbase')
FileUtils.rm_rf(File.join(_plato_dir, 'prjbase'))
_cp(prjbase_src, _plato_dir)

# $PLATO/mrbgems
puts 'copy mrbgems...'
mrbgem_dst = File.join(instdir, 'mrbgems')
FileUtils.rm_rf(mrbgem_dst)
_cp(File.join(srcroot, 'mrbgems'), mrbgem_dst)

# $PLATO/.plato/plato
puts 'copy Plato UI...'
case $platform
when :windows
  ['plato-win32-ia32']
when :mac
  ['plato-darwin-x64']
when :linux
  ['plato-linux-ia32']  # + ['plato-linux-x64']
end.each {|target|
  plato_src = File.join(srcroot, PLATO_UI, 'bin', lang, target)
  plato_dst = File.join(_plato_dir, target)
  FileUtils.rm_rf(plato_dst)
  _cp(plato_src, plato_dst)
}

# $HOME/.vscode/extensions
puts 'copy VSCode extensions...'
EXTNAME = 'mruby-plato'
home_dir = ($platform == :windows) ? ENV['USERPROFILE'] : Dir.home
vscext_dst = File.join(home_dir, '.vscode', 'extensions', EXTNAME)
vscext_src = File.join(srcroot, 'plato', 'tools', 'vscode-extension', EXTNAME)
FileUtils.rm_rf(vscext_dst)
`make -C #{vscext_src}`
FileUtils.mkdir_p(File.join(vscext_dst, 'out', 'src'))
_cp(File.join(vscext_src, 'package.json'), vscext_dst)
_cp(File.join(vscext_src, 'out', 'src', 'extension.js'), File.join(vscext_dst, 'out', 'src'))
# _cp(File.join(vscext_src, 'images'), vscext_dst)

# Create shortcut (Windows only)
if $platform == :windows
  `wscript #{File.join(File.dirname($0), 'shortcut.vbs')} #{instdir}`
end

puts $0 + ' completed.'
