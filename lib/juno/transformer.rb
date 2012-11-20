module Juno
  class Transformer < Proxy
    @classes = {}

    class << self
      alias_method :original_new, :new
    end

    VALUE_TRANSFORMER = {
      :marshal => { :load => '::Marshal.load(VALUE)',          :dump => '::Marshal.dump(VALUE)' },
      :base64  => { :load => "VALUE.unpack('m').first",        :dump => "[VALUE].pack('m').strip" },
      :json    => { :load => '::MultiJson.load(VALUE).first',  :dump => '::MultiJson.dump([VALUE])', :require => 'multi_json' },
      :yaml    => { :load => '::YAML.load(VALUE)',             :dump => '::YAML.dump(VALUE)',        :require => 'yaml' },
      #:tnet    => { :load => '::TNetstring.parse(VALUE)',      :dump => '::TNetstring.dump(VALUE)', :require => 'tnetstring' },
      :msgpack => { :load => '::MessagePack.unpack(VALUE)',    :dump => '::MessagePack.pack(VALUE)', :require => 'msgpack' },
      :bson    => { :load => '::BSON.deserialize(VALUE)["v"]', :dump => '::BSON.serialize({"v"=>VALUE})',   :require => 'bson' },
    }

    KEY_TRANSFORMER = {
      :base64  => { :transform => "[KEY].pack('m').strip" },
      :spread  => { :transform => '(TMP = KEY; ::File.join(TMP[0..1], TMP[2..-1]))' },
      :escape  => { :transform => "KEY.gsub(/[^a-zA-Z0-9_-]+/) { '%%' + $&.unpack('H2' * $&.bytesize).join('%%').upcase }" },
      :md5     => { :transform => '::Digest::MD5.hexdigest(KEY)',                              :require => 'digest/md5' },
      :json    => { :transform => '(TMP = KEY; String === TMP ? TMP : ::MultiJson.dump(TMP))', :require => 'multi_json' },
      :bson    => { :transform => '(TMP = KEY; String === TMP ? TMP : ::BSON.serialize({"k"=>TMP}).to_s)', :require => 'bson' },
      :yaml    => { :transform => '(TMP = KEY; String === TMP ? TMP : ::YAML.dump(TMP))',      :require => 'yaml' },
      :marshal => { :transform => '(TMP = KEY; String === TMP ? TMP : ::Marshal.dump(TMP))' },
      #:tnet    => { :transform => '(TMP = KEY; String === TMP ? TMP : ::TNetstring.dump(TMP))', :require => 'tnetstring' },
      :msgpack => { :transform => '(TMP = KEY; String === TMP ? TMP : ::MessagePack.pack(TMP))', :require => 'msgpack' },
    }

    class << self
      def compile(keys, values)
        tmp, key = 0, 'key'
        keys.each do |tn|
          raise "Unknown key transformer #{tn}" unless t = KEY_TRANSFORMER[tn]
          require t[:require] if t[:require]
          key = t[:transform].gsub('KEY', key).gsub('TMP', "x#{tmp}")
          tmp += 1
        end

        dumper = 'value'
        values.each do |tn|
          raise "Unknown value transformer #{tn}" unless t = VALUE_TRANSFORMER[tn]
          require t[:require] if t[:require]
          dumper = t[:dump].gsub('VALUE', dumper)
        end

        loader = 'value'
        values.reverse.each do |t|
          loader = VALUE_TRANSFORMER[t][:load].gsub('VALUE', loader)
        end

        klass = Class.new(Transformer)
        if loader == 'value'
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

      def new(store, options = {})
        keys = [options[:key]].flatten.compact
        values = [options[:value]].flatten.compact
        klass = @classes["#{keys.join('-')}+#{values.join('-')}"] ||= compile(keys, values)
        klass.original_new(store, options)
      end
    end
  end
end
