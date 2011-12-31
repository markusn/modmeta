#!/usr/bin/ENV ruby
# encoding: utf-8
# -*- coding: utf-8 -*-
################################################################################
# Display and/or modify tracker mod data (.xm |.mod |.it | .s3m)
#
# Author::    Markus Näsman  (mailto:markus [at] botten.org)
# Copyright:: Copyright (c) 2011 Markus Näsman
# License::   GPLv3
################################################################################

################################################################################
# R E Q U I R E
################################################################################
require 'optparse'

################################################################################
# C O N S T A N T S
################################################################################

# File formats supported
FILEFORMATS = ['.xm', '.mod', '.it', '.s3m']

# Constants for .xm (http://content.gpwiki.org/index.php/XM)
XM_TITLE_OFFSET_CONST   = 17
XM_TITLE_LENGTH_CONST   = 20
XM_TRACKER_OFFSET_CONST = 38
XM_TRACKER_LENGTH_CONST = 20

# Constants for .mod (http://www.aes.id.au/modformat.html)
MOD_TITLE_OFFSET_CONST = 0
MOD_TITLE_LENGTH_CONST = 20

# Constants for .it (guessed...)
IT_TITLE_OFFSET_CONST = 4
IT_TITLE_LENGTH_CONST = 20

# Constants for .s3m (http://hackipedia.org/File%20formats/Music/Sample%20based/html/s3mformat.html)
S3M_TITLE_OFFSET_CONST = 0
S3M_TITLE_LENGTH_CONST = 28

################################################################################
# V A R I A B L E S
################################################################################
options = {}

################################################################################
# F U N C T I O N S
################################################################################
def get_title_offset_len(filename)
  case File.extname(filename)
  when ".xm"
    return XM_TITLE_OFFSET_CONST, XM_TITLE_LENGTH_CONST
  when ".mod"
    return MOD_TITLE_OFFSET_CONST, MOD_TITLE_LENGTH_CONST
  when ".it"
    return IT_TITLE_OFFSET_CONST, IT_TITLE_LENGTH_CONST
  when ".s3m"
    return S3M_TITLE_OFFSET_CONST, S3M_TITLE_LENGTH_CONST
  else
    return -1, -1
  end
end

def get_tracker_offset_len(filename)
  case File.extname(filename)
  when ".xm"
    return XM_TRACKER_OFFSET_CONST, XM_TRACKER_LENGTH_CONST
  else
    return -1, -1
  end
end

def display_metadata(filename)
  display_title(filename)
  display_tracker(filename)
end

def display_title(filename)
  offset,len = get_title_offset_len(filename)
  display_attr(filename, "title", offset, len)
end

def display_tracker(filename)
  offset,len = get_tracker_offset_len(filename)
  display_attr(filename, "tracker", offset, len)
end

def display_attr(filename, attr, offset, len)
  v = "n/a"
  if offset >=0 && len >= 0
    f = open(filename)
    f.pos = offset
    v = f.read(len)
    f.close()
  end
  puts "#{attr}: #{v}"
end

def set_title(filename, title)
  offset,len = get_title_offset_len(filename)
  if offset < 0 || len < 0
    puts "Cannot set title for format"
    exit(1)
  elsif title.length > len
    puts "title longer than maximum allowed length #{len}, aborting!"
    exit(1)
  else # Good to go!
    # Create padded byte array from title
    title_bytes = len.times.map { 0 }
    i = 0
    title.each_byte do |byte|
      title_bytes[i] = byte
      i +=1
    end
    # Read file
    f = open(filename, 'r')
    bytes = f.bytes.to_a
    f.close()
    # Make modifications
    i = 0
    title_bytes.each do |byte|
      bytes[offset+i] = byte
      i +=1
    end
    # Write file
    f = open(filename, 'w')
    bytes.each do | byte |
      f.print byte.chr
    end
    f.close()
  end
end

def ensure_format(filename)
  if not FILEFORMATS.include?(File.extname(filename))
    puts "File format not supported"
    exit(1)
  end
end

################################################################################
# M A I N
################################################################################
if __FILE__ == $0
  # Parse options
  OptionParser.new do |opts|
    opts.banner = "Usage: modmeta.rb [options] [filename]"
    opts.on("-t", "--set-title [TITLE]", String, "Set title") do |title|
      options[:title] = title
    end
    opts.on("-d", "--display", "Display metadata") do |v|
      options[:display] = v
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!

  if ARGV.length == 0 # We need at least one file
    puts "Need to specify filename"
    exit(1)
  elsif ARGV.length == 1 # We got one file!
    filename = ARGV[0]
    ensure_format(filename)
    # Do something
    if options[:display]
      display_metadata(filename)
    elsif options[:title]
      set_title(filename, options[:title])
    end
  else # We got multiple files or a negative number of files (!?)
    puts "Only one filename should be specified"
    exit(1)
  end
end
