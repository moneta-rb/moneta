shared_examples :concurrent_increment do
  def increment_thread(name)
    Thread.new do
      s = new_store
      begin
        # Create an array where each entry is a list of all the return values
        # from calling increment for a particular key.
        increments = (0...100).map { [] }
        100.times do
          100.times do |j|
            increments[j] << s.increment(j.to_s, 1, expires: false).tap do
              Thread.pass if rand(1000) >= 995
            end
          end
        end
        increments
      ensure
        s.close
      end
    end
  end

  it 'have atomic increment across multiple threads', isolate: true do
    results = %w{a b c}
      .map { |name| increment_thread(name) }
      .map(&:value)
      .transpose # Now the array is indexed by store key instead of thread

    # Sanity check
    expect(results.length).to eq 100

    results.each do |ith_values|
      # ensure that for each pair in the triple there are no overlapping values
      expect(ith_values.combination(2).map { |a, b| a & b }).to all be_empty

      # ensure that when joined together they cover the full 1..300 range
      expect(ith_values.inject(:+)).to contain_exactly(*1..300)
    end
  end
end
