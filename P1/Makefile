NVCC = nvcc
NVCCFLAGS = -O3 -std=c++17 -arch=native -Xcompiler -Wall,-Wextra

TARGET = KMeans
SOURCES = src/main.cu
HEADERS = src/common.h

all: $(TARGET)

$(TARGET): $(SOURCES) $(HEADERS)
	$(NVCC) $(NVCCFLAGS) $(SOURCES) -o $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean
