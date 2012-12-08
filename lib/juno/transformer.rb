module Juno
  # Transforms keys and values (Marshal, YAML, JSON, Base64, MD5, ...).
  #
  # Example:
  #
  #   Juno.build do
  #     transformer :key => [:marshal, :escape], :value => [:marshal]
  #     adapter :File, :dir => 'data'
  #   end
  #
  # @api public
  class Transformer < Proxy
    VALUE_TRANSFORMER = {
      :base64   => { :load => "value.unpack('m').first",         :dump => "[value].pack('m').strip" },
      :bencode  => { :load => '::BEncode.load(value)',           :dump => '::BEncode.dump(value)', :require => 'bencode' },
      :bert     => { :load => '::BERT.decode(value)',            :dump => '::BERT.encode(value)', :require => 'bert' },
      :bson     => { :load => "::BSON.deserialize(value)['v']",  :dump => "::BSON.serialize('v'=>value)", :require => 'bson' },
      :compress => { :load => '::Zlib::Inflate.inflate(value)',  :dump => '::Zlib::Deflate.deflate(value)', :require => 'zlib' },
      :json     => { :load => '::MultiJson.load(value).first',   :dump => '::MultiJson.dump([value])', :require => 'multi_json' },
      :lzo      => { :load => '::LZO.decompress(value)',         :dump => '::LZO.compress(value)', :require => 'lzoruby' },
      :marshal  => { :load => '::Marshal.load(value)',           :dump => '::Marshal.dump(value)' },
      :msgpack  => { :load => '::MessagePack.unpack(value)',     :dump => '::MessagePack.pack(value)', :require => 'msgpack' },
      :ox       => { :load => '::Ox.parse_obj(value)',           :dump => '::Ox.dump(value)', :require => 'ox' },
      :snappy   => { :load => '::Snappy.inflate(value)',         :dump => '::Snappy.deflate(value)', :require => 'snappy' },
      :quicklz  => { :load => '::QuickLZ.decompress(value)',     :dump => '::QuickLZ.compress(value)', :require => 'qlzruby' },
      :tnet     => { :load => '::TNetstring.parse(value).first', :dump => '::TNetstring.dump(value)', :require => 'tnetstring' },
      :uuencode => { :load => "value.unpack('u').first",         :dump => "[value].pack('u').strip" },
      :yaml     => { :load => '::YAML.load(value)',              :dump => '::YAML.dump(value)', :require => 'yaml' },
    }

    KEY_TRANSFORMER = {
      :base64   => { :transform => "[key].pack('m').strip" },
      :bencode  => { :transform => '::BEncode.dump(key)', :require => 'bencode' },
      :bert     => { :transform => '::BERT.encode(key)', :require => 'bert' },
      :bson     => { :transform => "(tmp = key; String === tmp ? tmp : ::BSON.serialize('k'=>tmp).to_s)", :require => 'bson' },
      :escape   => { :transform => "key.gsub(/[^a-zA-Z0-9_-]+/) { '%%' + $&.unpack('H2' * $&.bytesize).join('%%').upcase }" },
      :json     => { :transform => '(tmp = key; String === tmp ? tmp : ::MultiJson.dump(tmp))', :require => 'multi_json' },
      :marshal  => { :transform => '(tmp = key; String === tmp ? tmp : ::Marshal.dump(tmp))' },
      :md5      => { :transform => '::Digest::MD5.hexdigest(key)', :require => 'digest/md5' },
      :msgpack  => { :transform => '(tmp = key; String === tmp ? tmp : ::MessagePack.pack(tmp))', :require => 'msgpack' },
      :ox       => { :transform => '(tmp = key; String === tmp ? tmp : ::Ox.dump(tmp))' },
      :spread   => { :transform => '(tmp = key; ::File.join(tmp[0..1], tmp[2..-1]))' },
      :tnet     => { :transform => '(tmp = key; String === tmp ? tmp : ::TNetstring.dump(tmp))', :require => 'tnetstring' },
      :uuencode => { :transform => "[key].pack('u').strip" },
      :yaml     => { :transform => '(tmp = key; String === tmp ? tmp : ::YAML.dump(tmp))', :require => 'yaml' },
    }

    @classes = {}

    class << self
      alias_method :original_new, :new

      def compile(keys, values)
        tmp, key = 0, 'key'
        keys.each do |tn|
          raise "Unknown key transformer #{tn}" unless t = KEY_TRANSFORMER[tn]
          require t[:require] if t[:require]
          key = t[:transform].gsub('key', key).gsub('tmp', "x#{tmp}")
          tmp += 1
        end

        klass = Class.new(Transformer)
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
          dumper, loader = 'value', 'value'
          values.each_index do |i|
            raise "Unknown value transformer #{values[i]}" unless t = VALUE_TRANSFORMER[values[i]]
            require t[:require] if t[:require]
            dumper = t[:dump].gsub('value', dumper)
            loader = VALUE_TRANSFORMER[values[-i-1]][:load].gsub('value', loader)
          end

          klass.class_eval <<-end_eval, __FILE__, __LINE__
            def key?(key, options = {})
              @adapter.key?(#{key}, options)
            end
            def load(key, options = {})
              value = @adapter.load(#{key}, options)
              value && #{loader}
            end
            def store(key, value, options = {})
              @adapter.store(#{key}, #{dumper}, options)
              value
            end
            def delete(key, options = {})
              value = @adapter.delete(#{key}, options)
              value && #{loader}
            end
          end_eval
        end
        klass
      end

      # Constructor
      #
      # @param [Juno store] adapter The underlying store
      # @param [Hash] options
      #
      # Options:
      # * :key - List of key transformers in the order in which they should be applied
      # * :value - List of value transformers in the order in which they should be applied
      def new(adapter, options = {})
        keys = [options[:key]].flatten.compact
        values = [options[:value]].flatten.compact
        raise 'No option :key or :value specified' if keys.empty? && values.empty?
        klass = @classes["#{keys.join('-')}+#{values.join('-')}"] ||= compile(keys, values)
        klass.original_new(adapter, options)
      end
    end
  end
end
