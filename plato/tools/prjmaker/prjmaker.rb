#
# prjmaker.rb - Plato project maker
# 
# ruby prjmaker <app.cfg> <mgem.lst>
#   app.cfg:  application configuration file.
#   mgem.lst: mrbgems list file.
#
require 'fileutils'
require 'json'
require 'erb'
require 'resolv'

# Check argument
if ARGV.size < 2
  puts <<"EOS"
Usage: #{$0} app.cfg mgem.lst
  app.cfg:  application configuration file
  mgem.lst: mrbgems list file
EOS
  exit(1)
end

appcfg, mgemlist = ARGV

# Get Plato environment ($HOME/.plato/plato.cfg)
begin
  platoenv = File.join(Dir.home, '.plato', 'plato.cfg')
  env = JSON::parse(File.read(platoenv))
rescue
  env = {}
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

# Get project root directory
# homedir = (RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/) ? 'C:' : Dir.home
homedir = $platform == :windows ? 'C:' : Dir.home
platoroot = env['instdir'] ? env['instdir'] : File.join(homedir, 'plato')
# Get project base directory
$prjbase = File.join(platoroot, '.plato', 'prjbase')

# Load application configuration
cfg = JSON::parse(File.read(appcfg))
action = cfg['action'] ? cfg['action'] : {}

# Make project directories
prjdir = File.join(platoroot, cfg['project'])
bindir = File.join(prjdir, 'bin')
libdir = File.join(prjdir, 'mrblib')
[prjdir, bindir, libdir].each {|dir|
  FileUtils.mkdir_p(dir) unless File.exist?(dir)
}

# Copy files into project directory
[ appcfg,
  File.join($prjbase, 'Rakefile'),
  File.join($prjbase, 'user_build_config.rb')
].each {|fn|
  FileUtils.cp(fn, File.join(prjdir, File.basename(fn)))
}
# selected-mrbgems.lst
FileUtils.cp(mgemlist, File.join(prjdir, 'selected-mrbgems.lst'))

#
# Make app.rb
#

# application type
# rapid:    'trigger' or 'server'
# advanced: TBD
app_type = cfg['app_type']

# target board
board = cfg['target_board']

# communication device
compara = cfg['com_para']
comcon = nil
btb = cfg['option_board'].inject(false) {|b,v| b |= (v['model'] == 'White-Tiger')} ? ' GPIO::BTB' : ''
case cfg['com_dev']
when 'BLE'
  comcls = 'PlatoDevice::RN4020'
  compara = nil
  comcon = nil
when 'ZigBee'
  comcls = 'PlatoDevice::XBee'
  compara = nil
  comcon = "@comdev.config#{btb}"
when 'WiFi'
  comcls = 'PlatoDevice::XBeeWiFi'
  compara = nil
  comcon = "@comdev.config#{btb}"
when 'Ethernet'
  comcls = 'PlatoDevice::Ethernet'
  compara = nil
  comcon = nil
else
  comcls = nil
  compara = nil
  comcon = nil
end
comdev = comcls ? "#{comcls}.open" : 'nil'

# sensing period [sec]
if sensing_period = cfg['sensing_period']
  sensing_period = sensing_period.to_i * 1000
end

# send period [min]
if send_period = cfg['send_period']
  send_period = send_period.to_i * 60 * 1000
end

# interval [sec]
if interval = action['interval']
  if sensing_period != 0
    interval = interval.to_f / (sensing_period.to_f / 1000.0)
  end
  interval = 1 if interval < 1
end

# trigger
if trigger = cfg['trigger']
  trigger = 'if' + trigger.inject([]) {|tri, t|
    # TODO: fix app.cfg key unmatch
    key = case t['key'][0,4]
    when 'tmp'; 'temp'
    when 'hum'; 'humi'
    when 'lx';  'illu'
    else;       t['key'][0,4]
    end
    # add trigger
    v = t['value']
    v = ((v.to_f - 32) * 5 / 9).round(3) if key == 'temp' && t['unit'] == 'F' # F->C
    tri << t['and_or'] << key << t['operator'] << v
  }.join(' ')
end

def time(t)
  return nil unless t
  tm = t.split(':')
  (tm[0].to_i * 10000 + tm[1].to_i * 100 + tm[2].to_i).to_s
end

if onetime = action['continuous']
  onetime = eval(onetime.downcase) ? nil : 'return nil if presig'
  if st = action['start']
    st = time(st)
  end
  if et = action['end']
    et = time(et)
  end
end

check_time_zone = nil
within_term = nil
if st || et
  check_time_zone = 'return false unless within_term?'
  within_term = <<"EOS"
  def within_term?
    t = @rtc.get_time
    now = t[3] * 10000 + t[4] * 100 + t[5]
    #{"return false if now<#{st}" if st}
    #{"return false if now>#{et}" if et}
    true
  end
EOS
end

# Make action script
server_uri = ''
case action['action_type']
when 'send_server'
  action_script = <<EOS
    # send to server
    @comdev.puts(values)
EOS
when 'ifttt'
  # server_uri
  server_uri = <<"EOS"
  SERVER_FQDN = 'maker.ifttt.com'
  URI = "/trigger/#{action['ifttt_event']}/with/key/#{action['ifttt_key']}"
EOS
  action['data_type'] = 'JSON'  # JSON data only
  protcol = (board == 'enzi') ? '' : "\'http\', "
  action_script = <<"EOS"
    # send to IFTTT service
    request = {'Content-Type'=>'Application/json'}
    request['Body'] = values
    begin
      ifttt = SimpleHttp.new(#{protcol}SERVER_FQDN, 80)
      ifttt.post(URI, request)
    rescue
    end
EOS
when 'blocks'
  # server_uri
  fqdn = "magellan-iot-#{action['blocks_entry']}-dot-#{action['blocks_prjid']}.appspot.com"
  blocks_addr = Resolv.getaddress(fqdn)
  server_uri = <<"EOS"
  SERVER_FQDN = '#{fqdn}'
  URI = '/'
  #{comcls}.setaddress(SERVER_FQDN, '#{blocks_addr}')
EOS
  # action
  action['blocks_msgtyp'] = action['blocks_msgtyp']
  json_s = <<"EOS"
{\\"api_token\\":\\"#{action['blocks_token']}\\",
\\"logs\\":[{
\\"type\\":\\"#{action['blocks_msgtyp']}\\",\\"attributes\\":
EOS
  json_s.gsub!("\n", '')
  json_e = '}]}'
  action['data_type'] = 'JSON'
  protcol = (board == 'enzi') ? '' : "\'http\', "
  action_script = <<"EOS"
    # send to MAGELLAN BLOCKS
    request = {'Content-Type'=>'Application/json'}
    request['Body'] = "#{json_s + '#{values}' + json_e}"
    begin
      blks = SimpleHttp.new(#{protocol}SERVER_FQDN, 80)
      blks.post(URI, request)
    rescue
    end
EOS
when 'gpio_out'
  action['data_type'] = 'NONE'  # data not use
  low = (action['gpio_value'].to_i == 0)
  action_script = <<"EOS"
    # write to GPIO port
    DigitalIO.new(GPIO::#{action['gpio_pin']}).write(edge == :positive ? GPIO::#{low ? "LOW" : "HIGH"} : GPIO::#{low ? "HIGH" : "LOW"})
EOS
else # 'free_text'
  if action_script = action['action_script']
    action_script = action_script.lines.map {|line|
      '    # ' + line
    }.join + "\n"
  end
end

# Make values
values = nil
items = []
case action['data_type']
when 'JSON'
  action['values'].each_with_index {|h, i|
    if action['action_type'].include?('ifttt')
      # IFTTT: "value1"〜"value3"
      key = "value#{i+1}"
    elsif action['action_type'].include?('blocks')
      # BLOCKS: "temperture"/"humidity"/"illuminance"
      key = h['title']
    else
      if key = h.values[0]
        key = key.gsub(/^@/, '').gsub('.', '_')[0,4]
      end
    end
    items << ('\"' + key + '\":' + '\"#{' + (app_type == 'trigger' ? h.values[0][0,4] : h.values[0]) + '}\"') if key
  }
  if action['action_type'].include?('blocks')
    devinfo = action['blocks_devinfo']
    devinfo = "@comdev.mac_address" if devinfo.size == 0
    items << "\\\"devinfo\\\":\\\"#{devinfo}\\\""
  end
  values = '"{' + items.join(',') + '}"'
when 'CSV'
  action['values'].each {|h|
    items << '#{' + (app_type == 'trigger' ? h.values[0][0,4] : h.values[0]) + '}'
  }
  values = '"' + items.join(',') + '"'
when 'NONE'
  values = "''"
end

# negative edge
negative_edge = ''
if action['gpio_not_occur'].to_i > 0
  negative_edge = "      app.action(v, :negative) if trigger == :negative\n"
end

# Write app.rb
appsrc = ERB.new(File.read(File.join($prjbase, app_type + '.erb'))).result
app = File.join(prjdir, 'app.rb')
File.write(app, appsrc)

# Launch Visual Studio Code
code = "code"
if $platform == :mac
  if `which code`.chomp.size == 0
    code = "open -a /Applications/Visual\\ Studio\\ Code.app"
  end
end
`#{code} #{platoroot} #{app}`
