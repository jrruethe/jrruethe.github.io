---
layout: post
title: "Object Pool"
date: 2015-11-26 16:11:06 -0500
comments: true
toc: true
categories: 
 - C++
 - Templates
 - Memory
---

An object pool is a specialized allocator that allocates memory in large chunks and deals them out in small slices. 
Malloc is typically an expensive call, especially for multiple small allocations, so significant performance improvements can be gained by managing memory directly. 
The object pool presented here is compatible with C++03, supports all standard containers, and offers O(1) amortized allocation and deallocation with configurable growth, limits, and alignment.

The pool works by allocating blocks of memory, partitioning them for the object type and alignment, then pushing all the addresses onto a stack representing available slots. 
Each allocation pops an address off the stack, each deallocation pushes an allocation onto the stack. When the stack is empty, another block is allocated and added to the linked list of blocks.

{% more %}

# Stack

The primary component of the object pool is the stack of addresses that represent free memory slots for objects. However, this isn't implemented like a typical stack; rather, the stack itself is interleaved through the free slots of the memory block. This means no additional memory is required; the data structure that manages the free memory is stored *within* the free memory it is managing! Each free slot, which would normally be zeroed out, instead points to the next free slot. Pushing and popping simply involves overwriting these pointers.

{% codeblock lang:c++ %}

template<typename T>
struct stack
{
	typedef T*       pointer;
	typedef pointer* metapointer;

	stack(void) :
		_top(NULL),
		_size(0)
	{}

	void push(pointer ptr)
	{
		// Store the current pointer at the given address
		*(reinterpret_cast<metapointer>(ptr)) = _top;

		// Advance the pointer
		_top = ptr;

		// Increment the size
		++_size;
	}

	pointer pop(void)
	{
		if(empty()){throw std::out_of_range("");}

		// Pop the top of the stack
		pointer retval = _top;

		// Step back to the previous address
		_top = *(reinterpret_cast<metapointer>(_top));

		// Decrement the size
		--_size;

		// Return the next free address
		return retval;
	}

	pointer top(void) const {return _top;}
	unsigned int size(void) const {return _size;}
	bool empty(void) const {return _size == 0;}

protected:
	pointer _top;
	unsigned int _size;
};

{% endcodeblock %}

# Node

If the object pool were statically sized, then only a single memory block would be required, and no linked list would be needed. However, to support growth, each memory block is treated as a node in a linked list, allowing for a dynamic number of blocks (and therefore a dynamic amount of allocated memory). 

{% codeblock lang:c++ %}

template<typename T>
struct node
{
	T& value(void)
	{
		return _object;
	}

	node* link(node* next)
	{
		_next = next;
		return _next;
	}

	node* next(void) const
	{
		return _next;
	}

	template<typename U>
	node(U const& arg) :
		_object(arg),
		_next(0)
	{}

	node(void) :
		_object(),
		_next(0)
	{}

protected:
	T _object;
	node* _next;
};

{% endcodeblock %}

# Growth

The growth of the pool can be controlled via a template parameter. This parameter is a functor that takes the current size of the pool and returns the new size that the pool should grow to. I provide functors to do exponential growth (like a vector) or linear growth, but it is easy to add a custom one to fine tune growth for your application.

{% codeblock lang:c++ %}

struct growth
{
	virtual std::size_t operator()(std::size_t const& value) const = 0;
};

struct exponential : public growth
{
	std::size_t operator()(std::size_t const& value) const
	{
		return value;
	}
};

template<std::size_t increment>
struct linear : public growth
{
	std::size_t operator()(std::size_t const& value) const
	{
		return increment;
	}
};

{% endcodeblock %}

# Pool

Finally, the pieces can all be put together to create the object pool. Allocation and deallocation consists of pushing and popping from the stack. If the stack is ever emptied, the pool grows by another block. The pool uses lazy allocation and has an efficient copy constructor to allow for quick rebinding; necessary for the standard containers.

{% codeblock lang:c++ %}

template<typename T,
			std::size_t align = 0,
			std::size_t initial_size = 1,
			std::size_t final_size = max_allocations<T>::value,
			typename growth = exponential>
struct pool
{
	typedef T type;

	typedef boundary<align> alignment;
	typedef pad<T, align> padding;

	enum{unit = padding::value};

	// Satisfy the allocator traits
	typedef type              value_type;
	typedef value_type*       pointer;
	typedef value_type const* const_pointer;
	typedef value_type&       reference;
	typedef value_type const& const_reference;
	typedef std::size_t       size_type;
	typedef std::ptrdiff_t    difference_type;

	typedef unsigned char byte;
	typedef pointer* metapointer;

	template<typename U>
	struct rebind
	{
		typedef pool<U, align, initial_size, final_size, growth> other;
	};

	void grow(void)
	{
		// Update the capacity
		_capacity = _size ? _growth(_size) : initial_size;

		// Cap at the final size
		if(_size + _capacity > final_size) _capacity = final_size - _size;

		// Bail out if we hit the upper limit
		if(_capacity <= 0) throw std::bad_alloc();

		// Add this new capacity to our total size
		_size += _capacity;

		// Allocate a new block of memory as a linked list node
		_current = _current->link(new node<block>(_capacity * unit + alignment::value));

		// Access the memory
		void* memory = static_cast<void*>(&_current->value());

		// Shift context to the new memory block
		_context = partition<T, align>(memory, _capacity * unit + alignment::value);

		// Push the slots to the stack
		for(int i = 0; i < _capacity; ++i) _free.push(&_context[i]);
	}

	pointer allocate(size_type count, const_pointer hint = 0)
	{
		// If we are out of slots, add more
		if(_free.empty()) grow();

		// Return the next slot
		return _free.pop();
	}

	void deallocate(pointer ptr, size_type count)
	{
		// Push this pointer onto the free list
		_free.push(ptr);
	}

	size_type max_size(void) const
	{
		// This pool only supports allocating one object at a time
		return 1;
	}

	pool(void) :
		_head(),
		_current(&_head),
		_size(0),
		_capacity(0)
	{}

	template<typename U>
	pool(pool<U, align, initial_size, final_size, growth> const& obj) :
		_head(),
		_current(&_head),
		_size(0),
		_capacity(0)
	{}

	~pool(void)
	{
		// Start at the initial block
		node<block>* current = _head.next();

		// Iterate through each block
		while(current)
		{
			// Get the next block
			node<block>* next = current->next();

			// Delete the current block
			delete current;

			// Advance to the next block
			current = next;
		}
	}

protected:
	node<block>  _head;
	node<block>* _current;
	std::size_t _size;
	std::size_t _capacity;
	partition<T, align> _context;
	stack<T> _free;
	growth _growth;
};

{% endcodeblock %}

# Stateless

C++03 allocators are required to be stateless. The standard containers do not accept an allocator instance, rather they construct one themselves. This means that two `std::set`s of type T will each maintain their own allocator. Clearly, the above pool is not stateless, however we can emulate that behavior by using a singleton. In this manner, there will only ever be one instance of the pool for each type, and all the containers will share the same pool.

This is implemented using a `stateless` allocator adapter. Each call to allocate / deallocate is routed through a singleton to the underlying policy.

{% codeblock lang:c++ %}

template<typename T,
			typename Policy>
struct stateless
{
	// Forward typedefs
	typedef T type;
	typedef type              value_type;
	typedef value_type*       pointer;
	typedef value_type const* const_pointer;
	typedef value_type&       reference;
	typedef value_type const& const_reference;
	typedef std::size_t       size_type;
	typedef std::ptrdiff_t    difference_type;

   template<typename U>
   struct rebind
   {
   	typedef stateless<U, typename Policy::template rebind<U>::other> other;
   };

   stateless(void){}

	template<typename U, typename PolicyU>
	stateless(stateless<U, PolicyU> const& other){}

   pointer allocate(size_type count, const_pointer hint = 0)
   {
   	return Singleton<Policy>::instance().allocate(count, hint);
   }

	void deallocate(pointer ptr, size_type count)
	{
		Singleton<Policy>::instance().deallocate(ptr, count);
	}

	size_type max_size(void) const
	{
		return Singleton<Policy>::instance().max_size();
	}
};

{% endcodeblock %}

# Hybrid

One caveat to the object pool is that it only supports the allocation of a single object at a time. This means the object pool will not work for `vector`s and some implementations of `deque`, because these data structures allocate multiple contiguous objects at a time. However, the point of the object pool is to alleviate performance issues related to multiple calls of malloc with small sizes. Vectors do this automatically, so the object pool cannot improve their performance.

Rather than trying to remember which data structures and implementations the pool supports, it would be better to allow the pool to support *all* the containers. To do this, a `hybrid` allocator adapter is used that forwards all allocations of a single object to the pool, and all allocations of multiple objects to the heap.

{% codeblock lang:c++ %}

template<typename T,
			typename S,
			typename M>
class hybrid : public S,
					public M
{
public:

	// Template parameters
	typedef T type;
	typedef S single;
	typedef M multiple;

	// Satisfy the allocator traits
	typedef type              value_type;
	typedef value_type*       pointer;
	typedef value_type const* const_pointer;
	typedef value_type&       reference;
	typedef value_type const& const_reference;
	typedef std::size_t       size_type;
	typedef std::ptrdiff_t    difference_type;

	template<typename U>
	struct rebind
	{
		typedef hybrid<U,
							typename   single::template rebind<U>::other,
							typename multiple::template rebind<U>::other
						  > other;
	};

	hybrid(void){}

	template<typename U,
				typename SinglePolicyU,
				typename MultiplePolicyU>
	hybrid(hybrid<U,
					  SinglePolicyU,
					  MultiplePolicyU> const& other) :
		single(other),
		multiple(other)
	{}

	// Resolve ambiguities by forwarding allocation / deallocation
	// requests to the proper policy
	pointer allocate(size_type count, const_pointer hint = 0)
	{
		if(count == 1)
		{
			return single::allocate(count, hint);
		}
		else
		{
			return multiple::allocate(count, hint);
		}
	}

	void deallocate(pointer ptr, size_type count)
	{
		if(count == 1)
		{
			single::deallocate(ptr, count);
		}
		else
		{
			multiple::deallocate(ptr, count);
		}
	}

	size_type max_size(void) const
	{
		return multiple::max_size();
	}
};

{% endcodeblock %}

# Final Result

The pool and all of it's pieces are very configurable, but a good set of defaults can be selected that will work just fine for most cases. It is best to take all the policies, traits, and adapters, and fold them all together into a single struct or typedef to make it easier to use. Then, it can be simply plugged into the allocator template parameter of any standard container.

{% codeblock lang:c++ %}

template<typename T>
struct fast_allocator : public
   allocator<T,
   			 hybrid<T,
   			 	 	  stateless<T,
   			 	 	  	  	  	   pool<T,
   			 	 	  	  	  	   	  16,
   			 	 	  	  	  	   	  16,
   			 	 	  	  	  	   	  max_allocations<T>::value,
   			 	 	  	  	  	   	  exponential
   			 	 	  	  	  	   	 >
									  >,
   			 	 	  heap<T,
   			 	 	       16
   			 	 	  	   >
						 >,
			    object_traits<T>
				>
{};

typedef std::set<Foo, std::less<Foo>, fast_allocator<Foo> > PooledFooSet;

{% endcodeblock %}
