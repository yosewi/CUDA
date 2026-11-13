#ifndef IO_H
#define IO_H

#include "common.h"

int readTxt(const char* path, Dataset* data);

int readBin(const char* path, Dataset* data);

int writeResult(const char* path, const Dataset* data, const double* centroids, const int* labels);

void freeDataset(Dataset* data);

#endif