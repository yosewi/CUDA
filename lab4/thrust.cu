// Using Thrust library.
//
// Assume having data:
//
//    day         [  0  0  1  2  5  5  6  6  7  8 ...]
//    site        [  2  3  0  1  1  2  0  1  2  1 ...]
//    measurement [  9  5  6  3  3  8  2  6  5 10 ...]
//
// For 'day' we have 'measurement' of rainfall in given 'site'.
//
//    Time series sorted by day
//    Measurements of zero are excluded from the time series
//
// Tasks:
//
//    Design structures containing the data (remember the difference AoS and SoA)
//    Calculate number of days with any rainfall
//    Calculate total rainfall at each site
//    Get number of days when rainfall exceeded 5
//    Find the first day when total rainfall exceeded 32
//    Return total rainfall between day 2 and 6 (inclusive)
//
// Note:
//     All computation should be done without loops!
//     Loops are allowed only when printing the results in point "Calculate total rainfall at each site"
//
// Documentation:   https://nvidia.github.io/cccl/unstable/thrust/index.html
//
// Compile: nvcc -arch=native --extended-lambda lab4.cu -o lab4

#include <thrust/version.h>
#include <thrust/device_vector.h>
#include <thrust/inner_product.h>
#include <thrust/sort.h>
#include <thrust/count.h>
#include <thrust/binary_search.h>
#include <thrust/reduce.h>
#include <thrust/scan.h>
#include <thrust/functional.h>

#include <iostream>
#include <iomanip>

using namespace std;

// Design structures containing the data (remember the difference AoS and SoA)
struct Data
    {
    thrust::device_vector<int> day;
    thrust::device_vector<int> site;
    thrust::device_vector<int> measurement;
    };

int main()
    {
    int day[]     = {  0,  0,  1,  2,  5,  5,  6,  6,  7,  8 };
    int site[]    = {  2,  3,  0,  1,  1,  2,  0,  1,  2,  1 };
    int measure[] = {  9,  5,  6,  3,  3,  8,  2,  6,  5, 10 };

    cout << endl << "Thrust v" << THRUST_MAJOR_VERSION << "." << THRUST_MINOR_VERSION << endl ;

    int SIZE = sizeof(day)/sizeof(int);
    Data data;
    data.day         = thrust::device_vector<int>(day, day+SIZE);
    data.site        = thrust::device_vector<int>(site, site+SIZE);
    data.measurement = thrust::device_vector<int>(measure, measure+SIZE);

//  Calculate number of days with any rainfall
    {
    // Hint: inner_product, plus<int>, not_equal_to<int>
    int numOfDays = thrust::inner_product(data.day.begin(), data.day.end() - 1,
                                          data.day.begin() + 1,
                                          1,
                                          thrust::plus<int>(),
                                          thrust::not_equal_to<int>());

    cout << "number of days with any rainfall: " << numOfDays << endl;
    }

//  Calculate total rainfall at each site
    {
    // Hint: sort_by_key, inner_product, plus<int>, not_equal_to<int>, reduce_by_key
    thrust::device_vector<int> site = data.site;
    thrust::device_vector<int> measurement = data.measurement;

    thrust::sort_by_key(site.begin(), site.end(), measurement.begin());

    int numOfSites = thrust::inner_product(site.begin(), site.end() - 1,
                                           site.begin() + 1,
                                           1,
                                           thrust::plus<int>(),
                                           thrust::not_equal_to<int>());

    thrust::device_vector<int> siteId(numOfSites);
    thrust::device_vector<int> siteSum(numOfSites);

    thrust::reduce_by_key(site.begin(), site.end(),
                          measurement.begin(),
                          siteId.begin(),
                          siteSum.begin());

    cout << "total rainfall at each site:" << endl;
    for (int i = 0; i < numOfSites; i++) {
        cout << "  site " << siteId[i] << ": " << siteSum[i] << endl;
    }
    }

//  Get number of days when rainfall exceeded 5
    {
    // Hint: reduce_by_key, count_if, lambda function
    thrust::device_vector<int> dayId(SIZE);
    thrust::device_vector<int> daySum(SIZE);

    auto group = thrust::reduce_by_key(data.day.begin(), data.day.end(),
                                       data.measurement.begin(),
                                       dayId.begin(),
                                       daySum.begin());

    int num = thrust::count_if(daySum.begin(), group.second,
                               [] __host__ __device__ (int x) { return x > 5; });

    cout << "number of days when rainfall exceeded 5: " << num << endl;
    }

//  Find the first day when total rainfall exceeded 32
    {
    // Hint: inclusive_scan, lower_bound
    thrust::device_vector<int> runningSum(SIZE);

    thrust::inclusive_scan(data.measurement.begin(), data.measurement.end(),
                           runningSum.begin());

    int index = thrust::lower_bound(runningSum.begin(), runningSum.end(), 33)
                - runningSum.begin();

    if (index < SIZE) {
        cout << "first day when total rainfall exceeded 32: " << data.day[index] << endl;
    }
    else {
        cout << "total rainfall never exceeded 32" << endl;
    }
    }

//  Return total rainfall between day 2 and 6 (inclusive)
    {
    // Hint: lower_bound, upper_bound, reduce
    int first = thrust::lower_bound(data.day.begin(), data.day.end(), 2) - data.day.begin();
    int last  = thrust::upper_bound(data.day.begin(), data.day.end(), 6) - data.day.begin();

    int sum = thrust::reduce(data.measurement.begin() + first,
                             data.measurement.begin() + last);

    cout << "total rainfall between day 2 and 6: " << sum << endl;
    }

    return 0;
    }
