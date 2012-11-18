require 'digest/md5'

module Juno
  class HashFile < Juno::File
    protected

    def store_path(key)
      hash = Digest::MD5.hexdigest(key_for(key))
      ::File.join(@dir, hash[0..1], hash[2..-1])
    end
  end
end
