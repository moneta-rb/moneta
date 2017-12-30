shared_examples :features do
  it 'should report correct features' do
    store.features.sort_by(&:to_s).should == features
  end

  it 'should have frozen features' do
    store.features.frozen?.should be true
  end

  it 'should have #supports?' do
    features.each do |f|
      store.supports?(f).should be true
    end
    store.supports?(:unknown).should be false
  end
end
