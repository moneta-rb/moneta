# Juno Specification

The purpose of the juno specification is to create a general-purpose API for interacting with key-value stores. In general, libraries that need to interact with key-value stores should be able to specify that they can use any "juno-compliant store".

# Juno Executable Specs

Juno ships with a set of executable specs which you can use to verify spec-compliance with your juno adapter.

# Juno Library

Juno ships with proof-of-concept adapters for over a dozen key-value stores, including in-memory, memcache, database-backed and S3. These adapters are meant as proofs-of-concept, and while the juno project intends to maintain them (and will accept patches to improve them), you should not consider them the core of the project.

# Requirements for a Juno Adapter

(See RFC 2119 for use of MUST, SHOULD, MAY, MUST NOT, and SHOULD NOT)

A Juno adapter must expose a class with the following characteristics:

## Class Methods

### <code>new(options[Hash]) => Object</code>

Return an instance of the juno adapter, with the instance methods listed below. The <code>options</code> hash is a required parameter, and the adapter may specify whatever additional requirements it needs to properly instantiate it.

## Instance Methods

### <code>\[\](key[Object]) => Object</code>

Return the value stored in the key-value-store under the provided key. Adapters MUST return a duplicate of the original value, and consumers should expect that adapters might serialize and deserialize the key and value. As a result, both the key and value MUST be objects that can be serialized using Ruby's Marshal system.

### <code>\[\]=(key[Object], value[Object]) => Object(value)</code>

Store the value in the key-value-store under the provided key. Adapters MAY serialize the value using Ruby's Marshal system, and MUST NOT store a reference to the original value in the store, unless Ruby disallows duplication of the original value. Adapters SHOULD NOT simply call <code>dup</code> on the value, unless the value stores no references to other Object. For example, an adapter MAY store a <code>dup</code> of a String, but SHOULD NOT store a <code>dup</code> of <code>["hello", "world"]</code>.

### <code>fetch(key[Object]) => Object</code>

Return the value stored in the key-value-store under the provided key. If no value is stored under the provided key, the adapter MUST raise an IndexError.

### <code>fetch(key[Object], &block) => Object</code>

Return the value stored in the key-value-store under the provided key. If no value is stored under the provided key, the adapter MUST yield to the block, and return the value. The adapter MUST NOT store the value returned from the block in the key-value-store.

### <code>fetch(key[Object], value[Object]) => Object</code>

Return the value stored in the key-value-store under the provided key. If no value is stored under the provided key, the adapter MUST return the default value provided. The adapter MUST NOT store the default value in the key-value-store.

### <code>delete(key[Object]) => Object</code>

Delete the value stored in the key-value-store for the key provided, and return the value previously stored there. After this operation, the key-value-store MUST behave as though no value was stored for the provided key.

### <code>key?(key[Object]) => [TrueClass, FalseClass]</code>

Determine whether a value exists in the key-value-store for the key provided. If a value exists, the adapter MUST return <code>true</code>. Otherwise, the adapter MUST return <code>false</code>.

### <code>store(key[Object], value[Object]) => Object(value)</code>

Behaves the same as <code>[]=</code>, but allows the client to send additional options which can be specified by the adapter (and which may be specified by extensions to this specification).

### <code>clear</code>

Completely empty all keys and values from the key-value-store. Adapters MAY allow a namespace during initialization, which can scope this operation to a particular subset of keys. After calling <code>clear</code>, a <code>[]</code> operation MUST return nil for every possible key, and a <code>key?</code> query MUST return false for every possible key.

# Additional Options Hashes

The following methods may all take an additional Hash as a final argument. This allows the client to send additional options which can be specified by the adapter (and which may be specified by extensions to this specification).

* fetch
* store
* delete
* key?
* clear

In the case of methods with optional arguments, the Hash MUST be provided as the final argument, and all optional arguments MUST be specified.

Keys in this Hash MUST be Strings or Symbols. If they are Strings, they MUST be prefixed with a unique namespace. Namespaces MUST be separated from the name of the key with a single ".". The namespace SHOULD be the name of the gem that exposes the key.

Keys in this Hash MUST NOT be Symbols unless this specification or an official extension to this specification defines a Symbol key.

# Key Equality

Adapters MUST consider keys as equal to one another if and only if the value of <code>Marshal.dump(keya)</code> is the same (byte-for-byte) as <code>Marshal.dump(keyb)</code>. This does not mean that adapters are required to use <code>Marshal.dump</code> to calculate the key to use for a given key specified by the consumer of the adapter. However, if an adapter does not, it MUST guarantee that the value returned for every key is identical to the value that would be returned if it did a byte-for-byte comparison of the result of <code>Marshal.dump</code> for every operation involving a key.

# Storage and Serialization

In a Juno-compliant adapter, any Ruby object that can be serialized using Ruby's marshalling system may be used for keys or values.

Adapters MAY use the marshalling system to serialize Ruby objects. Adapters MUST NOT return an Object from a fetch operation that existed on the heap prior to the fetch operation. The intention of this requirement is to prevent adapters that use the heap for persistence to store direct references to Objects passed into the <code>store</code> or <code>[]=</code> methods.

# Atomicity

The base Juno specification does not specify any atomicity guarantees. However, extensions to this spec may specify extensions that define additional guarantees for any of the defined operations.

# Expiry

The base Juno specification does not specify any mechanism for time-based expiry. However, extensions to this spec may specify mechanisms (using <code>store</code> to provide expiration semantics.
