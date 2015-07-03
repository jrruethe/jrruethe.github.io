---
layout: post
title: "Object Counter"
date: 2015-07-01 17:47:47 -0400
comments: true
categories: 
---

This post presents a lightweight generic object counter in C++. Object counters count the number of objects that have been created, as well as how many bytes they are utilizing. They are a handy way to get a sense of application health programatically as well as detect memory leaks with unit tests.

The code itself doesn't have any dependencies (not even Boost!). The example however uses Boost smart pointers, so you need the following installed to run it:

 - libboost-dev

This object counter is loosely modeled after Scott Meyer's[^1] counter, with the following differences:

 - Tracks creations as well as active objects, useful for determining if lots of copies are happening.
 - Tracks allocations on the heap
 - Tracks number of bytes allocated for the object

The code itself is pretty straightforward:

{% codeblock lang:c++ %}

#include <cstddef>

template<typename T>
struct ObjectCounter
{
   typedef T Type;
   typedef unsigned long long Count;

   static Count objects_created;
   static Count objects_created_on_heap;

   static Count objects_active;
   static Count objects_active_on_heap;

   static Count bytes_allocated;
   static Count bytes_allocated_on_heap;

   ObjectCounter(void)
   {
      ++objects_created;
      ++objects_active;
      bytes_allocated += sizeof(Type);
   }

   ObjectCounter(ObjectCounter const& other)
   {
      ++objects_created;
      ++objects_active;
      bytes_allocated += sizeof(Type);
   }

   ~ObjectCounter(void)
   {
      --objects_active;
      bytes_allocated -= sizeof(Type);
   }

   void* operator new(std::size_t bytes)
   {
      ++objects_created_on_heap;
      ++objects_active_on_heap;
      bytes_allocated_on_heap += sizeof(Type);

      return ::operator new(bytes);
   }

   void operator delete(void* ptr)
   {
      --objects_active_on_heap;
      bytes_allocated_on_heap -= sizeof(Type);
      
      return ::operator delete(ptr);
   }

   static void reset(void)
   {
      objects_created = 0;
      objects_created_on_heap = 0;
      objects_active = 0;
      objects_active_on_heap = 0;
      bytes_allocated = 0;
      bytes_allocated_on_heap = 0;
   }
};

template<typename T> typename ObjectCounter<T>::Count ObjectCounter<T>::objects_created(0);
template<typename T> typename ObjectCounter<T>::Count ObjectCounter<T>::objects_created_on_heap(0);
template<typename T> typename ObjectCounter<T>::Count ObjectCounter<T>::objects_active(0);
template<typename T> typename ObjectCounter<T>::Count ObjectCounter<T>::objects_active_on_heap(0);
template<typename T> typename ObjectCounter<T>::Count ObjectCounter<T>::bytes_allocated(0);
template<typename T> typename ObjectCounter<T>::Count ObjectCounter<T>::bytes_allocated_on_heap(0);

{% endcodeblock %}

Using the object counter is simple: just inherit from it, and everything else happens automatically. 

One very nice thing about this class is that it doesn't have any non-static data members. That means that inheriting from it allows the compiler to perform the *empty base optimization*, which means the inheriting object does not increase in size at all! 

>
**No Virtual Destructor?**  
Technically, classes that are intended to be inherited are supposed to define a virtual destructor to ensure that the derived class' memory gets cleaned up if it is deleted through a pointer to the base class. Doing this causes the object counter to no longer be empty, and I don't want to give that up. The object counter has one purpose, and developers should by convention not pass around object counter pointers.

Time to test it out. Before that, I'm going to introduce a little trick I learned from Evan Wallace[^2] that gives us a nice Python-style print command to avoid all the `cout` boilerplate:

{% codeblock lang:c++ %}

namespace __hidden__
{
   struct print
   {
      print() :
         space(false)
      {

      }

      ~print()
      {
         std::cout << std::endl;
      }

      template<typename T>
      print& operator,(T const& t)
      {
         if(space) std::cout << ' ';
         else space = true;
         std::cout << t;
         return *this;
      }

      bool space;
   };
}

#define print __hidden__::print(),

{% endcodeblock %}

This is a really clever trick that I would like to expand upon in a future post. Back to our test code:

{% codeblock lang:c++ %}

struct TestObject
{
   typedef char byte;
   byte data[4]; // Store 4 bytes
};

struct Object : public ObjectCounter<Object>
{
   typedef char byte;
   byte data[4]; // Store 4 bytes
};

int main(int argc, char* argv[])
{
   print "Object size  :", sizeof(TestObject)           , "bytes";
   print "Counter size :", sizeof(ObjectCounter<Object>), "bytes";
   print "Total size   :", sizeof(Object)               , "bytes";
   print "";

   // Increase scope
   {
      // Create an object on the stack
      Object a;

      print "Single:";
      print " - Objects created         :", ObjectCounter<Object>::objects_created;
      print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
      print " - Objects active          :", ObjectCounter<Object>::objects_active;
      print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
      print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
      print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
      print "";

      // Create an array of objects on the stack
      Object b[2];

      print "Array:";
      print " - Objects created         :", ObjectCounter<Object>::objects_created;
      print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
      print " - Objects active          :", ObjectCounter<Object>::objects_active;
      print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
      print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
      print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
      print "";

      // Create a vector of objects on the stack
      std::vector<Object> c;
      c.push_back(Object());

      print "Vector:";
      print " - Objects created         :", ObjectCounter<Object>::objects_created;
      print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
      print " - Objects active          :", ObjectCounter<Object>::objects_active;
      print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
      print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
      print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
      print "";

      // Copy an object
      Object d(a);

      print "Copy:";
      print " - Objects created         :", ObjectCounter<Object>::objects_created;
      print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
      print " - Objects active          :", ObjectCounter<Object>::objects_active;
      print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
      print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
      print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
      print "";
   }
   // Objects are now gone

   print "Out of Scope:";
   print " - Objects created         :", ObjectCounter<Object>::objects_created;
   print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
   print " - Objects active          :", ObjectCounter<Object>::objects_active;
   print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
   print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
   print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
   print "";

   ObjectCounter<Object>::reset();

   print "Reset:";
   print " - Objects created         :", ObjectCounter<Object>::objects_created;
   print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
   print " - Objects active          :", ObjectCounter<Object>::objects_active;
   print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
   print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
   print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
   print "";

   // Create an object on the heap
   Object* a_ptr = new Object();

   print "New:";
   print " - Objects created         :", ObjectCounter<Object>::objects_created;
   print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
   print " - Objects active          :", ObjectCounter<Object>::objects_active;
   print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
   print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
   print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
   print "";

   // Delete an object from the heap
   delete a_ptr;

   print "Delete:";
   print " - Objects created         :", ObjectCounter<Object>::objects_created;
   print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
   print " - Objects active          :", ObjectCounter<Object>::objects_active;
   print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
   print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
   print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
   print "";

   // Create a smart pointer
   {
      boost::shared_ptr<Object> b_ptr(new Object());

      print "Smart Pointer:";
      print " - Objects created         :", ObjectCounter<Object>::objects_created;
      print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
      print " - Objects active          :", ObjectCounter<Object>::objects_active;
      print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
      print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
      print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
      print "";
   }
   // Smart pointer destroyed

   print "Smart Pointer Destroyed:";
   print " - Objects created         :", ObjectCounter<Object>::objects_created;
   print " - Objects created on heap :", ObjectCounter<Object>::objects_created_on_heap;
   print " - Objects active          :", ObjectCounter<Object>::objects_active;
   print " - Objects active on heap  :", ObjectCounter<Object>::objects_active_on_heap;
   print " - Bytes allocated         :", ObjectCounter<Object>::bytes_allocated;
   print " - Bytes allocated on heap :", ObjectCounter<Object>::bytes_allocated_on_heap;
   print "";
}

{% endcodeblock %}

This gives the following output:

{% codeblock lang:yaml %}

Object size  : 4 bytes
Counter size : 1 bytes
Total size   : 4 bytes

Single:
 - Objects created         : 1
 - Objects created on heap : 0
 - Objects active          : 1
 - Objects active on heap  : 0
 - Bytes allocated         : 4
 - Bytes allocated on heap : 0

Array:
 - Objects created         : 3
 - Objects created on heap : 0
 - Objects active          : 3
 - Objects active on heap  : 0
 - Bytes allocated         : 12
 - Bytes allocated on heap : 0

Vector:
 - Objects created         : 5
 - Objects created on heap : 0
 - Objects active          : 4
 - Objects active on heap  : 0
 - Bytes allocated         : 16
 - Bytes allocated on heap : 0

Copy:
 - Objects created         : 6
 - Objects created on heap : 0
 - Objects active          : 5
 - Objects active on heap  : 0
 - Bytes allocated         : 20
 - Bytes allocated on heap : 0

Out of Scope:
 - Objects created         : 6
 - Objects created on heap : 0
 - Objects active          : 0
 - Objects active on heap  : 0
 - Bytes allocated         : 0
 - Bytes allocated on heap : 0

Reset:
 - Objects created         : 0
 - Objects created on heap : 0
 - Objects active          : 0
 - Objects active on heap  : 0
 - Bytes allocated         : 0
 - Bytes allocated on heap : 0

New:
 - Objects created         : 1
 - Objects created on heap : 1
 - Objects active          : 1
 - Objects active on heap  : 1
 - Bytes allocated         : 4
 - Bytes allocated on heap : 4

Delete:
 - Objects created         : 1
 - Objects created on heap : 1
 - Objects active          : 0
 - Objects active on heap  : 0
 - Bytes allocated         : 0
 - Bytes allocated on heap : 0

Smart Pointer:
 - Objects created         : 2
 - Objects created on heap : 2
 - Objects active          : 1
 - Objects active on heap  : 1
 - Bytes allocated         : 4
 - Bytes allocated on heap : 4

Smart Pointer Destroyed:
 - Objects created         : 2
 - Objects created on heap : 2
 - Objects active          : 0
 - Objects active on heap  : 0
 - Bytes allocated         : 0
 - Bytes allocated on heap : 0

{% endcodeblock %}

Everything looks correct, but take a look at line 22 of the output. This is a case where a temporary copy happened when loading the object into the vector. These are cases where C++11's move semantics are able to help. The object counter's copy constructor could be modified to also track copies being made, that is left as an exercise for the reader.

[^1]: [Counting Objects in C++ by Scott Meyers](http://ptgmedia.pearsoncmg.com/imprint_downloads/informit/aw/meyerscddemo/demo/MAGAZINE/CO_FRAME.HTM)
[^2]: [Obscure C++ Features by Evan Wallace](http://madebyevan.com/obscure-cpp-features/)