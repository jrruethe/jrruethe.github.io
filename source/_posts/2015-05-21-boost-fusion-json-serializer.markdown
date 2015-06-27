---
published: false
layout: post
title: "Boost Fusion Json Serializer"
date: 2015-05-21 19:21:50 -0400
comments: true
categories: 
---

In this post, I am going to walkthrough the creation of a C++ mixin that will allow any structure to serialize itself to Json, using the magical power of Boost::Fusion.

To do this, you will need the following installed:

 - libboost-dev

The Json serializer will support any structure composed of the following:

 - Primitives
 - Arrays
 - Containers
 - Nested Structures

First, we need a test structure that we want to serialize to Json. It needs to include some arrays, containers, and nested structures to test all the abilities of the serializer:

{% codeblock lang:c++ %}

    struct inner
    {
       int a;
       double b;
       bool c;

       typedef std::vector<int> vec_t;
       vec_t d;
    };
    
    struct outer
    {
       int one;
       double two;
       bool three;

       typedef inner array_t[2];
       array_t array;

       typedef std::set<int> set_t;
       set_t s;
       
       typedef std::map<int, int> map_t;
       map_t m;
    };
    
{% endcodeblock %}	

Boost::Fusion is a library that enables reflection in C++ with only a small amount of boilerplate. Pay careful attention to the use of `()` instead of `{}`, and the placement of the `,`:

{% codeblock lang:c++ %}

    BOOST_FUSION_ADAPT_STRUCT
    (
       inner,
       (int, a)
       (double, b)
       (bool, c)
       (inner::vec_t, d)
    )
    
    BOOST_FUSION_ADAPT_STRUCT
    (
       outer,
       (int, one)
       (double, two)
       (bool, three)
       (outer::array_t, array)
       (outer::set_t, s)
       (outer::map_t, m)
    )

{% endcodeblock %}

Next, we define a serializer for each meta-type that needs to be supported. Each serializer will take a reference to an output stream that will be appended to, a type to serialize, and the current recursion depth. The depth is useful for pretty-printing with the proper indentation:

{% codeblock lang:c++ %}

    template<typename T>
    struct primitive_serializer
    {
       typedef primitive_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {

       }
    };
    
    template<typename T>
    struct array_serializer
    {
       typedef array_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {

       }
    };
    
    template<typename T>
    struct container_serializer
    {
       typedef container_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {

       }
    };
    
    template<typename T>
    struct struct_serializer
    {
       typedef struct_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {

       }
    };

{% endcodeblock %}	

The `primitive_serializer` is the simplest one to implement, so lets start with that one. It will enclose the value in quotation marks and append it to the stream:

{% codeblock lang:c++ %}

    template<typename T>
    struct primitive_serializer
    {
       typedef primitive_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {
          os << "\""
             << t
             << "\"";
       }
    };

{% endcodeblock %}	

Next, lets implement the `array_serializer`. We need to get the size of the array, and iterate over it while serializing each element. Notice the use of newlines and tabs, and the increase in the recursion depth; we want the Json output to be pretty, as opposed to compressed (Switching to a compressed version is as simple as removing the newlines, tabs, and whitespace). Finally, we want to insert commas between each element, but we don't want a comma trailing after the final element:

{% codeblock lang:c++ %}

    static inline std::string tab(int depth)
    {
    	std::string retval;
    	for(int i = 0; i < depth; ++i){retval += "   ";}
    	return retval;
    }

    template<typename T>
    struct array_serializer
    {
       typedef array_serializer<T> type;
    
       typedef typename boost::remove_bounds<T>::type slice_t;
    
       static const size_t size = sizeof(T) / sizeof(slice_t);
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {
          os << "\n" + tab(depth) + "[";
    
          for(unsigned int i = 0; i < size; ++i)
          {
             json_serializer<slice_t>::serialize(os, t[i], depth + 1);
    
             if(i != size-1)
             {
                os << ", ";
             }
          }
    
          os << "\n" + tab(depth) + "]";
       }
    };

{% endcodeblock %}	

The container serializer is very similar; we use `BOOST_FOREACH` to do the iteration, and pull the `value_type` out of the container, but everything else is the same:

{% codeblock lang:c++ %}

    template<typename T>
    struct container_serializer
    {
       typedef container_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {
          os << "\n" + tab(depth) + "[";
    
          std::size_t size = t.size();
          std::size_t count = 0;
    
          BOOST_FOREACH(typename T::value_type const& v, t)
          {
             json_serializer<typename T::value_type>::serialize(os, v, depth + 1);
    
             if(count != size - 1)
             {
                os << ", ";
             }
    
             ++count;
          }
    
          os << "\n" + tab(depth) + "]";
       }
    };

{% endcodeblock %}	

The last serializer is the `struct_serializer`. This one is trickier. Structures are adapted as `Boost::Fusion` sequences by the boilerplate we defined above. A sequence is basically a vector, except each element can have a different type. In this case, the type/value pairs correspond directly with the members of the structure, and we can iterate over these members.

It would be fairly straightforward to treat the sequence similar to a container by using `boost::fusion::for_each`, so instead lets keep things interesting and use recursion.

Before we get to the serializer, lets define some wrappers for interacting with the sequences in a friendlier way. We can get properties of the sequence as a whole, or we can get properties of a certain element in the sequence by using it's index. You can even get an element's member name and member type as a string (which is very handy when writing an XML serializer):

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

{% endcodeblock %}	

Next we define the recursive struct serializer. The layout is similar to our other serializers, except this time there are two template parameters: the sequence and the element index.

{% codeblock lang:c++ %}

    template<typename S, typename N>
    struct struct_serializer_recursive
    {
       template<typename Ostream>
       static inline void serialize(Ostream& os, S const& s, int depth)
       {

       }
    };

{% endcodeblock %}	

Using the above sequence helpers, we can obtain the type of the current element, and the index of the next element. We can also get the name of the element being serialized, it's type, and it's value:

{% codeblock lang:c++ %}

    typedef typename element_at<S, N>::type current_t;
    typedef typename element_at<S, N>::next next_t;
    
    std::string name = element_at<S, N>::name();
    
    current_t const& t = element_at<S, N>::get(s);

{% endcodeblock %}	

Structures will be represented as key/value pairs separated by commas. Each value might be an array, container, or nested structure; therefore we need to call the `json_serializer` on each element. The final step is to recurse to the next element of the sequence. So a complete implementation would look like this:

{% codeblock lang:c++ %}

    template<typename S, typename N>
    struct struct_serializer_recursive
    {
       typedef typename element_at<S, N>::type current_t;
       typedef typename element_at<S, N>::next next_t;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, S const& s, int depth)
       {
          std::string name = element_at<S, N>::name();
          current_t const& t = element_at<S, N>::get(s);
          
          os << "\n" + tab(depth) + "\""
             << name
             << "\" : ";
    
          json_serializer<current_t>::serialize(os, t, depth);
    
          os << ", ";
    
          struct_serializer_recursive<S, next_t>::serialize(os, s, depth);
       }
    };

{% endcodeblock %}	

We need to define the base case to stop the recursion. To do this, we use template specialization for the last element of the sequence. Then, we initiate the recursion by calling into the first element of the sequence:

{% codeblock lang:c++ %}

    template<typename S>
    struct struct_serializer_recursive<S, typename sequence<S>::end>
    {
       template<typename Ostream>
       static inline void serialize(Ostream& os, S const& s, int depth)
       {
          // No output
       }
    };
    
    template<typename S>
    struct struct_serializer_initiate : struct_serializer_recursive<S, typename sequence<S>::begin>
    {
    
    };

{% endcodeblock %}	

With the help of these pieces, we can implement the `struct_serializer`:

{% codeblock lang:c++ %}

    template<typename T>
    struct struct_serializer
    {
       typedef struct_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth)
       {
          os << "\n" + tab(depth) + "{";
          struct_serializer_initiate<T>::serialize(os, t, depth + 1);
          os << "\n" + tab(depth) + "}";
       }
    };

{% endcodeblock %}	

Now that all four serializers are implemented, we need a way to determine which one to use. To do this, we will utilize Boost's `type traits` to determine the properties of each type. Boost provides type traits for arrays and classes (which we have adapted into sequences), as well as a hidden one that identifies containers. Anything left over is treated as a primitive. This can be accomplished with some metaprogramming magic and a series of if-then-else statements:

{% codeblock lang:c++ %}

    template<typename T>
    struct choose_serializer
    {
       typedef
       typename boost::mpl::eval_if<boost::is_array<T>,
                                    boost::mpl::identity<array_serializer<T> >,
                                    typename boost::mpl::eval_if<boost::spirit::traits::is_container<T>,
                                                                 boost::mpl::identity<container_serializer<T> >,
                                                                 typename boost::mpl::eval_if<boost::is_class<T>,
                                                                                              boost::mpl::identity<struct_serializer<T> >,
                                                                                              boost::mpl::identity<primitive_serializer<T> >
                                                                                             >
                                                                >
                                   >::type 
       type;
    };

{% endcodeblock %}	

The last piece is to wrap all this code up into a `json_serializer` and utilize it with a mixin. The mixin uses `CRTP` in which a structure inherits from the mixin and passes itself in as the template parameter. The mixin can then cast itself to the class type and begin iterating over itself:

{% codeblock lang:c++ %}

    template<typename T>
    struct json_serializer : public choose_serializer<T>::type
    {
    
    };
    
    template<typename T>
    struct json
    {
       std::string to_json(void)
       {
          std::stringstream ss;
          json_serializer<T>::serialize(ss << std::boolalpha, self(), 0);
          return ss.str();
       }
       
    private:
    
       T const& self(void) const
       {
          return *static_cast<T const*>(this);
       }
       
    };

{% endcodeblock %}	

Time to test it out! Instantiate the structure and populate it. Remember to apply the mixin via inheritance (`struct outer : public json<outer>`):

{% codeblock lang:c++ %}

    int main(int argc, char *argv[])
    {
       outer o;
       o.one = 1;
       o.two = 2.2;
       o.three = false;
    
       o.array[0].a = 3;
       o.array[0].b = 4.4;
       o.array[0].c = true;
       o.array[0].d.push_back(11);
       o.array[0].d.push_back(22);
    
       o.array[1].a = 5;
       o.array[1].b = 6.6;
       o.array[1].c = false;
       o.array[1].d.push_back(33);
       o.array[1].d.push_back(44);
    
       o.s.insert(55);
       o.s.insert(66);
    
       o.m[77] = 88;
       o.m[99] = 111;
    
       std::cout << o.to_json();
    
       std::cout << std::endl;
    }

{% endcodeblock %}	

The resulting Json printed out looks like this:

{% codeblock lang:json %}

    {
       "one" : "1", 
       "two" : "2.2", 
       "three" : "false", 
       "array" : 
       [
          {
             "a" : "3", 
             "b" : "4.4", 
             "c" : "true", 
             "d" : 
             ["11", "22"
             ], 
          }, 
          {
             "a" : "5", 
             "b" : "6.6", 
             "c" : "false", 
             "d" : 
             ["33", "44"
             ], 
          }
       ], 
       "s" : 
       ["55", "66"
       ], 
       "m" : 
       [
          {
             "first" : "77", 
             "second" : "88", 
          }, 
          {
             "first" : "99", 
             "second" : "111", 
          }
       ], 
    }

{% endcodeblock %}	

Close, but not quite. There are multiple issues:

 - Arrays are formatted goofy (lines 12, 20, 25)
 - Trailing commas (lines 21, 37)
 - The map is represented as an array of pairs (lines 29-36)

Fortunately, these issues are easily fixed.

The first issue is caused by the `primitive_serializer` not adding newlines for array values. This can be fixed with an extra boolean parameter that gets set when calling it from the `array_serializer`. You will find that you also want to set this extra parameter to true when calling from the `container_serializer`, since the containers are formatted as arrays. Note that all the serializer signatures need to be updated so they match, as well as each call to the serializer.:

{% codeblock lang:c++ %}

    template<typename T>
    struct primitive_serializer
    {
       typedef primitive_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth, bool array_value)
       {
          if(array_value)
          {
             os << "\n" + tab(depth) + "\""
                << t
                << "\"";
          }
          else
          {
             os << "\""
                << t
                << "\"";
          }
       }
    };

{% endcodeblock %}	

Fixing the second issue (trailing commas) involves a little more template magic. The problem is caused by the comma being added inside `struct_serializer_recursive`. A comma is added just before the recursion hits the base case and stops. Instead, we should conditionally add this comma, but skip that step on the last element. To do this, we outsource the comma-insertion to a functor and specialize it for the last element:

{% codeblock lang:c++ %}

    template<typename S,
             typename N>
    struct separator
    {
        static inline std::string comma()
        {
           return ",";
        }
    };
    
    template<typename S>
    struct separator<S, typename sequence<S>::last>
    {
       static inline std::string comma()
       {
          return "";
       }
    };

{% endcodeblock %}

Now `os << ", ";` can be replaced with `os << separator<S, N>::comma();`.

The third issue is caused by the map container's value_type being a pair. Boost is kind enough to adapt pairs into structures for us, but the output isn't quite the way we want it. Instead, we want `first` to be treated as the key, and `second` to be treated as the value. To fix this, we make a modified copy of `struct_serializer_recursive` for pairs that doesn't access the member name... 

{% codeblock lang:c++ %}

    template<typename S, typename N>
    struct pair_serializer_recursive
    {
       typedef typename element_at<S, N>::type current_t;
       typedef typename element_at<S, N>::next next_t;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, S const& s, int depth, bool array_value, bool pair)
       {
          current_t const& t = element_at<S, N>::get(s);
          
          os << "\n" + tab(depth) + "\""
             << t
             << "\" : ";
    
          pair_serializer_recursive<S, next_t>::serialize(os, s, depth, false, false);
       }
    };
    
    template<typename S>
    struct pair_serializer_recursive<S, typename sequence<S>::second>
    {
       typedef typename element_at<S, typename sequence<S>::second>::type current_t;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, S const& s, int depth, bool array_value, bool pair)
       {
          current_t const& t = element_at<S, typename sequence<S>::second>::get(s);
          
          os << "\""
             << t
             << "\"";
       }
    };
    
    template<typename T>
    struct pair_serializer_initiate : public pair_serializer_recursive<T, typename sequence<T>::begin>
    {
    
    };

{% endcodeblock %}

...specialize the `container_serializer` for `std::map` to change the boolean flags being set on the serializer... 

{% codeblock lang:c++ %}

    template<typename K, typename V, typename C, typename A>
    struct container_serializer<std::map<K, V, C, A> >
    {
       typedef std::map<K, V, C, A> T;
       typedef container_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth, bool array_value, bool pair)
       {
          os << "\n" + tab(depth) + "{";
    
          std::size_t size = t.size();
          std::size_t count = 0;
          
          BOOST_FOREACH(typename T::value_type v, t)
          {
             json_serializer<typename T::value_type>::serialize(os, v, depth + 1, true, true);
    
             if(count != size - 1)
             {
                os << ", ";
             }
    
             ++count;
          }
    
          os << "\n" + tab(depth) + "}";
       }
    };

{% endcodeblock %}

...and conditonally use the `pair_serializer` inside the `struct_serializer`:

{% codeblock lang:c++ %}

    template<typename T>
    struct struct_serializer
    {
       typedef struct_serializer<T> type;
    
       template<typename Ostream>
       static inline void serialize(Ostream& os, T const& t, int depth, bool array_value, bool pair)
       {
          if(pair)
          {
             pair_serializer_initiate<T>::serialize(os, t, depth, false, false);
          }
          else
          {
             os << "\n" + tab(depth) + "{";
             struct_serializer_initiate<T>::serialize(os, t, depth + 1, false, false);
             os << "\n" + tab(depth) + "}";
          }
       }
    };

{% endcodeblock %}

Unfortunately, this means we needed to add another boolean parameter for our serialize function. After all that, we get the following Json output:

{% codeblock lang:json %}

    {
       "one" : "1",
       "two" : "2.2",
       "three" : "false",
       "array" : 
       [
          {
             "a" : "3",
             "b" : "4.4",
             "c" : "true",
             "d" : 
             [
                "11", 
                "22"
             ]
          }, 
          {
             "a" : "5",
             "b" : "6.6",
             "c" : "false",
             "d" : 
             [
                "33", 
                "44"
             ]
          }
       ],
       "s" : 
       [
          "55", 
          "66"
       ],
       "m" : 
       {
          "77" : "88", 
          "99" : "111"
       }
    }

{% endcodeblock %}	

It validates! Below is the final form of the code. While it is quite a bit, the nice thing is that all a user needs to do is perform the fusion adaption of their structure and inherit from the mixin; the rest is hidden behind the scenes.


Hopefully you learned some cool C++ tricks from this.

---
This post was inspired by [Andres Senac](http://andres.senac.es/2011/04/generic-json-serializer.html).