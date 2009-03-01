$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require "rubygems"
require "moneta"
require "moneta/memory"
require "moneta/file"

require File.expand_path(File.join(File.dirname(__FILE__), "shared"))