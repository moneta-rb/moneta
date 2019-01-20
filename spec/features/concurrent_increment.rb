shared_examples :concurrent_increment do
  def increment_thread(name)
    Thread.new do
      s = new_store
      100.times do |i|
        100.times do |j|
          s.increment("counter#{j}", 1, expires: false)
          Thread.pass if rand(1000) >= 995
        end
        s.store("#{name}#{i}", i.to_s, expires: false)
      end
      s.close
    end
  end

  it 'have atomic increment across multiple threads', isolate: true do
    a = increment_thread('a')
    b = increment_thread('b')
    c = increment_thread('c')
    a.join
    b.join
    c.join
    100.times do |i|
      store["a#{i}"].should == i.to_s
      store["b#{i}"].should == i.to_s
      store["c#{i}"].should == i.to_s
    end
    100.times do |j|
      store.raw["counter#{j}"].should == 300.to_s
    end
  end
end
