#
# mrbwriter - app.rb
#

$DEBUG = true

module Kernel
  def print(*args)
    i = 0
    len = args.size
    while i < len
      __printstr__ args[i].to_s
      i += 1
    end
  end

  def puts(*args)
    i = 0
    len = args.size
    while i < len
      s = args[i].to_s
      __printstr__ s
      __printstr__ "\n" if (s[-1] != "\n")
      i += 1
    end
    __printstr__ "\n" if len == 0
    nil
  end
end

# Common definitions
CMDSTART    = '$'   # Start transmission
RSPSTART    = '#'
CMDVERSION  = 'V'   # Get version
CMDHEXSIZE  = 'S'   # Encoded binary size
LEN_TARGET  = 16    # Length of target name
LEN_VERSION = 16    # Length of version
DT_HEX      = 'H'   # HEX data type
DT_B64      = 'B'   # Base64 date type
APPNAME     = 'mrbwriter'
CONFIG_FILE = $0.gsub('.exe', '') + '.cfg'
COMM_RETRY  = 5
RETRY_DELAY = 300 * 1000  # 300ms

# MRBWriter class
class MRBWriter
  # Configuration data keys
  KEY_BAUD = "baudrate"
  KEY_DBIT = "databit"
  KEY_SBIT = "stopbit"
  KEY_PARI = "parity"
  KEY_TERM = "term"
  KEY_BLKS = "data_block_size"
  KEY_BRDY = "board_ready"

  # Default environment-dependent definitions
  DEF_CONFIG = {
    KEY_BAUD => 9600,
    KEY_DBIT => 8,
    KEY_SBIT => 1,
    KEY_PARI => 0,
    KEY_TERM => "\n",
    KEY_BLKS => 80,
    KEY_BRDY => nil
  }

  attr_reader :cfg

  def initialize
    @sp = nil
    @cfg = {}
  end

  def load_config(cfgfile)
    @cfg = {}
    begin
      File.open(cfgfile, 'r') {|f|
        json = f.read
        @cfg = JSON::parse(json)
      }
    rescue
    end
    DEF_CONFIG.each {|k, v| @cfg[k] = v unless @cfg.keys.include?(k)}
    @cfg
  end

  def open_comm(comm)
    COMM_RETRY.times {
      begin
        @sp = SerialPort.new(comm, cfg[KEY_BAUD], cfg[KEY_DBIT],
                cfg[KEY_SBIT], cfg[KEY_PARI]) unless @sp
        break
      rescue
      end
      usleep(RETRY_DELAY)
    }
    raise "Cannot open #{comm}" unless @sp
  end

  def comm_opened?
    @sp
  end

  def close_comm
    @sp.close if @sp
    @sp = nil
  end

  def wait_ready
    while cfg[KEY_BRDY]
      break if recv == cfg[KEY_BRDY]
    end
  end

  def send(cmd)
    puts ">>#{cmd}" if $DEBUG
    @sp.puts cmd + cfg[KEY_TERM]
  end

  def recv
    rsp = @sp.gets.chomp
    puts "<<#{rsp}" if $DEBUG
    rsp
  end

  def read(len=nil)
    len ? @sp.read(len) : @sp.read
  end

  def send_recv(cmd)
    rsp = ''
    cmds = cmd.size <= cfg[KEY_BLKS] ? [cmd] : cmd.scan(/.{1,#{cfg[KEY_BLKS]}}/)
    progress = cmds.size > 1 ? '.' : ''
    cmds.each_with_index {|dt, i|
      send(dt)
      print progress if !$DEBUG && i%10 == 0
      rsp += recv
    }
    rsp
  end
end

# initialize
bin = nil

# get arguments
comm, mrb, $DEBUG = ARGV

writer = MRBWriter.new

# configure
writer.load_config(CONFIG_FILE)

# read binary file
begin
  File.open(mrb, "rb") {|f| bin = f.read}
rescue
  raise "Cannot read application binary file. (#{mrb})"
end

begin
  puts "*** mrbwriter ***"
  puts "Waiting for transmission mode."

  # open serial port
  writer.open_comm(comm)

  # wait board ready
  writer.wait_ready

  print "Start transmission.\nTransfering"

  # start transmission
  writer.send(CMDSTART)
  loop {
    break if writer.recv == RSPSTART
  }

  # get version information
  ver = writer.send_recv(CMDVERSION)
  target  = ver[0, LEN_TARGET].strip
  version = ver[LEN_TARGET, LEN_VERSION].strip
  dt = version[0]

  # check version
  puts "<<target=#{target}\n<<version=#{version}" if $DEBUG
  # TODO

  # encode binary
  case dt
  when DT_B64
    puts "Data format: Base64" if $DEBUG
    enc = Base64.encode(bin)
  when DT_HEX
    puts "Data format: HEX" if $DEBUG
    enc = bin.chars.inject('') {|s, b| s << sprintf("%02X", b.ord & 0xff)}
  else
    raise "Unknown data type '#{dt}'"
  end
# puts ">>#{enc}" if $DEBUG

  # send encoded binary size
  writer.send_recv(CMDHEXSIZE + enc.size.to_s(16).upcase)

  # send binary
  writer.send_recv(enc)

  # puts "\nVerifying."
  puts ""

  # send CRC16 sum
  crc = sprintf("%04X", bin.crc16);
  puts "Writing."
  writer.send_recv(crc)

  # # Serial monitor (for test)
  # loop {
  #   begin
  #     writer.open_comm(comm) unless writer.comm_opened?
  #     loop {
  #       print writer.read(1)
  #     }
  #   rescue => e
  #     writer.close_comm
  #   end
  # }

rescue => e
  raise e
ensure
  writer.close_comm
  puts "End transmission."
end
