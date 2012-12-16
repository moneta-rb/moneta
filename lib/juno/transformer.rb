module Juno
  # Transforms keys and values (Marshal, YAML, JSON, Base64, MD5, ...).
  #
  # @example Add transformer to chain
  #   Juno.build do
  #     transformer :key => [:marshal, :escape], :value => [:marshal]
  #     adapter :File, :dir => 'data'
  #   end
  #
  # @api public
  class Transformer < Proxy
    def initialize(adapter, options = {})
      super
      @prefix, @secret = options[:prefix], options[:secret]
    end

    class << self
      alias_method :original_new, :new

      # Constructor
      #
      # @param [Juno store] adapter The underlying store
      # @param [Hash] options
      #
      # Options:
      # * :key - List of key transformers in the order in which they should be applied
      # * :value - List of value transformers in the order in which they should be applied
      # * :prefix - Prefix string for key namespacing (Used by the :prefix key transformer)
      # * :secret - HMAC secret to verify values (Used by the :hmac value transformer)
      def new(adapter, options = {})
        keys = [options[:key]].flatten.compact
        values = [options[:value]].flatten.compact
        raise 'Option :key or :value is required' if keys.empty? && values.empty?
        raise 'Option :prefix is required for :prefix key transformer' if keys.include?(:prefix) && !options[:prefix]
        raise 'Option :secret is required for :hmac value transformer' if values.include?(:hmac) && !options[:secret]
        name = class_name(keys, values)
        const_set(name, compile(keys, values)) unless const_defined?(name)
        const_get(name).original_new(adapter, options)
      end

      private

      def compile(keys, values)
        raise 'Invalid key transformer chain' if KEY_TRANSFORMER !~ keys.map(&:inspect).join
        raise 'Invalid value transformer chain' if VALUE_TRANSFORMER !~ values.map(&:inspect).join

        key = compile_transformer(keys, 'key')

        klass = Class.new(self)
        if values.empty?
          klass.class_eval <<-end_eval, __FILE__, __LINE__
            def key?(key, options = {})
              @adapter.key?(#{key}, options)
            end
            def load(key, options = {})
              @adapter.load(#{key}, options)
            end
            def store(key, value, options = {})
              @adapter.store(#{key}, value, options)
            end
            def delete(key, options = {})
              @adapter.delete(#{key}, options)
            end
          end_eval
        else
          dump = compile_transformer(values, 'value')
          load = compile_transformer(values.reverse, 'value', 1)

          klass.class_eval <<-end_eval, __FILE__, __LINE__
            def key?(key, options = {})
              @adapter.key?(#{key}, options)
            end
            def load(key, options = {})
              value = @adapter.load(#{key}, options)
              value && #{load}
            end
            def store(key, value, options = {})
              @adapter.store(#{key}, #{dump}, options)
              value
            end
            def delete(key, options = {})
              value = @adapter.delete(#{key}, options)
              value && #{load}
            end
          end_eval
        end
        klass
      end

      # Compile transformer validator regular expression
      def compile_validator(s)
        Regexp.new(s.gsub(/\w+/) do
                     '(' + TRANSFORMER.select {|k,v| v.first.to_s == $& }.map {|v| ":#{v.first}" }.join('|') + ')'
                   end.gsub(/\s+/, '').sub(/\A/, '\A').sub(/\Z/, '\Z'))
      end

      # Returned compiled transformer code string
      def compile_transformer(transformer, var, i = 2)
        transformer.inject(var) do |value, name|
          raise "Unknown transformer #{name}" unless t = TRANSFORMER[name]
          require t[3] if t[3]
          code = t[i]
          if t[0] == :serialize && var == 'key'
            "(tmp = #{value}; String === tmp ? tmp : #{code.gsub('value', 'tmp')})"
          else
            code.gsub('value', value)
          end
        end
      end

      def class_name(keys, values)
        (keys.empty? ? '' : keys.map(&:to_s).map(&:capitalize).join << 'Key') <<
          (values.empty? ? '' : values.map(&:to_s).map(&:capitalize).join << 'Value')
      end
    end

    # Available key/value transformers
    TRANSFORMER = {
      # Name    => [ Type,       Load,                              Dump,                                Library         ],
      :bencode  => [ :serialize, '::BEncode.load(value)',           '::BEncode.dump(value)',             'bencode'       ],
      :bert     => [ :serialize, '::BERT.decode(value)',            '::BERT.encode(value)',              'bert'          ],
      :bson     => [ :serialize, "::BSON.deserialize(value)['v']",  "::BSON.serialize('v'=>value).to_s", 'bson'          ],
      :json     => [ :serialize, '::MultiJson.load(value).first',   '::MultiJson.dump([value])',         'multi_json'    ],
      :marshal  => [ :serialize, '::Marshal.load(value)',           '::Marshal.dump(value)'                              ],
      :msgpack  => [ :serialize, '::MessagePack.unpack(value)',     '::MessagePack.pack(value)',         'msgpack'       ],
      :ox       => [ :serialize, '::Ox.parse_obj(value)',           '::Ox.dump(value)',                  'ox'            ],
      :tnet     => [ :serialize, '::TNetstring.parse(value).first', '::TNetstring.dump(value)',          'tnetstring'    ],
      :yaml     => [ :serialize, '::YAML.load(value)',              '::YAML.dump(value)',                'yaml'          ],
      :lzma     => [ :compress,  '::LZMA.decompress(value)',        '::LZMA.compress(value)',            'lzma'          ],
      :lzo      => [ :compress,  '::LZO.decompress(value)',         '::LZO.compress(value)',             'lzoruby'       ],
      :snappy   => [ :compress,  '::Snappy.inflate(value)',         '::Snappy.deflate(value)',           'snappy'        ],
      :quicklz  => [ :compress,  '::QuickLZ.decompress(value)',     '::QuickLZ.compress(value)',         'qlzruby'       ],
      :zlib     => [ :compress,  '::Zlib::Inflate.inflate(value)',  '::Zlib::Deflate.deflate(value)',    'zlib'          ],
      :base64   => [ :encode,    "value.unpack('m').first",         "[value].pack('m').strip"                            ],
      :uuencode => [ :encode,    "value.unpack('u').first",         "[value].pack('u').strip"                            ],
      :escape   => [ :encode,    'Escape.unescape(value)',          'Escape.escape(value)'                               ],
      :hmac     => [ :hmac,      'HMAC.verify(value, @secret)',     'HMAC.sign(value, @secret)' ,        'openssl'       ],
      :md5      => [ :digest,    nil,                               '::Digest::MD5.hexdigest(value)',    'digest/md5'    ],
      :rmd160   => [ :digest,    nil,                               '::Digest::RMD160.hexdigest(value)', 'digest/rmd160' ],
      :sha1     => [ :digest,    nil,                               '::Digest::SHA1.hexdigest(value)',   'digest/sha1'   ],
      :sha256   => [ :digest,    nil,                               '::Digest::SHA256.hexdigest(value)', 'digest/sha2'   ],
      :sha384   => [ :digest,    nil,                               '::Digest::SHA384.hexdigest(value)', 'digest/sha2'   ],
      :sha512   => [ :digest,    nil,                               '::Digest::SHA512.hexdigest(value)', 'digest/sha2'   ],
      :prefix   => [ :prefix,    nil,                               '@prefix+value'                                      ],
      :spread   => [ :spread,    nil,                               '(tmp = value; ::File.join(tmp[0..1], tmp[2..-1]))'  ],
    }

    # Allowed value transformers (Read it like a regular expression!)
    VALUE_TRANSFORMER = compile_validator('serialize? compress? hmac? encode?')

    # Allowed key transformers (Read it like a regular expression!)
    KEY_TRANSFORMER = compile_validator('serialize? prefix? (encode | (digest spread?))?')

    module Escape
      def self.escape(value)
        value.gsub(/[^a-zA-Z0-9_-]+/){ '%' + $&.unpack('H2' * $&.bytesize).join('%').upcase }
      end

      def self.unescape(value)
        value.gsub(/((?:%[0-9a-fA-F]{2})+)/){ [$1.delete('%')].pack('H*') }
      end
    end

    module HMAC
      def self.verify(value, secret)
        hash, value = value[0..31], value[32..-1]
        value if hash == OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), secret, value)
      end

      def self.sign(value, secret)
        OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), secret, value) << value
      end
    end
  end
end
