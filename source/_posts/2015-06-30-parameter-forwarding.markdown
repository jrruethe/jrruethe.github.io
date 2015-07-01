---
layout: post
title: "Parameter Forwarding"
date: 2015-06-30 17:41:55 -0400
comments: true
categories: 
---

C++11 introduced the possibility of "perfect forwarding" and "variadic templates". This allows a function to pass all of its parameters to another function seamlessly. Such abilities are very useful for wrapper classes and factories.

Fortunately, this ability can be emulated in C++03 with the power of Boost and the preprocessor. This post is a guide on how to do parameter forwarding. This concept will be used as a tool in a future post about creating a generic factory class.

For this walkthrough, you will need the following installed:

 - libboost-dev

To start, let's define a simplistic factory class as an example. Our factory for this example will not do much, except return the built object as a smart pointer.

{% codeblock lang:c++ %}
#include <boost/smart_ptr.hpp>

template<typename T>
struct Factory
{
   typedef T Type;
   typedef boost::shared_ptr<T> Pointer;

   Pointer create(void) const
   {
      return Pointer(new Type());
   }
};
{% endcodeblock %}  

The problem with this is that it only supports building objects with the default constructor. Hence, we want to use parameter forwarding to pass parameters from the `create` method to the constructor of the object.

We can make a manual attempt at this first:

{% codeblock lang:c++ %}
#include <boost/smart_ptr.hpp>

template<typename T>
struct Factory
{
   typedef T Type;
   typedef boost::shared_ptr<T> Pointer;

   Pointer create(void) const
   {
      return Pointer(new Type());
   }

   template<typename A0>
   Pointer create(A0 a0) const
   {
      return Pointer(new Type(a0));
   }

   template<typename A0,
            typename A1>
   Pointer create(A0 a0,
                  A1 a1) const
   {
      return Pointer(new Type(a0,
                              a1));
   }
};
{% endcodeblock %}  
    
You can see how this gets repetitive for constructors with many parameters. Likewise, you should also be able to see the pattern. Patterns mean we can let the machine do the work for us!

Before that, lets test what we have so far:

{% codeblock lang:c++ %}
#include <boost/smart_ptr.hpp>

template<typename T>
struct Factory
{
   typedef T Type;
   typedef boost::shared_ptr<T> Pointer;

   Pointer create(void) const
   {
      return Pointer(new Type());
   }

   template<typename A0>
   Pointer create(A0 a0) const
   {
      return Pointer(new Type(a0));
   }

   template<typename A0,
            typename A1>
   Pointer create(A0 a0,
                  A1 a1) const
   {
      return Pointer(new Type(a0,
                              a1));
   }
};

// Default constructor
struct A
{
   A(void)
   {
      std::cout << "A Constructor" << std::endl;
   }
};

typedef boost::shared_ptr<A> APtr;

// Non-default constructor
struct B
{
   B(int const& v) :
      _value(v)
   {
      std::cout << "B Constructor: " << _value << std::endl;
   }

   int value(void) const
   {
      return _value;
   }

protected:
   int const& _value;
};

typedef boost::shared_ptr<B> BPtr;

int main(int argc, char* argv[])
{
   int value = 3;

   Factory<A> factory_a;
   Factory<B> factory_b;

   APtr a_ptr = factory_a.create();
   BPtr b_ptr = factory_b.create(value);

   std::cout << b_ptr->value() << std::endl;

   value = 5;

   std::cout << b_ptr->value() << std::endl;
}
{% endcodeblock %}  

This outputs:

    A Constructor
    B Constructor: 3
    3
    0

Notice how the reference to `value` wasn't maintained. Boost addresses this issue in the [Boost::Move](http://www.boost.org/doc/libs/1_58_0/doc/html/move/construct_forwarding.html) library by using `BOOST_FWD_REF` and `boost::forward`. Lets incorporate these utilities:

{% codeblock lang:c++ %}
#include <boost/smart_ptr.hpp>
#include <boost/move/utility.hpp>

template<typename T>
struct Factory
{
   typedef T Type;
   typedef boost::shared_ptr<T> Pointer;

   Pointer create(void) const
   {
      return Pointer(new Type());
   }

   template<typename A0>
   Pointer create(BOOST_FWD_REF(A0) a0) const
   {
      return Pointer(new Type(boost::forward<A0>(a0)));
   }

   template<typename A0,
            typename A1>
   Pointer create(BOOST_FWD_REF(A0) a0,
                  BOOST_FWD_REF(A1) a1) const
   {
      return Pointer(new Type(boost::forward<A0>(a0),
                              boost::forward<A1>(a1)));
   }
};

{% endcodeblock %}  

Now we get the output:

    A Constructor
    B Constructor: 3
    3
    5

Thats better! Now that we know our code works, we can start to condense the pattern and let the preprocessor expand it out for us.

[Boost::Preprocessor](http://www.boost.org/doc/libs/1_58_0/libs/preprocessor/doc/index.html) is a handy library that makes interacting with the preprocessor much easier. It introduces a bunch of macros and conventions that we can build upon to emulate features like variadic templates. And despite how it sounds, the final result is rather compact and readable.

First, lets identify the patterns we want to condense. The first is the template parameter list:

    template<typename A0, typename A1>
    
Boost has a macro specifically designed for this purpose: `BOOST_PP_ENUM_PARAMS`. It takes in a number and some text, and replicates the text by appending increasing numbers. For example:

    #include <boost/preprocessor.hpp>
    BOOST_PP_ENUM_PARAMS(3, typename A)
    
Outputs (using the preprocessor `cpp main.cpp`):

    typename A0 , typename A1 , typename A2

Simply wrap the template brackets around this to achieve our first piece:

    #include <boost/preprocessor.hpp>
    template<BOOST_PP_ENUM_PARAMS(3, typename A)>
    
Outputs:

    template< typename A0 , typename A1 , typename A2>
    
Remember that C++ does not care about whitespace. The preprocessor macros will tend to insert whitespace in odd places. Likewise, the preprocessor will output everything on one line without line breaks.

The second pattern we see is the function parameters:

    BOOST_FWD_REF(A0) a0, BOOST_FWD_REF(A1) a1
    
This one is slightly trickier, because it doesn't fit the above enumeration pattern. For this case, we will use a different macro: `BOOST_PP_REPEAT`. This macro operates by convention; it will repeat a specified macro N times as long as that macro takes arguments in a certain way. In addition, we will use `BOOST_PP_CAT` to concatenate strings together. By treating N as one of the strings, we can create an enumeration with the freedom of controlling the output format.

    #include <boost/preprocessor.hpp>
    #define PARAMETERS(Z, N, D) BOOST_PP_CAT(A,N) BOOST_PP_CAT(a,N)
    BOOST_PP_REPEAT(3, PARAMETERS, ~)
    
Outputs:

    A0 a0 A1 a1 A2 a2
    
What is going on here? The `(Z, N, D)` represents state, number, and data, respectively. Boost uses this convention to pass around the "state" of the macro (analogous to how the `this` pointer is the implicit first parameter to any method call), the iteration value, and any extraneous data. For our case, we don't need to pass any data into the macro, so we use the conventional placeholder `~` to denote "void".  On each call of our defined macro, `N` is updated with the iteration count, and we can concatenate that to the letters `A` and `a` to form our type and value.

But what about the commas? Boost has us covered here as well with `BOOST_PP_COMMA`:
    
    #include <boost/preprocessor.hpp>
    #define PARAMETERS(Z, N, D) BOOST_PP_CAT(A,N) BOOST_PP_CAT(a,N) BOOST_PP_COMMA()
    BOOST_PP_REPEAT(3, PARAMETERS, ~)
    
Outputs:

    A0 a0 , A1 a1 , A2 a2 ,
    
Hmm, not quite. There is a trailing comma that we need to get rid of. I'll admit that at this point I was pretty confused, until I learned the trick; Boost also provides `BOOST_PP_COMMA_IF`, which takes a condition argument and will only expand to a comma if the condition is not 0.

Here is the trick: Instead of trying to eliminate the trailing comma, *prepend* the comma!

    #include <boost/preprocessor.hpp>
    #define PARAMETERS(Z, N, D) BOOST_PP_COMMA_IF(N) BOOST_PP_CAT(A,N) BOOST_PP_CAT(a,N)
    BOOST_PP_REPEAT(3, PARAMETERS, ~)
    
Outputs:

    A0 a0 , A1 a1 , A2 a2
    
Perfect!

The final pattern is very similar to the second one:

    #include <boost/preprocessor.hpp>
    #define FORWARD(Z, N, D) BOOST_PP_COMMA_IF(N) boost::forward<BOOST_PP_CAT(A,N)>(BOOST_PP_CAT(a,N))
    BOOST_PP_REPEAT(3, FORWARD, ~)

Outputs:

    boost::forward<A0>(a0) , boost::forward<A1>(a1) , boost::forward<A2>(a2)
    
Armed with these tools, we can now simplify the factory:

{% codeblock lang:c++ %}
template<typename T>
struct Factory
{
   typedef T Type;
   typedef boost::shared_ptr<T> Pointer;

   Pointer create(void) const
   {
      return Pointer(new Type());
   }

   /////////////////////////////////////////////////////////////////////////////
   #define NUM_PARAMETERS 3
   #define PARAMETERS(Z, N, D) BOOST_PP_COMMA_IF(N) BOOST_FWD_REF( BOOST_PP_CAT(A,N)) BOOST_PP_CAT(a,N)
   #define FORWARD(Z, N, D)    BOOST_PP_COMMA_IF(N) boost::forward<BOOST_PP_CAT(A,N)>(BOOST_PP_CAT(a,N))
	
   #define EXPAND(N)                                            \
   template<BOOST_PP_ENUM_PARAMS(N, typename A)>                \
   Pointer create(BOOST_PP_REPEAT(N, PARAMETERS, ~)) const      \
   {                                                            \
      return Pointer(new Type(BOOST_PP_REPEAT(N, FORWARD, ~))); \
   }                                                            \
   
   #undef EXPAND
   #undef FORWARD
   #undef PARAMETERS
   #undef NUM_PARAMETERS
   /////////////////////////////////////////////////////////////////////////////
};
{% endcodeblock %}  
    
It is always a good idea to undefine any macros you define after you are finished with them, since macros pollute the global namespace and you never know how they will interact with complex baselines.

There is one thing left to do; expand out the macro. Unsurprisingly, Boost also provides a way to do this. This method involves setting up a loop and iteratively calling `#include` on the result, which will cause the preprocessor to literally paste the results inline with the code:

{% codeblock lang:c++ %}
template<typename T>
struct Factory
{
   typedef T Type;
   typedef boost::shared_ptr<T> Pointer;

   Pointer create(void) const
   {
      return Pointer(new Type());
   }

   /////////////////////////////////////////////////////////////////////////////
   #define NUM_PARAMETERS 3
   #define PARAMETERS(Z, N, D) BOOST_PP_COMMA_IF(N) BOOST_FWD_REF( BOOST_PP_CAT(A,N)) BOOST_PP_CAT(a,N)
   #define FORWARD(Z, N, D)    BOOST_PP_COMMA_IF(N) boost::forward<BOOST_PP_CAT(A,N)>(BOOST_PP_CAT(a,N))
	
   #define EXPAND(N)                                            \
   template<BOOST_PP_ENUM_PARAMS(N, typename A)>                \
   Pointer create(BOOST_PP_REPEAT(N, PARAMETERS, ~)) const      \
   {                                                            \
      return Pointer(new Type(BOOST_PP_REPEAT(N, FORWARD, ~))); \
   }                                                            \
   
   #define  BOOST_PP_LOCAL_MACRO(N) EXPAND(N)
   #define  BOOST_PP_LOCAL_LIMITS   (1, NUM_PARAMETERS)
   #include BOOST_PP_LOCAL_ITERATE()
	
   #undef BOOST_PP_LOCAL_MACRO
   #undef BOOST_PP_LOCAL_LIMITS
   #undef EXPAND
   #undef FORWARD
   #undef PARAMETERS
   #undef NUM_PARAMETERS
   /////////////////////////////////////////////////////////////////////////////
};
{% endcodeblock %}  
    
Notice that the loop iterates from 1 to N, instead of starting at 0. This is because putting 0 in the template parameter expansion will result in `template<>`, and the compiler will interpret this as template specialization. To get around this, the "base case" for a default constructor is coded outside of the macro.

The preprocessor generates the following code:

{% codeblock lang:c++ %}
template<typename T>
struct Factory
{
   typedef T Type;
   typedef boost::shared_ptr<T> Pointer;

   Pointer create(void) const
   {
      return Pointer(new Type());
   }

   template< typename A0> Pointer create( const A0 & a0) const { return Pointer(new Type( boost::forward<A0>(a0))); }

   template< typename A0 , typename A1> Pointer create( const A0 & a0 , const A1 & a1) const { return Pointer(new Type( boost::forward<A0>(a0) , boost::forward<A1>(a1))); }

   template< typename A0 , typename A1 , typename A2> Pointer create( const A0 & a0 , const A1 & a1 , const A2 & a2) const { return Pointer(new Type( boost::forward<A0>(a0) , boost::forward<A1>(a1) , boost::forward<A2>(a2))); }
};
{% endcodeblock %}  
    
The final step is to increase `NUM_PARAMETERS` to 10 (or whatever max number you want to support).

The preprocessor is often disregarded in coding standards, however it is a powerful feature of C++ that should not be ignored.