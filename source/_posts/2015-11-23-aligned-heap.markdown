---
layout: post
title: "Aligned Heap"
date: 2015-11-23 18:01:02 -0500
comments: true
categories: 
---

In the [previous post](http://jrruethe.github.io/blog/2015/11/22/allocators/), I introduced an allocator framework that supports pluggable policies. An example heap policy was given. This post will expand on the heap to give it alignment abilities. You may want to refer to [another previous post](http://jrruethe.github.io/blog/2015/08/23/placement-new/) on alignment.

The code modifications are simple; allocate a little more data, align the pointer when allocating, then unalign it before deallocating:

{% codeblock lang:c++ %}

template<typename T,
		   std::size_t align = 0>
class heap
{
public:

	ALLOCATOR_TRAITS(T)

	template<typename U>
	struct rebind
	{
		typedef heap<U, align> other;
	};

	// Default Constructor
	heap(void){}

	// Copy Constructor
	template<typename U>
	heap(heap<U, align> const& other){}

	// Allocate memory
	pointer allocate(size_type count, const_pointer hint = 0)
	{
		// Request additional memory to perform alignment
		void* ptr = ::operator new((count * sizeof(type)) + boundary<align>::value, ::std::nothrow);

		// Align the pointer
		return static_cast<pointer>(boundary<align>::align(ptr));
	}

	// Deallocate memory
	void deallocate(pointer ptr, size_type count)
	{
		// Unalign the pointer and delete the memory
		::operator delete(boundary<align>::unalign(ptr));
	}

	// Max number of objects that can be allocated in one call
	size_type max_size(void) const {return max_allocations<T>::value;}
};


{% endcodeblock %}

Using the aligned heap no different than the previous version. If you leave out the alignment template parameter, it will act the same as before.

{% codeblock lang:c++ mark:21 %}

#include <set>

struct Example
{
	int value;

	Example(int v) :
		value(v)
	{}

	bool operator<(Example const& other) const
	{
		return value < other.value;
	}
};

int main(int argc, char* argv[])
{
	// Increase scope
	{
		std::set<Example, std::less<Example>, allocator<Example, heap<Example, 16> > > foo;

		foo.insert(Example(3));
		foo.insert(Example(1));
		foo.insert(Example(4));
		foo.insert(Example(2));
	}
	// Leaving scope
}

{% endcodeblock %}
