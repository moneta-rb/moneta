shared_examples_for "a read/write Moneta cache" do
  {"String" => ["key", "key2"], "Object" => [{:foo => :bar}, {:bar => :baz}]}.each do |type, (key, key2)|
    it "reads from keys that are #{type}s like a Hash" do
      @cache[key].should == nil
    end

    it "writes to keys that are #{type}s like a Hash" do
      @cache[key] = "value"
      @cache[key].should == "value"
    end

    it "returns false from key? if a #{type} key is not available" do
      @cache.key?(key).should be_false
    end

    it "returns true from key? if a #{type} key is available" do
      @cache[key] = "value"
      @cache.key?(key).should be_true
    end

    it "removes and return an element with a #{type} key from the backing store via delete if it exists" do
      @cache[key] = "value"
      @cache.delete(key).should == "value"
      @cache.key?(key).should be_false
    end

    it "returns nil from delete if an element for a #{type} key does not exist" do
      @cache.delete(key).should be_nil
    end

    it "removes all #{type} keys from the store with clear" do
      @cache[key] = "value"
      @cache[key2] = "value2"
      @cache.clear
      @cache.key?(key).should_not be_true
      @cache.key?(key2).should_not be_true
    end

    it "fetches a #{type} key with a default value with fetch, if the key is not available" do
      @cache.fetch(key, "value").should == "value"
    end

    it "fetches a #{type} key with a block with fetch, if the key is not available" do
      @cache.fetch(key) { |k| "value" }.should == "value"
    end

    it "fetches a #{type} key with a default value with fetch, if the key is available" do
      @cache[key] = "value2"
      @cache.fetch(key, "value").should == "value2"
    end

    it "stores #{key} values with #store" do
      @cache.store(key, "value")
      @cache[key].should == "value"
    end
  end

  it "refuses to #[] from keys that cannot be marshalled" do
    lambda do
      @cache[Struct.new(:foo).new(:bar)]
    end.should raise_error(TypeError)
  end

  it "refuses to fetch from keys that cannot be marshalled" do
    lambda do
      @cache.fetch(Struct.new(:foo).new(:bar), true)
    end.should raise_error(TypeError)
  end

  it "refuses to #[]= to keys that cannot be marshalled" do
    lambda do
      @cache[Struct.new(:foo).new(:bar)] = "value"
    end.should raise_error(TypeError)
  end

  it "refuses to store to keys that cannot be marshalled" do
    lambda do
      @cache.store Struct.new(:foo).new(:bar), "value"
    end.should raise_error(TypeError)
  end

  it "refuses to check for key? if the key cannot be marshalled" do
    lambda do
      @cache.key? Struct.new(:foo).new(:bar)
    end.should raise_error(TypeError)
  end

  it "refuses to delete a key if the key cannot be marshalled" do
    lambda do
      @cache.delete Struct.new(:foo).new(:bar)
    end.should raise_error(TypeError)
  end

  it "specifies that it is writable via frozen?" do
    @cache.should_not be_frozen
  end
end