/// Copyright 2022 OmniBTC Authors. Licensed under Apache-2.0 License.
module owner::vec_queue {
    use std::option::{Self, Option};
    use std::vector;

    /// This key already exists in the map
    const EKeyAlreadyExists: u64 = 0;

    /// This key does not exist in the map
    const EKeyDoesNotExist: u64 = 1;

    /// This index is out of inner contents.
    const EOutOfIndex: u64 = 2;

    /// A set data structure backed by a vector. The set is guaranteed not to contain duplicate keys.
    /// All operations are O(N) in the size of the set--the intention of this data structure is only to provide
    /// the convenience of programming against a set API.
    /// Sets that need sorted iteration rather than insertion order iteration should be handwritten.
    struct VecQueue<K: copy + drop> has copy, drop, store {
        contents: vector<K>,
        cap: u64,
    }

    /// Create an empty `VecSet`
    public fun empty<K: copy + drop>(cap: u64): VecQueue<K> {
        VecQueue { contents: vector::empty(), cap }
    }

    /// Insert a `key` into self.
    /// Aborts if `key` is already present in `self`.
    public fun insert<K: copy + drop>(self: &mut VecQueue<K>, key: K) {
        assert!(!contains(self, &key), EKeyAlreadyExists);
        if (vector::length(&self.contents) > self.cap) {
            // remove first key
            vector::remove(&mut self.contents, 0);
        };
        vector::push_back(&mut self.contents, key);
    }

    /// Remove the entry `key` from self. Aborts if `key` is not present in `self`.
    public fun remove<K: copy + drop>(self: &mut VecQueue<K>, key: &K) {
        let idx = get_idx(self, key);
        vector::remove(&mut self.contents, idx);
    }

    /// Remove the entry by index. Aborts if `idx` is out of inner vector.
    public fun remove_by_index<K: copy + drop>(self: &mut VecQueue<K>, idx: u64) {
        assert!(idx < size(self), EOutOfIndex);
        vector::remove(&mut self.contents, idx);
    }

    /// Return true if `self` contains an entry for `key`, false otherwise
    public fun contains<K: copy + drop>(self: &VecQueue<K>, key: &K): bool {
        option::is_some(&get_idx_opt(self, key))
    }

    /// Return the number of entries in `self`
    public fun size<K: copy + drop>(self: &VecQueue<K>): u64 {
        vector::length(&self.contents)
    }

    /// Return true if `self` has 0 elements, false otherwise
    public fun is_empty<K: copy + drop>(self: &VecQueue<K>): bool {
        size(self) == 0
    }

    /// Unpack `self` into vectors of keys.
    /// The output keys are stored in insertion order, *not* sorted.
    public fun into_keys<K: copy + drop>(self: VecQueue<K>): vector<K> {
        let VecQueue { contents, cap: _cap } = self;
        contents
    }

    // == Helper functions ==

    /// Find the index of `key` in `self. Return `None` if `key` is not in `self`.
    /// Note that keys are stored in insertion order, *not* sorted.
    fun get_idx_opt<K: copy + drop>(self: &VecQueue<K>, key: &K): Option<u64> {
        let i = 0;
        let n = size(self);
        while (i < n) {
            if (vector::borrow(&self.contents, i) == key) {
                return option::some(i)
            };
            i = i + 1;
        };
        option::none()
    }

    /// Find the index of `key` in `self. Aborts if `key` is not in `self`.
    /// Note that map entries are stored in insertion order, *not* sorted.
    fun get_idx<K: copy + drop>(self: &VecQueue<K>, key: &K): u64 {
        let idx_opt = get_idx_opt(self, key);
        assert!(option::is_some(&idx_opt), EKeyDoesNotExist);
        option::destroy_some(idx_opt)
    }
}
