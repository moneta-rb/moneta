RSpec.shared_examples :adapter_sequel do |specs, optimize: true|
  shared_examples :each_key_server do
    context "with each_key server" do
      let(:opts) do
        base_opts.merge(
          servers: {each_key: {}},
          each_key_server: :each_key
        )
      end

      moneta_specs specs
    end

    context "without each_key server" do
      let(:opts) { base_opts }
      moneta_specs specs
    end
  end

  if optimize
    context 'with backend optimizations' do
      let(:base_opts) { {table: "adapter_sequel"} }

      include_examples :each_key_server
    end
  end

  context 'without backend optimizations' do
    let(:base_opts) do
      {
        table: "adapter_sequel",
        optimize: false
      }
    end

    include_examples :each_key_server
  end
end
