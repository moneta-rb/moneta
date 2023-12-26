require "digest/md5"

module Moneta
  module Transforms
    # Hashes strings using MD5
    class MD5 < Transform
      delegate_to ::Digest::MD5, %i[hexdigest]
    end
  end
end
