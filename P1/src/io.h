#ifndef IO_H
#define IO_H

#include "common.h"

int readTxt(const char* path, Dataset* data);

void freeDataset(Dataset* data);

#endif
