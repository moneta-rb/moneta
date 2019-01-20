shared_examples :concurrent_create do
  def create_thread(name)
    Thread.new do
      s = new_store
      1000.times do |i|
        s[i.to_s].should == name if s.create(i.to_s, name, expires: false)
        Thread.pass if rand(100) >= 99
      end
      s.close
    end
  end

  it 'have atomic create across multiple threads', isolate: true do
    a = create_thread('a')
    b = create_thread('b')
    c = create_thread('c')
    a.join
    b.join
    c.join
  end
end
