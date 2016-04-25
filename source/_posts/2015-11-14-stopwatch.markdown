---
layout: post
title: "Stopwatch"
date: 2015-11-14 11:37:52 -0500
comments: true
categories: 
 - C++
---

Object counters and memory pools are great ways to monitor the memory usage of your program from within. 
It can also be useful to monitor the amount of time being spent executing from within your program. 
This post presents a stopwatch that can provide statistics on how long something takes to run.

{% more %}

This project will require the following libraries to compile:

 - libboost-chrono-dev
 - libboost-thread-dev
 - libboost-system-dev

The idea with the stopwatch is to provide simple `start` and `stop` methods to monitor execution time, and store statistics that can be programatically accessed. Two stopwatch types will be presented: a static stopwatch and an instantiatable stopwatch. Each has its uses, with advantages and disadvantages:

 - Static stopwatches can be differentiated using tags, and can be accessed anywhere
 - Object stopwatches can be managed at runtime, but must be passed around to be effective

First, we must define the statistics that will be managed:

{% codeblock lang:c++ %}
struct Statistics
{
public:
   typedef unsigned long long Count;

   Count  last;    // Last measured difference
   Count  min;     // Minimum measured difference
   Count  max;     // Maximum measured difference
   Count  samples; // Number of samples taken
   Count  total;   // Total measured difference
   double average; // Average measured difference
   Count  mark;    // Time when started
   bool   running; // Flag indicating that the stopwatch is running
   bool   cleared; // Flag indicating that the stopwatch is cleared

   Statistics(void) :
      last(0),
      min(0),
      max(0),
      samples(0),
      total(0),
      average(0.0),
      mark(0),
      running(false),
      cleared(true)
   {}

   friend std::ostream& operator<<(std::ostream& os, Statistics const& stats)
   {
      os << " - Last    : " << stats.last    << "\n"
         << " - Min     : " << stats.min     << "\n"
         << " - Max     : " << stats.max     << "\n"
         << " - Average : " << stats.average << "\n"
         << " - Total   : " << stats.total   << "\n"
         << " - Samples : " << stats.samples;

      return os;
   }
};
{% endcodeblock %}

Next, we need the actual implementation to track those statistics. It will provide `start`, `stop`, and `reset`, and will utilize a clock to get the timestamps to measure. Both the static and object types will utilize this implementation:

{% codeblock lang:c++ %}
template<typename ClockT>
class StopwatchImplementation
{
protected:

   typedef ClockT Clock;
   typedef unsigned long long Count;

   static void _start(Statistics& stats)
   {
      stats.mark = _clock(); // Get the current time
      stats.running = true;  // Stopwatch is now running
   }

   static void _stop(Statistics& stats)
   {
      // Only update the statistics if the stopwatch was running
      if(stats.running)
      {
         // No longer running
         stats.running = false;

         // Grab the current time
         Count now = _clock();

         // Calculate the difference while avoiding overflow
         stats.last = now > stats.mark
                      ? now - stats.mark
                      : stats.mark - now;

         // Keep track of the total and samples
         stats.total += stats.last;
         ++stats.samples;

         // Do not take a min from a cleared state, or it will be zero
         stats.min = stats.cleared
                     ? stats.last
                     : std::min(stats.min, stats.last);

         // Get the max
         stats.max = std::max(stats.max, stats.last);

         // Calculate the average
         stats.average = static_cast<double>(stats.total) /
                         static_cast<double>(stats.samples);

         // No longer cleared
         stats.cleared = false;
      }
   }

   static void _reset(Statistics& stats)
   {
      stats.last    = 0;
      stats.min     = 0;
      stats.max     = 0;
      stats.samples = 0;
      stats.total   = 0;
      stats.average = 0.0;
      stats.mark    = 0;
      stats.running = false;
      stats.cleared = true;
   }

   static void _print(std::string const& name,
                      Statistics const& stats,
                      std::ostream& os)
   {
      os << name << ":\n" << stats << std::endl;
   }

   static Clock _clock;
};
{% endcodeblock %}

You will notice that the clock has been completely abstracted away from the stopwatch implementation, allowing any functor to be plugged in. By default, we will use `boost::chrono::high_resolution_clock` with configurable units. Here is the clock implementation:

{% codeblock lang:c++ %}
template<typename Resolution>
class Clock
{
public:
   typedef unsigned long long Count;

   Clock(void) :
      // Initialize the reference to creation time
      _duration_reference(boost::chrono::high_resolution_clock::now())
   {}

   Count operator()(void) const
   {
      // Return the difference between now and the reference in the resolution units
      return static_cast<Count>(boost::chrono::duration_cast<Resolution>(boost::chrono::high_resolution_clock::now() - _duration_reference).count());
   }

protected:
   boost::chrono::high_resolution_clock::time_point _duration_reference;
};
{% endcodeblock %}

There are many different configurations that the clock can use:

{% codeblock lang:c++ %}
typedef detail::Clock<boost::chrono::hours>        HourClock;
typedef detail::Clock<boost::chrono::minutes>      MinuteClock;
typedef detail::Clock<boost::chrono::seconds>      SecondClock;
typedef detail::Clock<boost::chrono::milliseconds> MillisecondClock;
typedef detail::Clock<boost::chrono::microseconds> MicrosecondClock;
typedef detail::Clock<boost::chrono::nanoseconds>  NanosecondClock;
{% endcodeblock %}

Now that we have all the pieces, time to make the static and object stopwatch types. First, the static one. It is a static class with a template parameter that allows static instantiations to be differentiated. All methods are static and forwarded to the base class:

{% codeblock lang:c++ %}
template<typename TagT   = void,             // Specify a tag for "compile-time" instances
         typename ClockT = MicrosecondClock> // Default to the microsecond clock
class Stopwatch : public detail::StopwatchImplementation<ClockT>
{
public:

   typedef TagT   Tag;
   typedef ClockT Clock;
   typedef Stopwatch<Tag, Clock> Self;
   typedef detail::StopwatchImplementation<Clock> Base;
   typedef unsigned long long Count;

   // Forward to the base implementation
   static void start (void){Base::_start (_statistics);}
   static void stop  (void){Base::_stop  (_statistics);}
   static void reset (void){Base::_reset (_statistics);}

   static void print(std::ostream& os = std::cout)
   {
      Base::_print(name(), _statistics, os);
   }

   // Accessors
   static inline Count  last    (void){return _statistics.last;}
   static inline Count  min     (void){return _statistics.min;}
   static inline Count  max     (void){return _statistics.max;}
   static inline Count  samples (void){return _statistics.samples;}
   static inline Count  total   (void){return _statistics.total;}
   static inline double average (void){return _statistics.average;}

protected:

   static detail::Statistics _statistics;

private:

   // Return the name of the tag as a string
   static std::string name(void)
   {
      return boost::units::detail::demangle(typeid(Tag).name());
   }

   // Prevent this class from being instantiated
   Stopwatch(void){}
};
{% endcodeblock %}

Notice how the tag type defaults to `void`. We want to specialize the stopwatch for the void type and allow the specialization to act as the object stopwatch. This allows us to omit the tag type to instantiate an object:

{% codeblock lang:c++ %}
// Specialize on the void tag to allow creating instances
template<typename ClockT = MicrosecondClock>
class Stopwatch<void, ClockT> : public detail::StopwatchImplementation<ClockT>
{
public:

   typedef ClockT                                 Clock;
   typedef Stopwatch<void, Clock>                 Self;
   typedef detail::StopwatchImplementation<Clock> Base;
   typedef unsigned long long                     Count;

   Stopwatch(std::string const& tag) :
      _tag(tag)
   {}

   // Forward to the base implementation
   void start (void) {Base::_start (_statistics);}
   void stop  (void) {Base::_stop  (_statistics);}
   void reset (void) {Base::_reset (_statistics);}

   void print(std::ostream& os = std::cout) const
   {
      Base::_print(_tag, _statistics, os);
   }

   friend std::ostream& operator<<(std::ostream& os, Self const& obj)
   {
      obj.print(os);
      return os;
   }

   // Accessors
   inline Count  last    (void) const {return _statistics.last;}
   inline Count  min     (void) const {return _statistics.min;}
   inline Count  max     (void) const {return _statistics.max;}
   inline Count  samples (void) const {return _statistics.samples;}
   inline Count  total   (void) const {return _statistics.total;}
   inline double average (void) const {return _statistics.average;}

protected:

   // The tag for this object
   std::string _tag;

   // A statistics object specifically for this stopwatch instance
   detail::Statistics _statistics;
};
{% endcodeblock %}

We are all set! Time to test it out:

{% codeblock lang:c++ %}
// Define a tag
struct Static{};

int main(int argc, char* argv[])
{
	using namespace stopwatch;

	typedef Stopwatch<Static, MillisecondClock> static_stopwatch;
	Stopwatch<void, MillisecondClock> object_stopwatch("Object");

	for(int i = 0; i < 100; ++i)
	{
		static_stopwatch::start();
		object_stopwatch.start();

		boost::this_thread::sleep(boost::posix_time::milliseconds(10));

		static_stopwatch::stop();
		object_stopwatch.stop();
	}

	static_stopwatch::print();
	object_stopwatch.print();
}
{% endcodeblock %}

To compile this, run the following command:

    g++ stopwatch.cpp -l boost_chrono -l boost_system -l boost_thread
    
The output I get is:

    Static:
     - Last    : 10
     - Min     : 10
     - Max     : 11
     - Average : 10.19
     - Total   : 1019
     - Samples : 100
    Object:
     - Last    : 10
     - Min     : 10
     - Max     : 11
     - Average : 10.19
     - Total   : 1019
     - Samples : 100

As you can see, both types give the same results.
