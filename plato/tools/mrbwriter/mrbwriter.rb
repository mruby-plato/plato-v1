#
# mrbwriter.rb - mruby application writer
#
# Usage: ruby mrbwriter.rb <app_path>
#   app_path: Path name of mruby application directory.
#
require "open3"

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

home_dir, exe = ($platform == :windows) ? ['c:', '.exe'] : [Dir.home, '']
plato_dir = File.join(home_dir, 'plato')
tool_dir = File.join(plato_dir, '.plato', 'tools')
writer = File.join(tool_dir, 'mrbwriter' + exe)

app_name = ARGV[0] ? ARGV[0] : 'app1'
app_dir = File.join(plato_dir, app_name)

# Find Virtual COM Port
print 'Search COM port ... '
com_list = case $platform
when :windows # COM*
  require 'win32ole'
  wmi = WIN32OLE.new("WbemScripting.SWbemLocator").ConnectServer()
  coms = []
  wmi.ExecQuery("SELECT * FROM Win32_PnPEntity").each {|com|
    coms << $1 if com.Name =~ /\((COM\d+)\)/
  }
  coms
when :mac   # /dev/tty.usb*
  Dir.glob('/dev/tty.usb*')
when :linux # /dev/ttyACM* or /dev/ttyUSB*
  Dir.glob("/dev/ttyACM*\0/dev/ttyUSB*")
else
  []
end
if com_list.empty?
  puts 'not found.'
  exit(1)
end
vcp = com_list[0]
puts "#{vcp} found."

# Make application
print 'Build application ... '
cmd = "cd #{app_dir} && rake"
Open3.popen3(cmd) do |i, o, e, w|
  i.close
  o.each_char do |c| print c end
  e.each do |line| puts line end
end
puts 'done.'

# Get application binary's path
bins = [
  File.join(app_dir, 'bin', "*.mrb"),
  File.join(app_dir, 'bin', "*.ezb")
].join("\0")
app_bin = Dir.glob(bins)[0]

# Transfer an application binary via VCP
cmd = "#{writer} #{vcp} #{app_bin}"
Open3.popen3(cmd) do |i, o, e, w|
  i.close
  o.each_char do |c| print c end
  e.close #each do |line| puts line end
end
