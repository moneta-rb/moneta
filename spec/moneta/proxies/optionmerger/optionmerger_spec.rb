describe "optionmerger", proxy: :OptionMerger do
  moneta_store :Memory

  it '#with should return OptionMerger' do
    options = {optionname: :optionvalue}
    merger = store.with(options)
    merger.should be_instance_of(Moneta::OptionMerger)
  end

  it 'saves default options' do
    options = {optionname: :optionvalue}
    merger = store.with(options)
    Moneta::OptionMerger::METHODS.each do |method|
      merger.default_options[method].should equal(options)
    end
  end

  PREFIX = [['alpha', nil], ['beta', nil], ['alpha', 'beta']]

  it 'merges options' do
    merger = store.with(opt1: :val1, opt2: :val2).with(opt2: :overwrite, opt3: :val3)
    Moneta::OptionMerger::METHODS.each do |method|
      merger.default_options[method].should == {opt1: :val1, opt2: :overwrite, opt3: :val3}
    end
  end

  it 'merges options only for some methods' do
    PREFIX.each do |(alpha,beta)|
      options = {opt1: :val1, opt2: :val2, prefix: alpha}
      merger = store.with(options).with(opt2: :overwrite, opt3: :val3, prefix: beta, only: :clear)
      (Moneta::OptionMerger::METHODS - [:clear]).each do |method|
        merger.default_options[method].should equal(options)
      end
      merger.default_options[:clear].should == {opt1: :val1, opt2: :overwrite, opt3: :val3, prefix: "#{alpha}#{beta}"}

      merger = store.with(options).with(opt2: :overwrite, opt3: :val3, prefix: beta, only: [:load, :store])
      (Moneta::OptionMerger::METHODS - [:load, :store]).each do |method|
        merger.default_options[method].should equal(options)
      end
      merger.default_options[:load].should == {opt1: :val1, opt2: :overwrite, opt3: :val3, prefix: "#{alpha}#{beta}"}
      merger.default_options[:store].should == {opt1: :val1, opt2: :overwrite, opt3: :val3, prefix: "#{alpha}#{beta}"}
    end
  end

  it 'merges options except for some methods' do
    PREFIX.each do |(alpha,beta)|
      options = {opt1: :val1, opt2: :val2, prefix: alpha}
      merger = store.with(options).with(opt2: :overwrite, opt3: :val3, except: :clear, prefix: beta)
      (Moneta::OptionMerger::METHODS - [:clear]).each do |method|
        merger.default_options[method].should == {opt1: :val1, opt2: :overwrite, opt3: :val3, prefix: "#{alpha}#{beta}"}
      end
      merger.default_options[:clear].should equal(options)

      merger = store.with(options).with(opt2: :overwrite, opt3: :val3, prefix: beta, except: [:load, :store])
      (Moneta::OptionMerger::METHODS - [:load, :store]).each do |method|
        merger.default_options[method].should == {opt1: :val1, opt2: :overwrite, opt3: :val3, prefix: "#{alpha}#{beta}"}
      end
      merger.default_options[:load].should equal(options)
      merger.default_options[:store].should equal(options)
    end
  end

  it 'has method #raw' do
    store.raw.default_options.should == {store:{raw:true},create:{raw:true},load:{raw:true},delete:{raw:true}}
    store.raw.should equal(store.raw.raw)
  end

  it 'has method #expires' do
    store.expires(10).default_options.should == {store:{expires:10},create:{expires:10},increment:{expires:10}}
  end

  it 'has method #prefix' do
    store.prefix('a').default_options.should == {store:{prefix:'a'},load:{prefix:'a'},create:{prefix:'a'},
                                                 delete:{prefix:'a'},key?: {prefix:'a'},increment:{prefix:'a'}}

    store.prefix('a').prefix('b').default_options.should == {store:{prefix:'ab'},load:{prefix:'ab'},create:{prefix:'ab'},
                                                             delete:{prefix:'ab'},key?: {prefix:'ab'},increment:{prefix:'ab'}}

    store.raw.prefix('b').default_options.should == {store:{raw:true,prefix:'b'},load:{raw:true,prefix:'b'},create:{raw:true,prefix:'b'},delete:{raw:true,prefix:'b'},key?: {prefix:'b'},increment:{prefix:'b'}}

    store.prefix('a').raw.default_options.should == {store:{raw:true,prefix:'a'},load:{raw:true,prefix:'a'},create:{raw:true,prefix:'a'},delete:{raw:true,prefix:'a'},key?: {prefix:'a'},increment:{prefix:'a'}}
  end

  it 'supports adding proxis using #with' do
    compressed_store = store.with(prefix: 'compressed') do
      use :Transformer, value: :zlib
    end
    store['key'] = 'uncompressed value'
    compressed_store['key'] = 'compressed value'
    store['key'].should == 'uncompressed value'
    compressed_store['key'].should == 'compressed value'
    store.key?('compressedkey').should be true
    # Check if value is compressed
    compressed_store['key'].should_not == store['compressedkey']
  end
end
