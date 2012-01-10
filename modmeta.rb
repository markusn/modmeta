#!/usr/bin/env ruby
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

##
# Get the offset and length for title metadata field in filename
#
# * *Args*    :
#   - +filename+ -> filename to get title offset for
# * *Returns* :
#   - title offset, title length | -1,-1 if such does not exist
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

##
# Get the offset and length for tracker metadata field in filename
#
# * *Args*    :
#   - +filename+ -> filename to get tracker offset for
# * *Returns* :
#   - tracker offset, tracker length | -1,-1 if such does not exist
def get_tracker_offset_len(filename)
  case File.extname(filename)
  when ".xm"
    return XM_TRACKER_OFFSET_CONST, XM_TRACKER_LENGTH_CONST
  else
    return -1, -1
  end
end

##
# Display all metadata for filename
#
# * *Args*    :
#   - +filename+ -> filename to display metadata for
def display_metadata(filename)
  display_title(filename)
  display_tracker(filename)
end

##
# Display title metadata for filename
#
# * *Args*    :
#   - +filename+ -> filename to display title for
def display_title(filename)
  offset,len = get_title_offset_len(filename)
  display_attr(filename, "title", offset, len)
end

##
# Display tracker metadata for filename
#
# * *Args*    :
#   - +filename+ -> filename to display tracker for
def display_tracker(filename)
  offset,len = get_tracker_offset_len(filename)
  display_attr(filename, "tracker", offset, len)
end

##
# Display attr from filename
#
# * *Args*    :
#   - +filename+ -> filename to display attr for
#   - +attr+ -> name of attribute
#   - +offset+ -> offset for attr attribute in filename
#   - +length+ -> length for attr attribute in filename
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

##
# Assert that it is possible to set the attribute we're trying to set
#
# * *Args*    :
#   - +attr+ -> name of attribute
#   - +offset+ -> offset for attr attribute in filename
#   - +length+ -> length for attr attribute in filename
#   - +str+ -> string to set
# * *Raises* :
#   - +RuntimeError+ -> if offset or len < 0 or str.length > len
def ensure_allowed_set(offset, len, attr, str)
  if offset < 0 || len < 0
    raise "Cannot set title for format"
  elsif str.length > len
    raise "#{attr} longer than maximum allowed length #{len}, aborting!"
  end
end

##
# Set the title to title for filename
#
# * *Args*    :
#   - +filename+ -> file to set title for
#   - +title+ -> title string to set
# * *Raises* :
#   - +RuntimeError+ -> if title offset or title len < 0 or str len > title len
def set_title(filename, title)
  offset,len = get_title_offset_len(filename)
  ensure_allowed_set(offset, len, "Title", title)

  # Create padded byte array from title
  title_bytes = len.times.map { 0 }
  i = 0
  title.each_byte do |byte|
    title_bytes[i] = byte
    i +=1
  end
  # Write file
  f = open(filename, 'r+')
  f.pos = offset
  title_bytes.each do |byte|
    f.putc(byte)
  end
  f.close()
end

##
# Assert that filename has a supported file format
#
# * *Args*    :
#   - +filename+ -> filename to assert file format for
# * *Raises* :
#   - +RuntimeError+ -> if filr format is not supported
def ensure_format(filename)
  if not FILEFORMATS.include?(File.extname(filename))
    raise "File format not supported"
  end
end

################################################################################
# M A I N
################################################################################
if __FILE__ == $0
  begin
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
      raise "Need to specify filename"
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
      raise "Only one filename should be specified"
    end
  rescue
    puts $!
    exit(1)
  end
end
