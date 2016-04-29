---
layout: post
title: "Yaml De/Serialization with Boost Fusion"
date: 2015-08-17 20:17:35 -0400
comments: true
toc: true
categories: 
 - C++
 - Template Metaprogramming
 - Boost Fusion
---

In a [previous post]() I did a rather lengthy walkthrough of how to create a Json pretty printer for any object using Boost Fusion. This time I will be doing the same thing, only with Yaml. 

This method relies on a third party library[^1], but the end result is much cleaner. This method supports both serialization and deserialization. As a bonus, it can also work with Json!

{% more %}

To run the following code, you will need these libraries installed:

 - libboost-all-dev
 - libyaml-cpp-dev

I am using yaml-cpp version 0.5.1, and some internals are exposed. There is a possibility that this method would not work with a future version.

The first part is similar to before; creating some wrappers around the Boost Fusion / MPL calls for ease of use. Hopefully the comments and names are straightforward:

{% codeblock lang:c++ %}

template<typename S>
struct sequence
{
    // Point to the first element
    typedef boost::mpl::int_<0> begin;
    
    // Point to the element after the last element in the sequence
    typedef typename boost::fusion::result_of::size<S>::type end;
    
    // Point to the first element
    typedef boost::mpl::int_<0> first;
    
    // Point to the second element (for pairs)
    typedef boost::mpl::int_<1> second;
    
    // Point to the last element in the sequence
    typedef typename boost::mpl::prior<end>::type last;
    
    // Number of elements in the sequence
    typedef typename boost::fusion::result_of::size<S>::type size;
    
    // Get a range representing the size of the structure
    typedef boost::mpl::range_c<unsigned int, 0, boost::mpl::size<S>::value> indices;
};

template<typename S,
         typename N>
struct element_at
{
    // Type of the element at this index
    typedef typename boost::fusion::result_of::value_at<S, N>::type type;
    
    // Previous element
    typedef typename boost::mpl::prior<N>::type previous;
    
    // Next element
    typedef typename boost::mpl::next<N>::type next;
    
    // Member name of the element at this index
    static inline std::string name(void)
    {
        return boost::fusion::extension::struct_member_name<S, N::value>::call();
    }
    
    // Type name of the element at this index
    static inline std::string type_name(void)
    {
        return boost::units::detail::demangle(typeid(type).name());
    }
    
    // Access the element
    static inline typename boost::fusion::result_of::at<S const, N>::type get(S const& s)
    {
        return boost::fusion::at<N>(s);
    }
};

template<typename T>
struct type
{
    // Return the string name of the type
    static inline std::string name(void)
    {
        return boost::units::detail::demangle(typeid(T).name());
    }
};

{% endcodeblock %}

We need two functors:

 - One to insert items into a Yaml node
 - One to extract items from a Yaml node

# Inserter

The constructor will take in a Yaml node to insert into, and `operator()` will take in a Zip element. A Zip element is a tuple created by boost::fusion::for_each that is used to zip together two lists. The concept is the same as in Python:

``` python

> a = [1, 2, 3]

> b = [4, 5, 6]

> zip(a, b)
[(1, 4), (2, 5), (3, 6)]

```

The code performs the following operations:

 1. Grabs the index from the zip
 2. Gets the name of that field using reflection
 3. Gets the type of that field
 4. Aliases the member for convenience
 5. Stores the member under its name in the Yaml node

{% codeblock lang:c++ mark:29 %}

template<typename T>
struct inserter
{
   typedef T Type;

   inserter(YAML::Node& subroot) :
      mSubroot(subroot)
   {}

   template<typename Zip>
   void operator()(Zip const& zip) const
   {
      typedef typename boost::remove_const<
                 typename boost::remove_reference<
                    typename boost::fusion::result_of::at_c<Zip, 0>::type
                 >::type
              >::type Index;

      // Get the field name as a string using reflection
      std::string field_name = element_at<Type, Index>::name();

      // Get the field type
      typedef BOOST_TYPEOF(boost::fusion::at_c<1>(zip)) FieldType;

      // Alias the member
      FieldType const& member = boost::fusion::at_c<1>(zip);

      // Store this field in the yaml node
      mSubroot[field_name] = member;
   }

protected:
   YAML::Node& mSubroot;
};

{% endcodeblock %}

# Extractor

The extractor is the same concept, but it is slightly more difficult for three reasons:

 1. Parsing a file can fail, and `yaml-cpp` is not very good at reporting useful errors.
 2. `boost::fusion::for_each` requires the zip and `operator()` to be const.
 3. `boost::fusion::for_each` requires `operator()` to return void.
 
To solve these issues, we use the reflection capabilities to identify the field we are trying to load, and can report that on failure. Maintaining an item count also provides useful information for the error reporting. Using `const_cast` gets around the const requirements in an ugly manner. Finally, instead of returning `false` on error, we throw an exception that needs to be caught later.

{% codeblock lang:c++ mark:44 %}

template<typename T>
struct extractor
{
   typedef T Type;
  
   extractor(YAML::Node& subroot) :
      mSubroot(subroot),
      mItem(0)
   {
  
   }

   template<typename Zip>
   void operator()(Zip const& zip) const
   {
      typedef typename boost::remove_const<
                 typename boost::remove_reference<
                    typename boost::fusion::result_of::at_c<Zip, 0>::type
                 >::type
              >::type Index;

      // Get the field name as a string using reflection
      std::string field_name = element_at<Type, Index>::name();

      // Get the field native type
      typedef BOOST_TYPEOF(boost::fusion::at_c<1>(zip)) FieldType;

      // Alias the member
      // We need to const cast this because "boost::fusion::for_each"
      // requires that zip be const, however we want to modify it.
      FieldType const& const_member = boost::fusion::at_c<1>(zip);
      FieldType& member = const_cast<FieldType&>(const_member);

      // We need to const cast this because "boost::fusion::for_each"
      // requires that operator() be const, however we want to modify
      // the object. This item number is used for error reporting.
      int const& const_item = mItem;
      int& item = const_cast<int&>(const_item);

      // Try to load the value from the file
      try
      {
         // Extract this field from the yaml node
         member = mSubroot[field_name].as<FieldType>();

         // This item number helps us find issues when loading incomplete yaml files
         ++item;
      }
      // Catch any exceptions
      catch(YAML::Exception const& e)
      {
         // Print out some helpful information to find the error in the yaml file
         std::string type_name = type<FieldType>::name();
         std::cout << "Error loading item " << item  << " : " << type_name << " " << field_name << std::endl;

         // "boost::fusion::for_each" requires operator() to return void,
         // so the only way to signal that an error occurred is to throw
         // an exception.
         throw;
      }
   }

protected:
   YAML::Node& mSubroot;
   int mItem;
};

{% endcodeblock %}

Pay attention to the highlighted lines in the above `inserter` and `extractor`.  
The call to `operator=` in the inserter leads to this code being run inside the `yaml-cpp` library:

{% codeblock lang:c++ "yaml-cpp/node/impl.h" start:203 mark:208 %}

template<typename T>
inline void Node::Assign(const T& rhs)
{
    if(!m_isValid)
        throw InvalidNode();
    AssignData(convert<T>::encode(rhs));
}

{% endcodeblock %}

The call to `as` in the extractor leads to this code being run inside the `yaml-cpp` library:

{% codeblock lang:c++ "yaml-cpp/node/impl.h" start:109 mark:120 %}

// template helpers
template<typename T, typename S>
struct as_if {
    explicit as_if(const Node& node_): node(node_) {}
    const Node& node;
        
    const T operator()(const S& fallback) const {
        if(!node.m_pNode)
            return fallback;
            
        T t;
        if(convert<T>::decode(node, t))
            return t;
        return fallback;
    }
};

{% endcodeblock %}

The documentation states that user specified data types can specialize the `YAML::convert<>` class to handle encoding and decoding properly. Below is a screenshot of the documentation about this:

{% img ./01.png Yaml-cpp Documentation %}

However, there is a small obstacle when trying to specialize the `convert` structure for our fusion sequence:

{% codeblock lang:c++ mark:4 %}

namespace YAML
{
   template<>
   struct convert<???>
   {
      static Node encode(T const& rhs)
      {
         
      }
      
      static bool decode(Node const& node, T& rhs)
      {
         
      }
   }
}

{% endcodeblock %}

We can't specialize in a general sense because `???` would either have to be a template parameter, or we would need one of these for every `BOOST_FUSION_ADAPT_STRUCT` we create. 
Normally in this type of situation, we could use partial specialization if there was a second template parameter, even if it was a dummy variable that allowed us to use `boost::enable_if`.

Digging around the source a little more, we find this gem, and the answer to our problems:

{% codeblock lang:c++ "yaml-cpp/node/node.h" start:112 %}
template<typename T>
struct convert;
{% endcodeblock %}

Thats right! The convert structure is only forward declared, it is never actually defined! This means *we* can define it to be whatever we want!

Time to use some `boost::enable_if` magic. We add a dummy variable to both `encode` and `decode` that only enable those functions if the template parameter is a `boost::fusion` sequence. This allows the signatures of everything to match. Whenever a type `T` is not specialized by the library, the compiler will try to use our definition, which will only take effect if the type is a sequence. Otherwise, a compiler error will be thrown just as it would have before. In addition, this method still allows one to specialize for their type if they need extra functionality.

{% codeblock lang:c++ %}

namespace YAML
{
   template<typename T>
   struct convert
   {
      // This function will only be available if the template parameter is a boost fusion sequence
      static Node encode(T const& rhs,
                         typename boost::enable_if<typename boost::fusion::traits::is_sequence<T>::type>::type* = 0)
      {

      }

      // This function will only be available if the template parameter is a boost fusion sequence
      static bool decode(Node const& node, T& rhs,
                         typename boost::enable_if<typename boost::fusion::traits::is_sequence<T>::type>::type* = 0)
      {

      }
   };
}

{% endcodeblock %}

For the `encode` method, we iterate over every field in the sequence using the inserter, which will recurse through all the sub-sequences until we hit the "bottom". Every sequence is made up of primitive at some level, so eventually the recursion will stop as specializations of `encode` get called instead of the one we defined.

{% codeblock lang:c++ %}

// This function will only be available if the template parameter is a boost fusion sequence
static Node encode(T const& rhs,
                   typename boost::enable_if<typename boost::fusion::traits::is_sequence<T>::type>::type* = 0)
{
   // For each item in T
   // Call inserter recursively
   // Every sequence is made up of primitives at some level

   // Get a range representing the size of the structure
   typedef typename yaml::detail::sequence<T>::indices indices;

   // Make a root node to insert into
   YAML::Node root;

   // Create an inserter for the root node
   yaml::detail::inserter<T> inserter(root);

   // Insert each member of the structure
   boost::fusion::for_each(boost::fusion::zip(indices(), rhs), inserter);

   return root;
}
      
{% endcodeblock %}

The `decode` method works the same way, using the `extractor`. Remember that the extractor throws on error, so the exception needs to be caught.

{% codeblock lang:c++ %}

// This function will only be available if the template parameter is a boost fusion sequence
static bool decode(Node const& node, T& rhs,
                   typename boost::enable_if<typename boost::fusion::traits::is_sequence<T>::type>::type* = 0)
{
   // For each item in T
   // Call extractor recursively
   // Every sequence is made up of primitives at some level

   // Get a range representing the size of the structure
   typedef typename yaml::detail::sequence<T>::indices indices;

   // Create an extractor for the root node
   // Yaml-cpp requires node to be const&, but the extractor makes
   // non-const calls to it.
   Node& writable_node = const_cast<Node&>(node);
   yaml::detail::extractor<T> extractor(writable_node);
 
   // Extract each member of the structure
   try
   {
      // An exception is thrown if any item in the loop cannot be read
      boost::fusion::for_each(boost::fusion::zip(indices(), rhs), extractor);
   }
   // Catch all exceptions and prevent them from propagating
   catch(...)
   {
      return false;
   }

   // If we made it here, all fields were read correctly
   return true;
}

{% endcodeblock %}

# Mixin

Ok! All the pieces and parts are completed. Time to make a mixin to wrap it all up. We want objects to have method to convert to and from Yaml and Json (remember that Json is a subset of Yaml, so the yaml parser gives us both abilities for free!). All we need to do is kickstart the recursion using the `inserter` and `extractor`.

{% codeblock lang:c++ %}

namespace yaml
{
   template<typename T>
   class Yaml
   {
   public:

      typedef T Base;

      // Convert this object to yaml
      std::string to_yaml(void)
      {
         // Create an emitter
         YAML::Emitter emitter;

         // Emit yaml
         return emit(emitter);
      }

      // Convert this object to json
      std::string to_json(void)
      {
         // Create an emitter
         YAML::Emitter emitter;

         // Set the emitter manipulators for json
         emitter << YAML::Flow;
         emitter << YAML::DoubleQuoted;
         emitter << YAML::TrueFalseBool;
         emitter << YAML::EscapeNonAscii;

         // Emit json
         return emit(emitter);
      }

      // Load yaml into this object
      bool from_yaml(std::string const& yaml_string)
      {
         // Create a root node to load into
         YAML::Node root;

         try
         {
            // Try loading the root node
            root = YAML::Load(yaml_string);
         }
         catch(...)
         {
            // The yaml couldn't be parsed
            std::cout << "Invalid yaml" << std::endl;
            return false;
         }

         // Get a range representing the size of the structure
         typedef typename detail::sequence<Base>::indices indices;

         // Create an extractor for the root node
         detail::extractor<Base> extractor(root);

         // Extract each member of the structure
         try
         {
            // An exception is thrown if any item in the loop cannot be read
            boost::fusion::for_each(boost::fusion::zip(indices(), self()), extractor);
         }
         // Catch all exceptions and prevent them from propagating
         catch(...)
         {
            return false;
         }

         // If we made it here, all fields were read correctly
         return true;
      }

      // The yaml parser can also parse json
      inline bool from_json(std::string const& json_string)
      {
         return from_yaml(json_string);
      }

   protected:

      std::string emit(YAML::Emitter& emitter)
      {
         // Get a range representing the size of the structure
         typedef typename detail::sequence<Base>::indices indices;

         // Make a root node to insert into
         YAML::Node root;

         // Create an inserter for the root node
         detail::inserter<Base> inserter(root);

         // Insert each member of the structure
         boost::fusion::for_each(boost::fusion::zip(indices(), self()), inserter);

         // Emit yaml
         emitter << root;

         // Return string representation
         return emitter.c_str();
      }

   private:

      // Cast ourselves to our CRTP base
      Base& self(void)
      {
         return static_cast<Base&>(*this);
      }
   };
}

{% endcodeblock %}

# Testing

Time to test it. First we create some test structures with different types and containers, and adapt them into sequences:

{% codeblock lang:c++ mark:13,15,30-31,34 %}

#include <string>
#include <sstream>
#include <map>
#include <vector>
#include <iostream>

using namespace yaml;

namespace test
{
   struct One
   {
      friend boost::fusion::extension::access;

      One(void) :
         two(0),
         three(0.0),
         four(false)
      {}

      One(int a, double b, bool c) :
         two(a),
         three(b),
         four(c)
      {}

      int two;
      double three;

   private:
      bool four;
   };

   struct Five : public Yaml<Five>
   {
      typedef std::map<int, One> Map_t;
      Map_t six;

      typedef std::vector<One> Vector_t;
      Vector_t seven;

      std::string eight;

      typedef std::vector<std::vector<double> > Matrix_t;
      Matrix_t nine;
   };
}

BOOST_FUSION_ADAPT_STRUCT
(
   test::One,
   (int, two)
   (double, three)
   (bool, four)
)

BOOST_FUSION_ADAPT_STRUCT
(
   test::Five,
   (test::Five::Map_t, six)
   (test::Five::Vector_t, seven)
   (std::string, eight)
   (test::Five::Matrix_t, nine)
)

{% endcodeblock %}

A couple things to note here. First off, a default constructor is required for decoding. Secondly, if you want to adapt private or protected members, your class must befriend the `boost::fusion::extension::access` class. Finally, the top-level structure that you want to serialize / deserialize must inherit from the `Yaml<>` mixin.

To try it out, populate the structure and output it as Yaml and Json. Then try parsing a different Yaml string and make sure the structure was populated accordingly:

{% codeblock lang:c++ %}

using namespace test;

int main(int argc, char* argv[])
{
   Five v;
   v.six.insert(std::make_pair(123, One(3, 6.6, true)));
   v.six.insert(std::make_pair(456, One(4, 8.8, false)));

   v.seven.push_back(One(5, 1.1, true));
   v.seven.push_back(One(5, 2.2, true));

   v.eight = "eight";

   std::vector<double> temp;
   temp.push_back(2.3);
   temp.push_back(4.5);

   v.nine.push_back(temp);
   v.nine.push_back(temp);

   std::cout << v.to_yaml() << std::endl;
   std::cout << v.to_json() << std::endl;

   ///////////////////////////////////////////
   std::cout << "==============" << std::endl;

   std::stringstream ss;

   ss << "six:            \n"
      << "  234:          \n"
      << "    two: 4      \n"
      << "    three: 5.5  \n"
      << "    four: true  \n"
      << "  345:          \n"
      << "    two: 6      \n"
      << "    three: 7.7  \n"
      << "    four: false \n"
      << "seven:          \n"
      << "  - two: 8      \n"
      << "    three: 9.9  \n"
      << "    four: true  \n"
      << "  - two: 2      \n"
      << "    three: 3.3  \n"
      << "    four: true  \n"
      << "eight: nine     \n"
      << "nine:           \n"
      << "  -             \n"
      << "    - 3.4       \n"
      << "    - 5.6       \n"
      << "  -             \n"
      << "    - 7.8       \n"
      << "    - 9.0       \n";

   v.from_yaml(ss.str());
   std::cout << v.to_yaml() << std::endl;
}

{% endcodeblock %}

The output is:

{% codeblock lang:python %}
six:
  123:
    two: 3
    three: 6.6
    four: true
  456:
    two: 4
    three: 8.800000000000001
    four: false
seven:
  - two: 5
    three: 1.1
    four: true
  - two: 5
    three: 2.2
    four: true
eight: eight
nine:
  -
    - 2.3
    - 4.5
  -
    - 2.3
    - 4.5
{"six": {"456": {"two": "4", "three": "8.800000000000001", "four": "false"}, "123": {"three": "6.6", "four": "true", "two": "3"}}, "seven": [{"two": "5", "three": "1.1", "four": "true"}, {"two": "5", "three": "2.2", "four": "true"}], "eight": "eight", "nine": [["2.3", "4.5"], ["2.3", "4.5"]]}
==============
eight: nine
six:
  234:
    three: 5.5
    four: true
    two: 4
  345:
    two: 6
    three: 7.7
    four: false
seven:
  - three: 9.9
    two: 8
    four: true
  - three: 3.3
    two: 2
    four: true
nine:
  -
    - 3.4
    - 5.6
  -
    - 7.8
    - 9

{% endcodeblock %}

[^1]: [Yaml-cpp](https://github.com/jbeder/yaml-cpp) - Jesse Beder
