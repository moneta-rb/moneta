require 'moneta'
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
end
