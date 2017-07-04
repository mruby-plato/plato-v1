# Application receiver for enzi
class AppReceiver
  BOARD_NAME    = 'enzi'
  DATA_TYPE     = 'H'     # Hex format
  FIRM_VERSION  = '1.05'
	CMDSTART      = '$'
	RSPSTART      = '#'
	CMDVERSION    = 'V'
	CMDSIZE       = 'S'
	SW            = A3      # BTA SW on WhiteTiger
  APPFILE       = 'enzi.ezb'
  BUFSIZE       = 1000
  MODE_WAIT     = 1000    # Wait time

  def initialize
    # @tmo_write_mode = 1000
    @ready_word     = 'Enter application write mode ...'
  end

  def get_line
    while true
      ln = gets.strip
      break if ln.size > 0
    end
    ln
  end

  def hex2bin(hex)
    bin = ""
    for i in 0...hex.size/2
      h = hex[i*2, 2]
      bin << sprintf("%c", h.to_i(16))
    end
    bin
  end

  # receive and write application binary
	def receive
		# send ready
		puts @ready_word

		# initialial sequence
		hexsize = 0
		while cmd = get_line
			case cmd[0]
			when CMDSTART
				puts RSPSTART
			when CMDVERSION
				#  12345678901234567890123456789012
				# "enzi            H1.0.5          "
        puts sprintf("%-16s%c%-15s", BOARD_NAME, DATA_TYPE, FIRM_VERSION)
			when CMDSIZE  # 'Sxxxx'
				hexsize = cmd[1..-1].to_i(16)
				puts ""
				break
			else
				raise "Invalid command #{cmd.inspect}"
			end
		end

		# receive and write application binary
    bin = ''
    binsize = (hexsize / 2).to_i
    while bin.size < binsize
      hex = get_line.strip
      0.step(hex.size-1, 2) {|i|
        bin << (hex[i,2].to_i(16).chr)
      }
      puts "#{bin.size * 2}/#{hexsize}"
    end

		# check CRC16 checksum
		crc = get_line
    # TODO: check
    # puts crc

    # Overwrite application binary file
    f = File.open(APPFILE, 'w+')
    bin.each_char {|b| f.putc b}
    f.flush
    f.close

    # notify completion
    puts crc
    delay(500)

    # software reset
    system_reset
  end
end

# Check write mode
tout = millis + AppReceiver::MODE_WAIT
while tout > millis
  if digitalRead(AppReceiver::SW) == LOW
    AppReceiver.new.receive
    break # dummy
  end
  delay(1)
end

# # 
# # application (for test)
# #
# puts "application start..."
# 5.times {|i|
#   puts '*' * (i+1)
# }

# Next sequence
# - Initialize mrbgems.
# - Run user application.
