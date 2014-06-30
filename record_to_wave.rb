require "json"
require "coreaudio"

dev = CoreAudio.default_input_device
buf = dev.input_buffer(1024)

wav = CoreAudio::AudioFile.new("music#{Time.now.strftime('%F-%H%M%S')}.m4v", :write, :format => :m4a,
                               :rate => dev.nominal_rate,
                               :channels => dev.input_stream.channels)

samples = 0
th = Thread.start do
  loop do
    w = buf.read(4096)
    mutecount = 0
    while w == NArray.sint(2, 4096) do
      mutecount += 1
      samples += w.size / dev.input_stream.channels
      wav.write(w)
      w = buf.read(4096)
    end
    p mutecount if mutecount != 0
    if mutecount > 10 then
        wav.close
        filename = "music#{Time.now.strftime('%F-%H%M%S')}.m4v"
        p filename
        p JSON.load(`wget http://www.stardigio.com/playingtop?toppid=401 -O-`)[1]
        wav = CoreAudio::AudioFile.new(filename, :write, :format => :m4a,
                               :rate => dev.nominal_rate,
                               :channels => dev.input_stream.channels)
        wav.write(NArray.sint(2, 4096))
        wav.write(w)
        w = buf.read(4096) while w == NArray.sint(2, 4096)
    end
    samples += w.size / dev.input_stream.channels
    wav.write(w)
  end
end

buf.start;
$stdout.print "RECORDING..."
$stdout.flush

close_time = Time.now + (60 * 60 * 4)
sleep 1 while Time.now < close_time

buf.stop
$stdout.puts "done."
th.kill.join

wav.close

puts "#{samples} samples read."
puts "#{buf.dropped_frame} frame dropped."
