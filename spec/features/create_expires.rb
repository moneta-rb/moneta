shared_examples :create_expires do
  shared_examples :create_expires_at_usec do |usec|
    context "at #{usec} microseconds" do
      include_context :at_usec, usec

      it 'creates the given key and expires it' do
        store.create('key','value', expires: min_ttl).should be true
        store['key'].should == 'value'
        sleep min_ttl + t_res
        store.key?('key').should be false
      end

      it 'does not change expires if the key exists' do
        store.store('key', 'value', expires: false).should == 'value'
        store.create('key','another value', expires: min_ttl).should be false
        store['key'].should == 'value'
        sleep min_ttl + t_res
        store['key'].should == 'value'
        store.key?('key').should be true
      end
    end
  end

  usecs.each{ |usec| include_examples :create_expires_at_usec, usec }
end
