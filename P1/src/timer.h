#ifndef TIMER_H
#define TIMER_H

#include <chrono>

struct Timer {
    std::chrono::steady_clock::time_point begin;

    void start()
    {
        begin = std::chrono::steady_clock::now();
    }

    double stopMs() const
    {
        std::chrono::duration<double, std::milli> elapsed = std::chrono::steady_clock::now() - begin;
        return elapsed.count();
    }
};

#endif