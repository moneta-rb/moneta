describe Moneta::Builder do
  it 'raises an error if #use is called after #adapter' do
    expect do
      Moneta::Builder.new do
        adapter :Null
        use :Lock
      end.build
    end.to raise_error /Please check/
  end

  it 'raises an error if #adapter called twice' do
    expect do
      Moneta::Builder.new do
        adapter :Null
        adapter :Null
      end.build
    end.to raise_error /Please check/
  end

  it 'raises an error if no #adapter is specified' do
    expect do
      Moneta::Builder.new do
        use :Lock
        use :Lock
      end.build
    end.to raise_error /Please check/
  end

  it 'dups options before passing them to each middleware' do
    my_adapter = Class.new do
      def initialize(options)
        throw "a is missing" unless options.delete(:a)
      end
    end

    my_middleware = Class.new do
      def initialize(backend, options)
        throw "a is missing" unless options.delete(:a)
      end
    end

    options = { a: 1 }
    Moneta::Builder.new do
      use my_middleware, options
      adapter my_adapter, options
    end.build

    expect(options).to include(a: 1)
  end
end
