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


  n_files = files.size


  isEdge = false
  (n_files/2).downto(0) {|i|
    if isEdge then
      mv(files[i], files[i]+'_')
    else
      stat = File.stat(files[i])
      if (200..342400).include?(stat.size) then
        isEdge = true
        mv(files[i], files[i]+'_')
      end
    end
  }

  isEdge = false
  (n_files/2).upto(n_files-1) {|i|
    if isEdge then
      mv(files[i], files[i]+'_')
    else
      stat = File.stat(files[i])
      if (200..342400).include?(stat.size) then
        isEdge = true
        mv(files[i], files[i]+'_')
        mv(files[i-1], files[i-1]+'_')
      end
    end
  }
end

def rename_mp3(date, ch =401, start =0)

  #include FileUtils::DryRun
  include FileUtils

  folder = date + (ch==401?'':'_'+ch.to_s)

  files = Dir.glob("./#{folder}/music*.mp3")
  files.sort!
  screen_mp3(files)

  renamefiles = Dir.glob("./#{folder}/music*.mp3")
  renamefiles.sort!

  f = open(folder + "revert.txt","w")

  Net::HTTP.version_1_2

  ch = '401' if ch.nil?
  raise if date.nil?

  prg = ''
  Net::HTTP.start('kazunori.148ra.com', 80) {|http|
    response = http.get("/hack/stardigiopdf/#{date}/#{date}_#{ch}.csv_")
    prg = response.body.tosjis
  }

  prg.sub!(/Åñå¬êlìIÇ…äyÇµÇﬁèÍçáÇèúÇ´.*/ms,"")
  #names = CSV.parse(prg, ?\t).to_a
  names = []
  prg.split("\n").each {|row|
    title, artist = row.split("\t")

    #ó·äOèàóù
    if title != "" then
      next if title[0] == ?\s
      if artist =~ /00[0-9]Å°Å°StarDigio/ then
        puts artist
        /(.*) (.*)$/ =~ title
        title  = $1
        artist = $2
        puts artist
        next if artist == 'SINGLE'
      end
      names.push [title, artist]
    end
  }

  comment = "#{date[0,4]}/#{date[4,2]}/#{date[6,2]} from SKY"

  renamefiles = renamefiles.zip(names[start,names.size - start])
  renamefiles.each {|row|
    from, (title, artist) = row

    unless from.nil? or title.nil? or artist.nil? then

      title.gsub!(/Å`.*/,'')

      artist.gsub!('/','Å^')
      title.gsub!('/','Å^')
      artist.gsub!("\"",'Åh')
      title.gsub!("\"",'Åh')
      artist.gsub!(':','ÅF')
      title.gsub!(':','ÅF')
      artist.gsub!('?','ÅH')
      title.gsub!('?','ÅH')
      artist.gsub!('<','ÅÉ')
      title.gsub!('<','ÅÉ')
      artist.gsub!('>','ÅÑ')
      title.gsub!('>','ÅÑ')
      artist.gsub!('*','Åñ')
      title.gsub!('*','Åñ')


      to = "./#{folder}/" + artist + '@' + title + '.mp3'
      f.puts from + "\t" + to
      puts from + " to " + to
#      puts "-" + (artist == "").to_s + " and " + (title == "").to_s

      mv(from ,to) unless File.exist?(to)

      begin
        Mp3Info.open(to) {|m|
          m.tag1["title"] = title + "\0"
          m.tag1["artist"] = artist + "\0"
          m.tag1["album"] = title + "\0"
          m.tag1["comments"] = comment
        }
      rescue => e
      end
    end
  }
  f.close
end

def main

  date  = ARGV[0]
  ch    = ARGV[1].to_i
  start = ARGV[2].to_i

  rename_mp3(date, ch, start)

end

main
