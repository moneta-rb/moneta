require 'moneta'
describe Moneta::Builder do

  it "raises an error if #use is called after #adapter" do
    expect do
      Moneta::Builder.new do
        adapter :Null
        use :Lock
      end
    end.to raise_error /the adapter is already specified/
  end

  it "raises an error if #adapter called twice" do
    expect do
      Moneta::Builder.new do
        adapter :Null
        adapter :Null
      end
    end.to raise_error /the adapter is already specified/
  end
end
