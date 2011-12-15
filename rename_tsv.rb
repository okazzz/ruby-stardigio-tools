#!/usr/local/bin/ruby
# usage ruby rename.rb date ch startindex
# 
# ex. ruby rename.rb 20071231 401

require 'rubygems'
require 'mp3info'
require 'fileutils'
require 'kconv.rb'
require 'net/http'
require 'csv'

def screen_mp3(files)
  status = :invalid
  ret = nil
  files.reject! do |filename|
    stat = File.stat(filename)
    if (342200..342400).include?(stat.size) then
      status = ([:valid, :invalid] - [status])[0]
      ret = true
    elsif status == :invalid then
      ret = true
    else
      ret = false
    end

    ret
  end

  files.pop
end

def rename_mp3(date, ch =401, start =0)

  #include FileUtils::DryRun
  include FileUtils

  Net::HTTP.version_1_2

  ch = '401' if ch.nil?
  raise if date.nil?

  prg = ''

  Net::HTTP.start('kazunori.148ra.com', 80) {|http|
    response = http.get("/hack/stardigiopdf/#{date}/#{date}_#{ch}.csv_")
    prg = response.body.tosjis
  }

  files = Dir.glob("./#{date}/music*.mp3")
  files.sort!

  renamefiles = files.dup
  screen_mp3(renamefiles)

  rm(files - renamefiles)

  prg.sub!(/–ŒÂl“I‚ÉŠy‚µ‚Şê‡‚ğœ‚«.*/ms,"")
  #puts prg
  #names = CSV.parse(prg, ?\t).to_a
  names = []
  prg.split("\n").each {|row|
    names.push row.split("\t")
  }
  #p names

  comment = "#{date[0,4]}/#{date[4,2]}/#{date[6,2]} from SKY"

  renamefiles = renamefiles.zip(names[start,names.size - start])
  renamefiles.each {|row|
    from, (title, artist) = row

    unless from.nil? or title.nil? then

      title.gsub!(/`.*`/,'')

      artist.gsub!('/','^')
      title.gsub!('/','^')
      artist.gsub!("\"",'h')
      title.gsub!("\"",'h')
      artist.gsub!(':','F')
      title.gsub!(':','F')
      artist.gsub!('?','H')
      title.gsub!('?','H')
      artist.gsub!('<','ƒ')
      title.gsub!('<','ƒ')
      artist.gsub!('>','„')
      title.gsub!('>','„')
      artist.gsub!('*','–')
      title.gsub!('*','–')

      to = "./#{date}/" + artist + '@' + title + '.mp3'
      mv(from ,to)
      puts from + " to " + to

      Mp3Info.open(to) {|m|

        unless m.hastag1? then
          m.tag1["title"] = title + "\0"
          m.tag1["artist"] = artist + "\0"
          m.tag1["album"] = title + "\0"
          m.tag1["comments"] = comment
        end
      }
    end
  }
end

def main

  date  = ARGV[0]
  ch    = ARGV[1]
  start = ARGV[2].to_i

  rename_mp3(date, ch, start)

end

main
