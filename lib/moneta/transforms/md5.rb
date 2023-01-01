require 'digest/md5'

module Moneta
  module Transforms
    class MD5 < Transform
      delegate_to ::Digest::MD5, %i[hexdigest]
    end
  end
end
