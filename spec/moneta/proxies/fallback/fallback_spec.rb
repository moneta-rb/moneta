describe 'fallback', proxy: :Fallback do
  context 'when the adapter is working' do
    moneta_build do
      Moneta.build do
        use :Fallback
        adapter :Memory
      end
    end

    moneta_specs STANDARD_SPECS.without_transform.returnsame.without_persist.with_each_key
  end

  context 'when the adapter is broken' do
    moneta_build do
      Moneta.build do
        use :Fallback #, rescue: [IOError, NoMethodError]
        adapter(Class.new do
          include Moneta::Defaults

          def load(key, options = {})
            raise IOError, "deliberate error for load"
          end

          def store(key, value, options = {})
            raise IOError, "deliberate error for store"
          end

          def delete(key, options = {})
            raise IOError, "deliberate error for delete"
          end

          def clear(options = {})
            raise IOError, "deliberate error for clear"
          end
        end.new)
      end
    end

    # Null adapter behaviour
    moneta_specs MonetaSpecs.new(specs: [:null, :not_increment, :not_create, :not_persist])
  end
end
