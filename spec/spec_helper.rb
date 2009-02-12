$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require "rubygems"
require "moneta"
require "moneta/memory"
require "moneta/memcache"
require "moneta/file"
require "moneta/xattr"
require "moneta/datamapper"
require "moneta/rufus"

require File.expand_path(File.join(File.dirname(__FILE__), "shared"))