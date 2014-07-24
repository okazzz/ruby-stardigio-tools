#!/usr/bin/ruby
#
require 'json'
require 'taglib'
require 'coreaudio'

dev = CoreAudio.default_input_device
buf = dev.input_buffer(1024)

playing_info = nil
filename = "music#{Time.now.strftime('%F-%H%M%S')}_start.m4a"
wav = CoreAudio::AudioFile.new(filename, :write, :format => :m4a,
                               :rate => dev.nominal_rate,
                               :channels => dev.input_stream.channels)

samples = 0
th = Thread.start do
  Silent = NArray.sint(dev.input_stream.channels, 4096)
  mutecount = 0

  loop do
    w = buf.read(4096)

    if w == Silent then
      puts "no signal\n"
      mutecount += 1
    elsif mutecount != 0 then
      puts "mute: #{mutecount}"
      mutecount = 0
    end

    if mutecount > 20 then
        wav.close

        unless playing_info.nil? or playing_info["PL_TITLE"] == "" then
          title  = playing_info["PL_TITLE"].gsub(/ \uff5e.*\uff5e/, '')
          artist = playing_info["PL_ARTIST"]
	  p title
          p artist
          TagLib::MP4::File.open(filename) do |mp4|
            mp4.tag.title  = title
            mp4.tag.artist = artist
            mp4.tag.album  = title
            mp4.tag.comment= Time.now.strftime('%F') + "from SKY"
            mp4.save
          end
	else
	  puts "playing info not found"
        end

        filename = "music#{Time.now.strftime('%F-%H%M%S')}.m4a"
        p filename
        wav = CoreAudio::AudioFile.new(filename, :write, :format => :m4a,
                               :rate => dev.nominal_rate,
                               :channels => dev.input_stream.channels)
        wav.write(Silent)
        wav.write(Silent)

	puts "waiting for playing music"
	while w == Silent do
	  puts "no signal"
          mutecount += 1
	  samples += w.size / dev.input_stream.channels
	  w = buf.read(4096)
	end
	puts "mute: #{mutecount}"
        mutecount = 0

	playing_info =  JSON.load(`wget http://www.stardigio.com/playingtop?toppid=401 -O-`)[1]
        p playing_info
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
File.unlink(filename)


puts "#{samples} samples read."
puts "#{buf.dropped_frame} frame dropped."
