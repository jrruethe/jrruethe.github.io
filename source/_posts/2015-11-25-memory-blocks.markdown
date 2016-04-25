---
layout: post
title: "Memory Blocks"
date: 2015-11-25 16:10:58 -0500
comments: true
categories: 
 - C++
 - Memory
---

Memory pools work by taking a large chunk of memory and dealing out small pieces of it upon allocation requests. 
Object pools are a specialized version that treat the memory as an array of objects, such that each "slot" is the same size. 
In reality, managing an object pool involves more than *just* an array of objects due to alignment and padding.

When doing 100% of your own memory management, it becomes useful to have a set of tools to assist with organizing memory. 
You can think of a chunk of memory as being similar to an empty hard drive; the act of aligning, partitioning, and padding the memory is similar to formatting a hard drive with a filesystem.

{% more %}

# Allocating Memory

There are a few different ways to acquire a block of memory. The following lines allocate a block of 32 bytes:

    char memory[32];
    char* memory = static_cast<char*>(malloc(32));

Notice how `sizeof(memory)` for each of those lines will give different results. A contiguous block of memory is represented by a starting address and a size; both values are needed to do anything useful with it. For static and local stack memory, the size is known at compile time, however for dynamic memory allocated on the heap, the size must be maintained separately. 

# Memory Block

A class that acts similar to a smart pointer for memory blocks can do the memory management for us, including holding the size and calling free upon destruction. The following is an implementation of a memory block class:

{% codeblock lang:c++ %}

struct block
{
	typedef char byte;

	// Constructor, size in bytes
	block(std::size_t size) :
		_memory(0),
		_size(size)
	{
		if(size > 0) _memory = static_cast<byte*>(malloc(size));
	}

	// Default Constructor
	block(void) :
		_memory(0),
		_size(0)
	{}

	// Destructor
	~block(void) {if(_memory) free(_memory);}

	// Access a specific byte of memory
	byte& operator[](unsigned int i){return _memory[i];}
	byte const& operator[](unsigned int i) const {return _memory[i];}

	// Dereference operator makes the block act like a pointer
	byte& operator*(void) {return *_memory;}
	byte const& operator*(void) const {return *_memory;}

	// Address-of operator returns the address of the memory
	byte* operator&(void) {return _memory;}
	byte const* operator&(void) const {return _memory;}

	// Size of the memory in bytes
	std::size_t size(void) const {return _size;}

protected:
	byte* _memory;
	std::size_t _size;
};

{% endcodeblock %}

Using this class is simple:

{% codeblock lang:c++ %}

int main(int argc, char* argv[])
{
	block memory(32);
	memset(&memory, 0x41, memory.size());
	std::cout << memory.size() << std::endl;
	std::cout << *memory << std::endl;
	std::cout << memory[1] << std::endl;
}

{% endcodeblock %}

Outputs:

    32
    A
    A

As you can see, the memory block class acts just like a pointer to an array of bytes. This is a convienient building block for creating an object pool.

# Padding

When creating an array of objects, you may need to ensure that each object is properly aligned. If you ensure that the first object is aligned, and that each object is padded properly, then you have the guarantee that *all* the objects in the array are aligned. Padding the object will result in some excess space being used in order to make sure the next object is properly aligned. Below is a small helper class that can pad any type to the next multiple of `X` bytes.

{% codeblock lang:c++ %}

template<typename T, std::size_t multiple = 0>
struct pad
{
	enum{value = ((sizeof(T) + multiple - 1) / multiple) * multiple};
};

template<typename T>
struct pad<T, 0>
{
	enum{value = sizeof(T)};
};

{% endcodeblock %}

Here is an example:

{% codeblock lang:c++ %}

struct Data
{
	char buffer[17];
};

int main(int argc, char* argv[])
{
	std::cout << sizeof(Data) << std::endl;
	std::cout << pad<Data, 2>::value << std::endl;
	std::cout << pad<Data, 4>::value << std::endl;
	std::cout << pad<Data, 8>::value << std::endl;
	std::cout << pad<Data, 16>::value << std::endl;
}

{% endcodeblock %}

Outputs:

    17
    18
    20
    24
    32

# Partitioning

Once you have a raw memory block, it needs to be partitioned before it can be used. The act of partitioning will align and pad the memory block and allow slots to be accessed for object storage. In other words, a partitioned memory block will act just like an array:

{% codeblock lang:c++ %}

template<typename T,
			std::size_t align = 0>
class partition
{
public:

	// Pad T for alignment
	enum{unit = pad<T, align>::value};

	// Default Constructor
	partition(void) :
		_memory(0),
		_size(0)
	{}

	// Constructor
	partition(void* memory,
			    std::size_t size) :
	   _memory(boundary<align>::next(memory)),
	   _size(size)
	{}
	
	// Return the number of T's that can fit inside the memory
	std::size_t capacity(void) const
	{

		return std::max(_size - align, static_cast<std::size_t>(0)) / unit;
	}

	// Access a specific T
	T& operator[](unsigned int i)
	{
		if(i >= capacity()){throw std::out_of_range("");}
		return *reinterpret_cast<T*>(
					 reinterpret_cast<std::size_t>(
					    _memory) + (i * unit));
	}

protected:
	void* _memory;
	std::size_t _size;
};


{% endcodeblock %}

Here is some example usage, borrowing the memory dumper from a [previous blog post](http://jrruethe.github.io/blog/2015/08/23/placement-new/):

{% codeblock lang:c++ %}

struct Data
{
	Data(void)
	{
	   memset(buffer, 0xAA, sizeof(buffer));
	}

	char buffer[6];
};

int main(int argc, char* argv[])
{
	char memory[54];
    memset(memory, 0xCC, sizeof(memory));

	partition<Data, 8> array(&memory, sizeof(memory));

	dump_memory(memory, sizeof(memory));

	std::cout << array.capacity() << std::endl;
	printf("0x%016lX\n", &memory[0]);
	printf("0x%016lX\n", &array[0]);
	printf("0x%016lX\n", &array[1]);
	printf("0x%016lX\n", &array[2]);

	array[0] = Data();
	array[3] = Data();
	array[4] = Data();

	dump_memory(memory, sizeof(memory));
}

{% endcodeblock %}

Here is the output:

    -----------------------------------------------------------------------
    54 bytes              0  1  2  3   4  5  6  7   8  9  A  B   C  D  E  F
    0x00007FFFE9D71680:  CC CC CC CC  CC CC CC CC  CC CC CC CC  CC CC CC CC
    0x00007FFFE9D71690:  CC CC CC CC  CC CC CC CC  CC CC CC CC  CC CC CC CC
    0x00007FFFE9D716A0:  CC CC CC CC  CC CC CC CC  CC CC CC CC  CC CC CC CC
    0x00007FFFE9D716B0:  CC CC CC CC  CC CC
    -----------------------------------------------------------------------
    5
    0x00007FFFE9D71680
    0x00007FFFE9D71688
    0x00007FFFE9D71690
    0x00007FFFE9D71698
    -----------------------------------------------------------------------
    54 bytes              0  1  2  3   4  5  6  7   8  9  A  B   C  D  E  F
    0x00007FFFE9D71680:  CC CC CC CC  CC CC CC CC  AA AA AA AA  AA AA CC CC
    0x00007FFFE9D71690:  CC CC CC CC  CC CC CC CC  CC CC CC CC  CC CC CC CC
    0x00007FFFE9D716A0:  AA AA AA AA  AA AA CC CC  AA AA AA AA  AA AA CC CC
    0x00007FFFE9D716B0:  CC CC CC CC  CC CC
    -----------------------------------------------------------------------
    
As you can see, the data objects stored inside the partitioned memory are padded and 8 byte aligned. The alignment caveats mentioned in the [previous post](http://jrruethe.github.io/blog/2015/08/23/placement-new/) apply, including the wasted space at the beginning of the array.
