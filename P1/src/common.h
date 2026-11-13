#ifndef COMMON_H
#define COMMON_H

// Ograniczenia ze specyfikacji.
#define MAX_DIM 20
#define MAX_K 20
#define MAX_ITERATIONS 100

enum DataFormat {
    FORMAT_TXT,
    FORMAT_BIN
};

enum Method {
    METHOD_CPU,
    METHOD_GPU1,
    METHOD_GPU2
};

struct Options {
    DataFormat  format;
    Method      method;
    const char* inputPath;
    const char* outputPath;
};

struct Dataset {
    int N;
    int d; 
    int k;
    double* points;
};

#endif