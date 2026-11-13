NVCC = nvcc
NVCCFLAGS = -O3 -std=c++17 -arch=native -Xcompiler -Wall,-Wextra
 
TARGET = KMeans
SOURCES = src/main.cu src/io.cpp src/kmeans_cpu.cpp
HEADERS = src/common.h src/io.h src/kmeans_cpu.h src/timer.h
 
all: $(TARGET)
 
$(TARGET): $(SOURCES) $(HEADERS)
	$(NVCC) $(NVCCFLAGS) $(SOURCES) -o $(TARGET)
 
clean:
	rm -f $(TARGET)
 
.PHONY: all clean