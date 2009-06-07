#
#  Basic File Store
#  by Hampton Catlin
#
#  This cache simply uses a directory that it creates
#  and manages to keep your file stores. If you don't need
#  expiration make sure to turn it off, because it requires
#  an extra file open.
#
#  The only key requirements are there can't be a key named
#  "___expiration__" and any characters your operating system
#  doesn't like! "/" is to be avoided
#


require 'fileutils'
require File.join(File.dirname(__FILE__), "file")

module Moneta
  class BasicFile
    include Defaults
    include Moneta::File::Implementation

    def initialize(options = {})
      @namespace = options[:namespace]
      @directory = ::File.join(options[:path], @namespace.to_s)
      
      unless options[:skip_expires]
        @expiration_directory = ::File.join(options[:path], [@namespace, "expiration"].compact.join("_"))
        setup_expiration_cache
        self.extend(StringExpires)
      end

      ensure_directory_created(@directory)
    end
    
    # Override default behaviour to create subdirectories
    def []=(key, value)
      ensure_directory_created(::File.dirname(path(key)))
      super
    end
    
    def clear
      super
      if @expiration
        @expiration.clear
      end
    end
    
    private
    def setup_expiration_cache
      @expiration = BasicFile.new(:path => @expiration_directory, :skip_expires => true)
    end
    
    def ensure_directory_created(directory_path)
      if ::File.file?(directory_path)
        raise StandardError, "The path you supplied #{directory_path} is a file"
      elsif !::File.exists?(directory_path)
        FileUtils.mkdir_p(directory_path)
      end
    end
      
  end
end