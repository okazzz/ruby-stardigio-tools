#!/usr/local/bin/ruby
# usage: delete.rb dir

path = ARGV[0].sub(/\/$/,'')
files = Dir.glob(path + "/**/*.mp3")
filelists = Hash.new
files.each {|filepath|
  if File.stat(filepath).ftype == "file" then
    file = File.basename(filepath, ".mp3")
    if filelists[file].nil? then
       filelists[file] = Array[filepath]
    else
       filelists[file] << filepath
    end
  end
}
#p filelists
filelists.each_value {|files|
  files.sort! {|a, b|
#    FileTest.size?(b) <=> FileTest.size?(a)
    File.mtime(a) <=> File.mtime(b)
  }
  if files.size > 1 then
    (1 ... files.size).each {|index|
      print files[index] + " " + File.mtime(files[index]).to_s + "\n"
      File.unlink(files[index])
    }
  end
}
