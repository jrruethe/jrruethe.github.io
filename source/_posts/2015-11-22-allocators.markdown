---
layout: post
title: "C++ Allocators"
date: 2015-11-22 16:10:49 -0500
comments: true
categories: 
---

This post will discuss how to make a STL compliant allocator.

All of the standard containers support a 2nd (or 3rd) template parameter to specify the allocator that should be used. Each container allocates memory to store the objects it contains, and it uses the allocator to obtain the memory required for this storage. By using a custom allocator, you can remain in control of how memory is managed.

Custom allocators are useful for a variety of cases:

 - Reducing system call overhead when requesting multiple small memory blocks
 - Improving cache efficiency by keeping memory contiguous
 - Using standard containers with memory-mapped io, or a memory-mapped file for persistent containers
 - Maintaining 100% control of memory for embedded systems or game development

Wikipedia summarizes it well[^1]:
>
One of the main reasons for writing a custom allocator is performance. Utilizing a specialized custom allocator may substantially improve the performance or memory usage, or both, of the program. The default allocator uses operator new to allocate memory. This is often implemented as a thin layer around the C heap allocation functions, which are usually optimized for infrequent allocation of large memory blocks. This approach may work well with containers that mostly allocate large chunks of memory, like vector and deque. However, for containers that require frequent allocations of small objects, such as map and list, using the default allocator is generally slow. Other common problems with a malloc-based allocator include poor locality of reference, and excessive memory fragmentation.

The allocators discussed in this post are meant to be used with C++03. C++11 adds more support for custom allocators, and makes them easier to implement. Furthermore, C++03 allocators are compatible with C++11, but not the other way around.

Creating a custom allocator may seem difficult, but the core concept is pretty simple. Here are the basic rules:

 - Cannot have state (C++03 only)
 - Must support certain typedefs and methods
 - Must support type rebinding
 - Allocators of the same type must compare equally

No state also means no virtual functions, as the vtable can be considered state. Normal inheritance is okay, however it is generally considered bad practice to derive from std::allocator. Instead, we will create our own allocator using policies and traits. The methods that need to be implemented can be separated into two categories: those that are related to the allocator, and those that are related to the object being allocated. This distinction defines the policy and traits we will implement.[^2]

>
**Policies and Traits**[^3]  
Policies are classes (or class templates) to inject behavior into a parent class, typically through inheritance. By decomposing a parent interface into orthogonal (independent) dimensions, policy classes form the building blocks of more complex interfaces. Traits are class templates to extract properties from a generic type. Traits are often used in template-metaprogramming and SFINAE tricks to overload a function template based on a type condition.

### Object Traits

The first thing to define is the object traits. This structure is responsible for creating and destroying objects, as well as returning the address of an object. Note that classes support overriding the "address-of" operator, so the object traits will need to be specialized for those classes. The object traits can also be specialized for a type to keep track of the number of instantiations using the allocator, much like the object counter works.

{% codeblock lang:c++ %}

template<typename T>
class object_traits
{
public:

   typedef T type;

   template<typename U>
   struct rebind
   {
   	typedef object_traits<U> other;
   };

   // Constructor
   object_traits(void){}

   // Copy Constructor
   template<typename U>
   object_traits(object_traits<U> const& other){}

   // Address of object
   type*       address(type&       obj) const {return &obj;}
   type const* address(type const& obj) const {return &obj;}

   // Construct object
   void construct(type* ptr, type const& ref) const
   {
		// In-place copy construct
		new(ptr) type(ref);
   }

   // Destroy object
   void destroy(type* ptr) const
   {
		// Call destructor
		ptr->~type();
   }
};

{% endcodeblock %}

### Rebinding

Notice the special `rebind` struct in the above code. This is a convention used by the STL to allow for chainging the type of the allocator. For example, when you make a `std::list<T>`, internally the type is being rebound to `std::list<Node<T> >`, because lists store nodes that contain a T, not the T itself. To support this, the allocator itself must support rebinding such that memory is allocated for the node, not just T.

### Allocator Traits

The allocator policies require a certain set of typedefs to be present. In most cases, they can all be derived from the type of the allocator, so it makes sense to use a macro:

{% codeblock lang:c++ %}

#define ALLOCATOR_TRAITS(T)                \
typedef T                 type;            \
typedef type              value_type;      \
typedef value_type*       pointer;         \
typedef value_type const* const_pointer;   \
typedef value_type&       reference;       \
typedef value_type const& const_reference; \
typedef std::size_t       size_type;       \
typedef std::ptrdiff_t    difference_type; \

{% endcodeblock %}

### Allocator Policy

Next, the actual allocator policy needs to be defined. The allocator policy is responsible for allocating and deallocating memory. For this example, a simple heap allocator will work. The functionality will mimic that of the standard allocator:

{% codeblock lang:c++ %}

template<typename T>
struct max_allocations
{
	enum{value = static_cast<std::size_t>(-1) / sizeof(T)};
};

template<typename T>
class heap
{
public:

	ALLOCATOR_TRAITS(T)

	template<typename U>
	struct rebind
	{
		typedef heap<U> other;
	};

	// Default Constructor
	heap(void){}

	// Copy Constructor
	template<typename U>
	heap(heap<U> const& other){}

	// Allocate memory
	pointer allocate(size_type count, const_pointer /* hint */ = 0)
	{
		if(count > max_size()){throw std::bad_alloc();}
		return static_cast<pointer>(::operator new(count * sizeof(type), ::std::nothrow));
	}

	// Delete memory
	void deallocate(pointer ptr, size_type /* count */)
	{
		::operator delete(ptr);
	}

	// Max number of objects that can be allocated in one call
	size_type max_size(void) const {return max_allocations<T>::value;}
};

{% endcodeblock %}

### Allocator

Now that we have all the pieces, it is time to bring them all together. The actual allocator class is nothing more than a wrapper to combine the above into one common place. The key to the allocator wrapper is that it inherits from the allocator policy and object traits, thus the combination satisfies all the requirements for a compliant allocator.

{% codeblock lang:c++ %}

#define FORWARD_ALLOCATOR_TRAITS(C)                  \
typedef typename C::value_type      value_type;      \
typedef typename C::pointer         pointer;         \
typedef typename C::const_pointer   const_pointer;   \
typedef typename C::reference       reference;       \
typedef typename C::const_reference const_reference; \
typedef typename C::size_type       size_type;       \
typedef typename C::difference_type difference_type; \

template<typename T,
         typename PolicyT = heap<T>,
         typename TraitsT = object_traits<T> >
class allocator : public PolicyT,
                  public TraitsT
{
public:
    
    // Template parameters
    typedef PolicyT Policy;
    typedef TraitsT Traits;
    
    FORWARD_ALLOCATOR_TRAITS(Policy)
    
    template<typename U>
    struct rebind
    {
       typedef allocator<U,
                         typename Policy::template rebind<U>::other,
                         typename Traits::template rebind<U>::other
                        > other;
    };
    
    // Constructor
    allocator(void){}
    
    // Copy Constructor
    template<typename U,
             typename PolicyU,
             typename TraitsU>
    allocator(allocator<U,
                        PolicyU,
                        TraitsU> const& other) :
       Policy(other),
       Traits(other)
    {}
};

{% endcodeblock %}

Notice how the rebinding structure works here; the policy and traits classes are both rebound to the new type when the overall allocator is rebound.

### Equality operators

The STL uses the equality operator to determine if memory allocated by one allocator can be deallocated with another. Normally, a heap allocator can be used interchangably between types, so the equality operator would return true. However, with this allocator framework, different policies can be plugged in, and some policies may not be interchangable. Therefore, the equality operator will default to false. Specializations of the equality operators can be made for specific policies to register equality, such as he heap policy:

{% codeblock lang:c++ %}

// Two allocators are not equal unless a specialization says so
template<typename T, typename PolicyT, typename TraitsT,
         typename U, typename PolicyU, typename TraitsU>
bool operator==(allocator<T, PolicyT, TraitsT> const& left,
                allocator<U, PolicyU, TraitsU> const& right)
{
   return false;
}

// Also implement inequality
template<typename T, typename PolicyT, typename TraitsT,
         typename U, typename PolicyU, typename TraitsU>
bool operator!=(allocator<T, PolicyT, TraitsT> const& left,
                allocator<U, PolicyU, TraitsU> const& right)
{
   return !(left == right);
}

// Comparing an allocator to anything else should not show equality
template<typename T, typename PolicyT, typename TraitsT,
         typename OtherAllocator>
bool operator==(allocator<T, PolicyT, TraitsT> const& left,
                OtherAllocator const& right)
{
   return false;
}

// Also implement inequality
template<typename T, typename PolicyT, typename TraitsT,
         typename OtherAllocator>
bool operator!=(allocator<T, PolicyT, TraitsT> const& left,
                OtherAllocator const& right)
{
	return !(left == right);
}

// Specialize for the heap policy
template<typename T, typename TraitsT,
         typename U, typename TraitsU>
bool operator==(allocator<T, heap<T>, TraitsT> const& left,
                allocator<U, heap<U>, TraitsU> const& right)
{
   return true;
}

// Also implement inequality
template<typename T, typename TraitsT,
         typename U, typename TraitsU>
bool operator!=(allocator<T, heap<T>, TraitsT> const& left,
                allocator<U, heap<U>, TraitsU> const& right)
{
   return !(left == right);
}

{% endcodeblock %}

### Using the Allocator

Using the allocator is simple, just pass it into the 2nd (or 3rd) template parameter of a container. Remember that some containers (like `set`) have a second template parameter that accepts a comparator.

{% codeblock lang:c++ %}

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
		std::set<Example, std::less<Example>, allocator<Example, heap<Example> > > foo;

		foo.insert(Example(3));
		foo.insert(Example(1));
		foo.insert(Example(4));
		foo.insert(Example(2));
	}
	// Leaving scope
}

{% endcodeblock %}

And that is how to make an allocator! A future blog post will discuss different policies that can be created.

[^1]: [What is the difference between a trait and a policy?](http://stackoverflow.com/questions/14718055/what-is-the-difference-between-a-trait-and-a-policy/14723986#14723986) - TemplateRex
[^2]: [C++ Standard Allocator, An Introduction and Implementation](http://www.codeproject.com/Articles/4795/C-Standard-Allocator-An-Introduction-and-Implement) - Lai Shiaw San Kent
[^3]: [Allocator (C++)](https://en.wikipedia.org/wiki/Allocator_%28C%2B%2B%29#Custom_allocators)