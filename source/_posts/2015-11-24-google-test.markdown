---
layout: post
title: "Google Test"
date: 2015-11-24 16:10:22 -0500
comments: true
categories: 
---

This post is a quick introduction to Google Test and how to use it to test your C++ code. Google Test is a unit testing framework that is easy to use and creates meaningful tests with intuitive output.

### Installing

On Debian based systems, you will want to install the following packages:

 - libgtest-dev
 - build-essential
 - cmake

Note that `libgtest-dev` includes the headers and sources, but not the compiled libraries. Follow the instructions below to compile and install the libraries[^1]:

    cd /tmp
    mkdir build
    cd build
    cmake -DCMAKE_BUILD_TYPE=RELEASE /usr/src/gtest/
    make
    sudo mv libgtest* /usr/lib/
    
You could also use `checkinstall` to create a deb package containing the library files.

### Using

To get started, you will need to:

 1. Include the Google Test headers
 2. Write a `TEST` section
 3. Initiate the unit tests from `main()`
 
Tests are composed of various `EXPECT_*` statements to ensure that functions return expected values, etc. For a full description of the various types of tests that can be written using Google Test, refer to the documents below:

 - [Primer](https://github.com/google/googletest/blob/master/googletest/docs/V1_7_Primer.md)
 - [FAQ](https://github.com/google/googletest/blob/master/googletest/docs/V1_7_FAQ.md)
 - [Advanced Guide](https://github.com/google/googletest/blob/master/googletest/docs/V1_7_AdvancedGuide.md)
 - [Google Mock](https://github.com/google/googletest/blob/master/googlemock/docs/ForDummies.md)
 
{% codeblock lang:c++ %}

#include <gtest/gtest.h>

TEST(TestGroup, TestCase)
{
	EXPECT_EQ(2, 1+1);
}

int main(int argc, char* argv[])
{
	::testing::InitGoogleTest(&argc, argv);
	return RUN_ALL_TESTS();
}

{% endcodeblock %}

One thing to remember with the `EXPECT_*` statements is that the *first* argument is the hardcoded expected value (ie: the "truth"), and the `second` parameter is the variable or function call to be tested.

To compile, you need to link against both the compiled gtest library as well as pthread:

    g++ -g -O0 main.cpp -lgtest -pthread

The output will look something like this:

{% codeblock lang:c++ %}

[==========] Running 1 test from 1 test case.
[----------] Global test environment set-up.
[----------] 1 test from TestGroup
[ RUN      ] TestGroup.TestCase
[       OK ] TestGroup.TestCase (0 ms)
[----------] 1 test from TestGroup (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test case ran. (0 ms total)
[  PASSED  ] 1 test.

{% endcodeblock %}

Google Test is a great way to ensure that your code is working properly. I often use Google Test with a relaxed form of *Test Driven Development*[^2].
    
[^1]: [Why no library files installed for google test?](http://askubuntu.com/questions/145887/why-no-library-files-installed-for-google-test) - Wojciech Migda 
[^2]: [Test Driven Development](https://en.wikipedia.org/wiki/Test-driven_development)
