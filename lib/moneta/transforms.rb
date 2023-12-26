module Moneta
  # This module is used to namespace Moneta's built-in transform classes, as used by {Moneta::Transformer}.
  module Transforms
    TRANSFORMS = %i[
      BEncode
      BERT
      BSON
      JSON
      Marshal
      MessagePack
      Ox
      PHP
      TNet
      YAML
      Bzip2
      LZ4
      LZMA
      LZO
      Snappy
      QuizLZ
      Zlib
      Base64
      UrlsafeBase64
      Escape
      Hex
      QP
      UUEncode
      HMAC
      Prefix
      Truncate
      MD5
      RMD160
      SHA1
      SHA256
      SHA384
      SHA512
      City32
      City64
      City128
      Spread
      ToS
      Inspect
    ].freeze

    TRANSFORMS.each do |transform|
      autoload transform, "moneta/transforms/#{transform.to_s.downcase}"
    end

    # Used by {Moneta::Transformer} to initialise instances of {Moneta::Transform} to do key/value encoding and
    # decoding.
    #
    # @param name [String,Symbol] The name of the transform
    # @return [Module] A class that implements the {Moneta::Transform} interface when initialized
    def self.module_for(name)
      transform_sym =
        case name
        when :msgpack
          :MessagePack
        else
          name_str = name.to_s.gsub("_", "")
          TRANSFORMS.find do |transform|
            transform == name ||
              transform.to_s.downcase == name_str
          end
        end

      const_get transform_sym if transform_sym
    end
  end
end
