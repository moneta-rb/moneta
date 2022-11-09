describe Moneta::Config do
  describe 'without any configuration' do
    it 'does not set the config attribute' do
      klass = Class.new do
        include ::Moneta::Config

        def initialize(**options)
          configure(**options)
        end
      end

      instance = klass.new(k: 'v')
      expect(instance.config).to be nil
    end
  end

  describe 'basic functionality' do
    subject :klass do
      Class.new do
        include ::Moneta::Config

        config :a
        config :b

        def initialize(**options)
          configure(**options)
        end
      end
    end

    it 'sets all config values to nil by default' do
      instance = klass.new
      expect(instance.config.a).to eq nil
      expect(instance.config.b).to be nil
    end

    it 'sets config values with values provided to #configure' do
      instance = klass.new(a: 1)
      expect(instance.config.a).to eq 1
      expect(instance.config.b).to be nil
    end

    it 'freezes the config' do
      instance = klass.new
      expect(instance.config.frozen?).to be true
    end
  end

  describe 'with required arguments' do
    subject :klass do
      Class.new do
        include ::Moneta::Config

        config :a, required: true
        config :b, default: 'x', required: true

        def initialize(**options)
          configure(**options)
        end
      end
    end

    it 'raises an ArgumentError if #configure is called without one of the required arguments' do
      expect { klass.new(a: 1) }.to raise_error ArgumentError, 'b is required'
      expect { klass.new(b: 1) }.to raise_error ArgumentError, 'a is required'
    end
  end

  describe 'with defaults' do
    subject :klass do
      Class.new do
        include ::Moneta::Config

        config :a, default: 't'
        config :b, default: 's'

        def initialize(**options)
          configure(**options)
        end
      end
    end

    it 'uses the defaults if no argument is provided' do
      instance = klass.new(a: 1)

      expect(instance.config.a).to eq 1
      expect(instance.config.b).to eq 's'
    end

    it 'allows falsy values to override truthy defaults' do
      instance = klass.new(a: nil, b: false)

      expect(instance.config.a).to be nil
      expect(instance.config.b).to be false
    end
  end

  describe 'with coercion' do
    describe 'using a symbol' do
      subject :klass do
        Class.new do
          include ::Moneta::Config

          config :a, coerce: :to_s

          def initialize(**options)
            configure(**options)
          end
        end
      end

      it "uses the symbol's to_proc property" do
        instance = klass.new(a: :x)
        expect(instance.config.a).to eq 'x'
      end
    end

    describe 'using a lambda' do
      subject :klass do
        Class.new do
          include ::Moneta::Config

          config :a, coerce: lambda { |a| a.to_sym }

          def initialize(**options)
            configure(**options)
          end
        end
      end

      it "calls the lambda" do
        instance = klass.new(a: 'x')
        expect(instance.config.a).to eq :x
      end
    end
  end

  describe 'with a block' do
    subject :klass do
      Class.new do
        include ::Moneta::Config

        config :a do |a:, b:|
          { a: a, b: b, test: @test }
        end

        config :b, default: 'b default'

        def initialize(test: nil, **options)
          @test = test
          configure(**options)
        end
      end
    end

    it 'calls the block after all arguments and defaults have been processed' do
      instance1 = klass.new(a: 'a value')
      expect(instance1.config.a).to include(a: 'a value', b: 'b default')

      instance2 = klass.new(b: 'b value')
      expect(instance2.config.a).to include(a: nil, b: 'b value')
    end

    it 'calls the block using instance_exec' do
      instance = klass.new(test: 'test value')
      expect(instance.config.a).to include(test: 'test value')
    end
  end

  describe 'with inheritance' do
    subject :klass do
      Class.new do
        include ::Moneta::Config

        config :a

        def initialize(**options)
          configure(**options)
        end
      end
    end

    it 'does not allow subclasses to override superclass config' do
      expect do
        Class.new(klass) do
          config :a
        end
      end.to raise_error ArgumentError, 'a is already a config option'
    end

    it 'does not affect the superclass when additional config is added to the subclass' do
      klass2 = Class.new(klass) do
        config :b
      end

      instance1 = klass.new(a: 1, b: 2)
      expect(instance1.config.to_h).to eq(a: 1)

      instance2 = klass2.new(a: 1, b: 2)
      expect(instance2.config.to_h).to eq(a: 1, b: 2)
    end

    it 'is possible for two subclasses to have the same additional config' do
      klass2 = Class.new(klass) do
        config :b
      end

      klass3 = Class.new(klass) do
        config :b
      end

      instance2 = klass2.new(a: 2, b: 1)
      expect(instance2.config.to_h).to eq(a: 2, b: 1)

      instance3 = klass3.new(a: 1, b: 2)
      expect(instance3.config.to_h).to eq(a: 1, b: 2)
    end
  end
end
