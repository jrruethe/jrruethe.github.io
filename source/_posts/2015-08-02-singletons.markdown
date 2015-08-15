---
layout: post
title: "Singletons"
date: 2015-08-02 15:55:58 -0400
comments: true
categories: 
---

The Singleton pattern is a design pattern that restricts the instantiation of a class to one object. It is typically used for solving the problem of resource contention, such that you need to manage a single instance of a resource. Singletons are misunderstood and difficult to implement correctly, hopefully this post can clear things up.

It is known as an anti-pattern in that it is often misused or abused to the point where it can have a negative effect on a code base. Opponents to Singletons compare them to global variables, but that is not entirely true; As an object-oriented pattern, they can implement interfaces and be subclassed, which gives them more useful properties than a normal global. That said, Singletons are considered harmful[^1] for a variety of reasons:

 - Singletons make code hard to follow
 - Singletons make code hard to test
 - Singletons make code hard to maintain
 - Singletons make code hard to secure

The reason for this is because the use of a Singleton hides the dependency from the interface, giving program flow a path that is not easily visible.

>
Singletons are nothing more than global state. Global state makes it so your objects can secretly get hold of things which are not declared in their APIs, and, as a result, Singletons make your APIs into pathological liars. If you are the person who built the code originally, you know the true dependencies, but anyone who comes after you is baffled.[^2]

Note that there is a difference between having a single object and having a Singleton. Passing around a single instance to share among your classes via constructor references is known as dependency injection, and is a cleaner solution for most problems that a Singleton can solve. Take the following for example:

    // Singleton approach
    Constructor(void)
    {
        this->single_instance = Singleton::instance()
    }
    
    // Dependency Injection approach
    Constructor(SingleInstance& instance) :
        single_instance(instance)
    {

    }

With the second approach, it becomes very clear from the interface that the object depends on SingleInstance. This dependency is hidden with the first approach. The second approach can also be tested easier by subclassing the SingleInstance to make a testable version.

Still, there are cases where Singletons are very useful:

 - Debug Logging
 - Memory Pools
 - Factories
   - [Abstract Factory](https://sourcemaking.com/design_patterns/abstract_factory)
   - [Builder](https://sourcemaking.com/design_patterns/builder)
   - [Prototype](https://sourcemaking.com/design_patterns/prototype)

In these types of situations, there is one object that has a single responsibility and must be accessible from anywhere. In particular, a memory pool using a Singleton is not very different from allocating memory from the heap using the global `::operator new`. 

Configuration is sometimes done with Singletons, however this isn't considered a good practice. Dependency injection is typically a better way to handle passing configuration through your program.

## Creating a Singleton

Singletons conform to the following conditions[^3]:

 - Private static attribute in the class.
 - Public static accessor function in the class.
 - Perform creation on first use in the accessor function.
 - All constructors are protected or private.
 - Clients may only use the accessor function to manipulate the Singleton.

Creating a Singleton is much harder than it appears, and there are very subtle considerations that are easy to miss or implement incorrectly. A few examples are:

 - Lazy instantiation
 - Proper destruction
 - Thread safety
 - Instruction reordering

A first cut at a Singleton may look something like this:

{% codeblock lang:c++ %}

#include <iostream>

template<typename T>
class Singleton
{
public:

   static T& instance(void)
   {
      if(!pointer)
      {
         pointer = new T();
      }

      return *pointer;
   }

private:

   Singleton(void){}

   static T* pointer;
};

template<typename T> T* Singleton<T>::pointer;

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}

{% endcodeblock %}

Running this produces the following output:

    Beginning of main
    Hello!
    0x1e2a370 : 0x1e2a370

Notice the following:

 - The constructor was only called once
 - The addresses are the same, meaning there is only one object
 - The destructor was never called
 - The object was created lazily (on first request)

>
**Return a pointer or reference?**  
The advantage to returning a reference instead of a pointer is:  

>
 - You can be assured that there won't be a null pointer
 - The user will be unable to delete the pointer
 - No need to dereference to use overloaded operators

This falls apart when multi-threading is introduced. Consider the following events:

 1. Thread 1 may get through line 8 
 2. Thread 2 could pass all the way through to line 14
 3. Thread 1 then performs line 10 again

This situation causes two `T`'s plus a memory leak. Furthermore, both threads are now pointing at different objects.

To make it thread safe, a mutex can be used:

{% codeblock lang:cpp mark:11,26,30 %}

#include <iostream>
#include <boost/thread/mutex.hpp>

template<typename T>
class Singleton
{
public:

   static T& instance(void)
   {
      boost::mutex::scoped_lock lock(mutex);

      if(!pointer)
      {
         pointer = new T();
      }

      return *pointer;
   }

private:

   Singleton(void){}

   static T* pointer;
   static boost::mutex mutex;
};

template<typename T> T* Singleton<T>::pointer;
template<typename T> boost::mutex Singleton<T>::mutex;

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}

{% endcodeblock %}

Now, only one thread is able to pass line 10 at a time, making the logic that follows thread safe. However, mutexes are expensive to acquire, and every call to `instance` requires locking the mutex, even though it really only needs to be locked when the object needs to be created the very first time. So a common thing to do is check whether the instance needs to be created before locking the mutex:

{% codeblock lang:c++ start:9 mark:11-12,19 %}

static T& instance(void)
{
   if(!pointer)
   {
      boost::mutex::scoped_lock lock(mutex);

      if(!pointer)
      {
         pointer = new T();
      }
   }

   return *pointer;
}

{% endcodeblock %}

This approach is called the Double-Checked Locking Pattern, or DCLP. 

## The Double-Checked Locking Pattern is Unsafe

Scott Meyers and Andrei Alexandrescu have discussed[^4] the subtle issues with DCLP. Their paper as an interesting read; the problems boil down to the fact that the compiler may reorder instructions or the hardware may reorder memory accesses, and there was no way to express these constraints using the C++ language at the time (C++11 fixes these issues, as we will see later).

For example, the compiler may do the following:

{% codeblock lang:c++ start:9 mark:17-19 %}

static T& instance(void)
{
   if(!pointer)
   {
      boost::mutex::scoped_lock lock(mutex);

      if(!pointer)
      {
         pointer =                     // 3
            ::operator new(sizeof(T)); // 1
         new (pointer) T();            // 2
      }
   }
   return *pointer;
}

{% endcodeblock %}

Here, the actual construction is broken down into three steps:

 1. Allocating memory for the object
 2. Constructing the object
 3. Assigning the pointer to the memory

The paper claims that DCLP can only work if steps 1 and 2 are completed before step 3, however the compiler's optimizer is free to perform step 3 after step 1. This means there could be a brief moment where the pointer is pointing to allocated memory, but an unconstructed object. Imagine the following scenario:

 1. Thread 1 may get through line 10 (completing steps 1 and 3, but not 2)
 2. Thread 2 gets to line 3, passes the check, and skips to line 15, returning an unconstructed object
 
This type of bug is very subtle and not obvious to the developer. Furthermore, these types of crashes are virtually impossible to track down.
 
## Fixing the Double-Checked Locking Pattern

One way to get around the multi-threaded issues is to have one object for each thread, instead of one object globally. A per-thread Singleton[^5] can be implemented like this:

{% codeblock lang:c++ %}

#include <boost/thread.hpp>

template<typename T>
class ThreadSingleton
{
public:
    static T& instance(void)
    {
        static boost::thread_specific_ptr<T> pointer;

        if(!pointer.get())
        {
           pointer.reset(new T());
        }

        return *pointer;
    }

protected:

    ThreadSingleton(void);
};

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

void run(void)
{
   Hello& hello = ThreadSingleton<Hello>::instance();
   Hello& hello2 = ThreadSingleton<Hello>::instance();
   std::cout << "Thread 2: " << &hello << " : " << &hello2 << std::endl;
}

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   boost::thread thread = boost::thread(&run);
   Hello& hello = ThreadSingleton<Hello>::instance();
   Hello& hello2 = ThreadSingleton<Hello>::instance();
   std::cout << "Thread 1: " << &hello << " : " << &hello2 << std::endl;
   thread.join();
}

{% endcodeblock %}

Notice how this method is closer to what we initially started with: A single check with no mutex. Because the thread specific pointer will never be accessed concurrently by multiple threads, this solution is inherently thread safe. Here are there results of running this code:

    Beginning of main
    Hello!
    Thread 1: 0x17d96e0 : 0x17d96e0
    Hello!
    Thread 2: 0x7f7c500008c0 : 0x7f7c500008c0
    Goodbye!
    Goodbye!
    
As you can see, each thread creates (and destroys) its per-thread Singleton. You can see that each Singleton has a different address as well.

>
**Warning**  
Thread specific pointers should always be static. They use their address as the key to establish uniqueness. A program storing their thread specific pointer on the stack will have issues when two threads reach the same point in the program, because their addresses on the stack will match (remember that each thread has its own stack). This will cause the two pointers to believe they are pointing at the same[^6].

In some cases, this solution is acceptable. Most times, a true global Singleton is desired. 

The paper claims that the DCLP can be made safe with the addition of memory fences. These provide guarantees that reads will not be reordered before writes.
The C++11 standard includes this capability, and Boost has made it available to C++03.
In fact, Boost provides a solution in their documentation[^7] (modified to match the templated format used earlier):

{% codeblock lang:c++ mark:12,18,24,35,39 %}

#include <iostream>
#include <boost/atomic.hpp>
#include <boost/thread/mutex.hpp>

template<typename T>
class Singleton
{
public:

   static T& instance(void)
   {
      T* pointer = storage.load(boost::memory_order_consume);

      if(!pointer)
      {
         boost::mutex::scoped_lock lock(mutex);

         pointer = storage.load(boost::memory_order_consume);

         if(!pointer)
         {
            pointer = new T();

            storage.store(pointer, boost::memory_order_release);
         }
      }

      return *pointer;
   }

private:

   Singleton(void){}

   static boost::atomic<T*> storage;
   static boost::mutex mutex;
};

template<typename T> boost::atomic<T*> Singleton<T>::storage;
template<typename T> boost::mutex Singleton<T>::mutex;

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}

{% endcodeblock %}

## Enhancing the Singleton

We still have the problem that the destructor is never called. The solution to this is to convert the raw pointer into a scoped_ptr. However, the atomics can only be used with primitive types. We need to apply some[^8] transformations[^9] to the code to decouple the atomic from the pointer:

{% codeblock lang:c++ %}

#include <iostream>
#include <boost/atomic.hpp>
#include <boost/thread/mutex.hpp>

template<typename T>
class Singleton
{
public:

   static T& instance(void)
   {
      bool created = storage.load(boost::memory_order_consume);

      if(!created)
      {
         boost::mutex::scoped_lock lock(mutex);

         created = storage.load(boost::memory_order_consume);

         if(!created)
         {
            pointer = new T();

            storage.store(true, boost::memory_order_release);
         }
      }

      return *pointer;
   }

private:

   Singleton(void){}

   static T* pointer;
   static boost::atomic<bool> storage;
   static boost::mutex mutex;
};

template<typename T> T* Singleton<T>::pointer;
template<typename T> boost::atomic<bool> Singleton<T>::storage;
template<typename T> boost::mutex Singleton<T>::mutex;

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}

{% endcodeblock %}

Now that the pointer is separated from the atomic, we can replace the pointer with the scoped pointer to get the following:

{% codeblock lang:c++ mark:39,52,57 %}

// dclp.cpp
// Copyright (C) 2015 Joe Ruether jrruethe@gmail.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

#include <iostream>
#include <boost/atomic.hpp>
#include <boost/thread/mutex.hpp>
#include <boost/scoped_ptr.hpp>

template<typename T>
class Singleton
{
public:

   static T& instance(void)
   {
      bool created = storage.load(boost::memory_order_consume);

      if(!created)
      {
         boost::mutex::scoped_lock lock(mutex);

         created = storage.load(boost::memory_order_consume);

         if(!created)
         {
            pointer.reset(new T());

            storage.store(true, boost::memory_order_release);
         }
      }

      return *pointer;
   }

private:

   Singleton(void){}

   static boost::scoped_ptr<T> pointer;
   static boost::atomic<bool> storage;
   static boost::mutex mutex;
};

template<typename T> boost::scoped_ptr<T> Singleton<T>::pointer;
template<typename T> boost::atomic<bool> Singleton<T>::storage;
template<typename T> boost::mutex Singleton<T>::mutex;

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}

{% endcodeblock %}

At this point we have a flexible and safe implementation of the DCLP. The output is:

    Beginning of main
    Hello!
    0x19626e0 : 0x19626e0
    Goodbye!

## Boost Pool Method

As I mentioned, I needed a Singleton for a memory pool. Naturally, I decided to see how Boost handles this for their own pool. I searched for all the boost include files with Singleton in their name:

    $ find /usr/include/boost/ -name '*singleton*' -type f
    
    /usr/include/boost/log/detail/singleton.hpp
    /usr/include/boost/test/utils/trivial_singleton.hpp
    /usr/include/boost/accumulators/numeric/detail/pod_singleton.hpp
    /usr/include/boost/thread/detail/singleton.hpp
    /usr/include/boost/pool/singleton_pool.hpp
    /usr/include/boost/serialization/singleton.hpp
    /usr/include/boost/interprocess/detail/windows_intermodule_singleton.hpp
    /usr/include/boost/interprocess/detail/intermodule_singleton.hpp
    /usr/include/boost/interprocess/detail/intermodule_singleton_common.hpp
    /usr/include/boost/interprocess/detail/portable_intermodule_singleton.hpp

Then I used my IDE to dive into each one and see how it was implemented:

    #include <boost/log/detail/singleton.hpp>                      // Call once method
    #include <boost/test/utils/trivial_singleton.hpp>              // Meyer's method
    #include <boost/accumulators/numeric/detail/pod_singleton.hpp> // Static method
    #include <boost/thread/detail/singleton.hpp>                   // Meyer's method
    #include <boost/pool/singleton_pool.hpp>                       // Pool method
    #include <boost/serialization/singleton.hpp>                   // Meyer's method
    
The Meyer's method and the call once method will be discussed later. The static method is simply a wrapper to make something static and isn't particularly interesting:

    template<typename T>
    struct pod_singleton
    {
        static T instance;
    };
    
    template<typename T> 
    T pod_singleton<T>::instance;
    
The real interesting method, that I haven't seen anywhere else yet, is the Boost Pool method. The code included in the later versions of Boost (~1.55) is more difficult to read, however a version from 1.39[^10] is very clear and well commented. The code is repeated below with some minor adjustments:

{% codeblock lang:c++ %}

// Copyright (C) 2000 Stephen Cleary
//
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org for updates, documentation, and revision history.

// The following helper classes are placeholders for a generic "singleton"
//  class.  The classes below support usage of singletons, including use in
//  program startup/shutdown code, AS LONG AS there is only one thread
//  running before main() begins, and only one thread running after main()
//  exits.
//
// This class is also limited in that it can only provide singleton usage for
//  classes with default constructors.
//

// The design of this class is somewhat twisted, but can be followed by the
//  calling inheritance.  Let us assume that there is some user code that
//  calls "singleton_default<T>::instance()".  The following (convoluted)
//  sequence ensures that the same function will be called before main():
//    instance() contains a call to create_object.do_nothing()
//    Thus, object_creator is implicitly instantiated, and create_object
//      must exist.
//    Since create_object is a static member, its constructor must be
//      called before main().
//    The constructor contains a call to instance(), thus ensuring that
//      instance() will be called before main().
//    The first time instance() is called (i.e., before main()) is the
//      latest point in program execution where the object of type T
//      can be created.
//    Thus, any call to instance() will auto-magically result in a call to
//      instance() before main(), unless already present.
//  Furthermore, since the instance() function contains the object, instead
//  of the singleton_default class containing a static instance of the
//  object, that object is guaranteed to be constructed (at the latest) in
//  the first call to instance().  This permits calls to instance() from
//  static code, even if that code is called before the file-scope objects
//  in this file have been initialized.

// T must be: no-throw default constructible and no-throw destructible
template <typename T>
struct Singleton
{
  private:

    struct object_creator
    {
      // This constructor does nothing more than ensure that instance()
      //  is called before main() begins, thus creating the static
      //  T object before multithreading race issues can come up.
      object_creator(void)
      {
         Singleton<T>::instance();
      }

      inline void do_nothing(void) const {}
    };
    static object_creator create_object;

    Singleton(void);

  public:

    typedef T object_type;

    // If, at any point (in user code), singleton_default<T>::instance()
    //  is called, then the following function is instantiated.
    static object_type& instance(void)
    {
      // This is the object that we return a reference to.
      // It is guaranteed to be created before main() begins because of
      //  the next line.
      static object_type obj;

      // The following line does nothing else than force the instantiation
      //  of singleton_default<T>::create_object, whose constructor is
      //  called before main() begins.
      create_object.do_nothing();

      return obj;
    }
};

template <typename T>
typename Singleton<T>::object_creator Singleton<T>::create_object;

#include <iostream>

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}


{% endcodeblock %}

And the output:

    Hello!
    Beginning of main
    0x64dc88 : 0x64dc88
    Goodbye!

Notice that this method does not use lazy instantiation, but rather it uses *eager instantiation*, meaning the Singleton is created before `main` is called. In addition, it properly calls the destructor and is thread safe without any locks or atomics. Despite the author describing this method as "twisted", I think it is rather elegant. Unfortunately, it lacks the ability to do per-thread singletons, and its eager instantiation is a drawback.

## Meyer's Method (C++11)

Things get much easier in C++11. Scott Meyers introduced a very simple and elegant Singleton back in 1996[^11]:

{% codeblock lang:c++ %}

template<typename T>
class Singleton
{
public:

   static T& instance(void)
   {
      static T singleton;
      return singleton;
   }

private:
   Singleton(void);
};

#include <iostream>

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}

{% endcodeblock %}

Outputs:

    Beginning of main
    Hello!
    0x64dc78 : 0x64dc78
    Goodbye!

This method is only thread safe with C++11 and up. It uses lazy instantiation, properly calls the destructor, and doesn't use any mutexes or atomics. With C++11, it is now considered the correct way to implement a Singleton.

## Boost Call Once Method

Meyer's Singleton cannot be used in C++03, but we can get pretty close to it using Boost's `call_once` capabilities.

>
**boost::call_once**  
The call_once function and once_flag type (statically initialized to BOOST_ONCE_INIT) can be used to run a routine exactly once. This can be used to initialize data in a thread-safe manner.[^12]

{% codeblock lang:c++ %}

#include <boost/scoped_ptr.hpp>
#include <boost/thread/once.hpp>
#include <boost/noncopyable.hpp>

template<typename T>
class Singleton : private boost::noncopyable
{
public:

   static T& instance(void)
   {
      boost::call_once(&Singleton::create, flag);
      return *pointer;
   }

protected:

   Singleton(void){}

   static void create(void)
   {
      pointer.reset(new T());
   }

   static boost::scoped_ptr<T> pointer;
   static boost::once_flag flag;
};

template<typename T>
boost::scoped_ptr<T> Singleton<T>::pointer;

template<typename T>
boost::once_flag Singleton<T>::flag = BOOST_ONCE_INIT;

#include <iostream>

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << &hello << " : " << &hello2 << std::endl;
}

{% endcodeblock %}

Output:

    Beginning of main
    Hello!
    0x1d20370 : 0x1d20370
    Goodbye!

## My Method

I'm a pretty big fan of the `call_once` method:

 - Avoids the complications of DCLP
 - Aligns with the preferred C++11 standard method of achieving a Singleton
 - Works with C++03
 - Properly handles destruction
 - Properly handles multi-threading
 - Employs lazy instantiation

With some clever manipulations, we can also get this to work as a per-thread singleton:

 1. Template the pointer type
 2. Store the once flag inside a pointer
 3. Move the code to a base class
 4. Specialize an implementation for each supported pointer type
 5. Thread specific pointers should check if their flag is null when getting an instance

{% codeblock lang:c++ %}

// singleton.cpp
// Copyright (C) 2015 Joe Ruether jrruethe@gmail.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

#include <boost/scoped_ptr.hpp>
#include <boost/thread/once.hpp>
#include <boost/thread/tss.hpp>
#include <boost/noncopyable.hpp>

namespace detail
{
   /////////////////////////////////////////////////////////////////////////////

   template<typename T, template<typename U> class P>
   class SingletonImpl;

   /////////////////////////////////////////////////////////////////////////////

   template<typename T,
            template<typename U> class pointer_type>
   class SingletonBase
   {
   protected:

      static T& reference(boost::once_flag& flag)
      {
         boost::call_once(&SingletonBase::create, flag);
         return *pointer;
      }

      static void create(void)
      {
         pointer.reset(new T());
      }

      static boost::scoped_ptr<T> pointer;
   };

   template<typename T, template<typename U> class P>
   boost::scoped_ptr<T> SingletonBase<T, P>::pointer;

   /////////////////////////////////////////////////////////////////////////////

   template<typename T>
   class SingletonImpl<T, boost::scoped_ptr>
      : public SingletonBase<T, boost::scoped_ptr>
   {
   public:

      static T& instance(void)
      {
         return SingletonImpl::reference(*once_flag_ptr);
      }

   protected:
      static boost::scoped_ptr<boost::once_flag> once_flag_ptr;
   };

   template<typename T>
   boost::scoped_ptr<boost::once_flag>
   SingletonImpl<T, boost::scoped_ptr>::once_flag_ptr(new boost::once_flag());

   /////////////////////////////////////////////////////////////////////////////

   template<typename T>
   class SingletonImpl<T, boost::thread_specific_ptr>
      : public SingletonBase<T, boost::thread_specific_ptr>
   {
   public:

      static T& instance(void)
      {
         if(!once_flag_ptr.get())
            once_flag_ptr.reset(new boost::once_flag());

         return SingletonImpl::reference(*once_flag_ptr);
      }

   protected:
      static boost::thread_specific_ptr<boost::once_flag> once_flag_ptr;
   };

   template<typename T>
   boost::thread_specific_ptr<boost::once_flag>
   SingletonImpl<T, boost::thread_specific_ptr>::once_flag_ptr;

   /////////////////////////////////////////////////////////////////////////////
}

template<typename T>
class Singleton : public detail::SingletonImpl<T, boost::scoped_ptr>{};

template<typename T>
class ThreadSingleton : public detail::SingletonImpl<T, boost::thread_specific_ptr>{};

#include <iostream>
#include <boost/thread.hpp>

struct Hello
{
   Hello(void){std::cout << "Hello!" << std::endl;}
   ~Hello(void){std::cout << "Goodbye!" << std::endl;}
};

void run(void)
{
   Hello& hello = ThreadSingleton<Hello>::instance();
   Hello& hello2 = ThreadSingleton<Hello>::instance();
   std::cout << "Thread 2: " << &hello << " : " << &hello2 << std::endl;
}

int main(int argc, char* argv[])
{
   std::cout << "Beginning of main" << std::endl;
   boost::thread thread = boost::thread(&run);
   Hello& hello = Singleton<Hello>::instance();
   Hello& hello2 = Singleton<Hello>::instance();
   std::cout << "Thread 1: " << &hello << " : " << &hello2 << std::endl;
   thread.join();
}

{% endcodeblock %}

Outputs:

    Beginning of main
    Hello!
    Thread 1: 0x109a700 : 0x109a700
    Hello!
    Thread 2: 0x7f9528000930 : 0x7f9528000930
    Goodbye!
    Goodbye!

And there you have it. Sometimes Singletons are good, sometimes they are evil, and sometimes they are difficult to implement correctly. Hopefully now you understand a little more about this pattern.

[^1]: [Singletons Considered Harmful](http://www.object-oriented-security.org/lets-argue/singletons) - Kenton Varda
[^2]: [Singletons are Pathological Liars](http://misko.hevery.com/2008/08/17/singletons-are-pathological-liars/) - Misko Hevery
[^3]: [Singleton Design Pattern](https://sourcemaking.com/design_patterns/singleton)
[^4]: [C++ and the Perils of Double-Checked Locking](http://www.aristeia.com/Papers/DDJ_Jul_Aug_2004_revised.pdf) - Scott Meyers and Andrei Alexandrescu
[^5]: [Two Useful Singleton Templates](http://www.gameafar.com/gaffer/singletons) - Lachlan Orr
[^6]: [A problem with boost::thread_specific_ptr](http://www.mr-edd.co.uk/blog/thread_specific_ptr_problem) - Edd Dawson
[^7]: [Boost Atomic Usage Examples](http://www.boost.org/doc/libs/1_58_0/doc/html/atomic/usage_examples.html#boost_atomic.usage_examples.singleton)
[^8]: [Acquire and Release Fences](http://preshing.com/20130922/acquire-and-release-fences/) - Jeff Preshing
[^9]: [Is this implementation of DCLP in C++11 correct?](http://stackoverflow.com/questions/30587666/is-this-implementation-of-double-checked-lock-pattern-dclp-in-c11-is-correct) - User TCS
[^10]: [Boost Pool Singleton](http://www.boost.org/doc/libs/1_39_0/boost/pool/detail/singleton.hpp) - Stephen Cleary
[^11]: [The Meyers Singleton](http://www.devarticles.com/c/a/Cplusplus/C-plus-plus-In-Theory-The-Singleton-Pattern-Part-I/4/) - Scott Meyers
[^12]: [Boost Call Once](http://www.boost.org/doc/libs/1_32_0/doc/html/call_once.html)