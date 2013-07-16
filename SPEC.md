# Moneta Specification

(See RFC 2119 for use of MUST, SHOULD, MAY, MUST NOT, and SHOULD NOT)

The purpose of the moneta specification is to create a general-purpose API for interacting with key-value stores. In general, libraries that need to interact with key-value stores should be able to specify that they can use any "moneta-compliant store". Moneta ships with a set of executable specs which you can use to verify spec-compliance with your moneta adapter.

## Class Methods

### <code>new(options[Hash] => {}) => Object</code>

Return an instance of the moneta adapter, with the instance methods listed below. The <code>options</code> hash is a required parameter, and the adapter may specify whatever additional requirements it needs to properly instantiate it.

## Instance Methods

### <code>\[\](key[Object]) => Object</code>

Return the value stored in the key-value-store under the provided key. Adapters MUST return a duplicate of the original value, and consumers should expect that adapters might serialize and deserialize the key and value. As a result, both the key and value MUST be objects that can be serialized using Ruby's Marshal system.

### <code>\[\]=(key[Object], value[Object]) => Object(value)</code>

Store the value in the key-value-store under the provided key. Adapters MAY serialize the value using Ruby's Marshal system, and MUST NOT store a reference to the original value in the store, unless Ruby disallows duplication of the original value. Adapters SHOULD NOT simply call <code>dup</code> on the value, unless the value stores no references to other Object. For example, an adapter MAY store a <code>dup</code> of a String, but SHOULD NOT store a <code>dup</code> of <code>["hello", "world"]</code>.

### <code>fetch(key[Object], options[Hash] => {}, &block) => Object</code>

Return the value stored in the key-value-store under the provided key. If no value is stored under the provided key, the adapter MUST yield to the block, and return the value. The adapter MUST NOT store the value returned from the block in the key-value-store.

### <code>fetch(key[Object], value[Object], options[Hash] => {}) => Object</code>

Return the value stored in the key-value-store under the provided key. If no value is stored under the provided key, the adapter MUST return the default value provided. The adapter MUST NOT store the default value in the key-value-store.

### <code>delete(key[Object], options[Hash] => {}) => Object</code>

Delete the value stored in the key-value-store for the key provided, and return the value previously stored there. After this operation, the key-value-store MUST behave as though no value was stored for the provided key.

### <code>key?(key[Object], options[Hash] => {}) => [TrueClass, FalseClass]</code>

Determine whether a value exists in the key-value-store for the key provided. If a value exists, the adapter MUST return <code>true</code>. Otherwise, the adapter MUST return <code>false</code>.

### <code>store(key[Object], value[Object], options[Hash] => {}) => Object(value)</code>

Behaves the same as <code>[]=</code>, but allows the client to send additional options which can be specified by the adapter (and which may be specified by extensions to this specification).

### <code>increment(key[Object], amount[Integer] = 1, options[Hash] => {}) => Integer(value)</code>

Increments a value atomically. This method is not supported by all stores and might raise a <code>NotImplementedError</code>.
This method MUST accept negative amounts, but the result MUST be unsigned.

### <code>decrement(key[Object], amount[Integer] = 1, options[Hash] => {}) => Integer(value)</code>

Decrements a value atomically. This method is not supported by all stores and might raise a <code>NotImplementedError</code>.
This method MUST accept negative amounts, but the result MUST be unsigned.

### <code>create(key[Object], value[Object], options[Hash] => {}) => [TrueClass, FalseClass]</code>

Creates a value atomically. This method is not supported by all stores and might raise a <code>NotImplementedError</code>.
It MUST return true if the value was created.

### <code>clear(options[Hash] => {})</code>

Completely empty all keys and values from the key-value-store. Adapters MAY allow a namespace during initialization, which can scope this operation to a particular subset of keys. After calling <code>clear</code>, a <code>[]</code> operation MUST return nil for every possible key, and a <code>key?</code> query MUST return false for every possible key.

### <code>close</code>

Closes the store

### <code>features => Array&lt;Symbol&gt;</code> and <code>supports?(Symbol) => [TrueClass, FalseClass]</code>

Feature detection. Adapters MUST return <code>:create</code> and <code>:increment</code> if these methods are supported.

## Additional Options Hashes

The following methods may all take an additional Hash as a final argument. This allows the client to send additional options which can be specified by the adapter (and which may be specified by extensions to this specification). The methods MUST NOT modify the supplied option hash.

* fetch
* load
* store
* delete
* key?
* increment
* clear

In the case of methods with optional arguments, the Hash MUST be provided as the final argument. Keys in this Hash MUST be Symbols.

## Atomicity

The base Moneta specification does not specify any atomicity guarantees. However, extensions to this spec may specify extensions that define additional guarantees for any of the defined operations.
