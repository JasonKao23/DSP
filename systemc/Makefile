# compiler
CXX = g++

# Flags passed to the C++ compiler.
CXXFLAGS += -g -Wall -Wextra -I. -I$(SYSTEMC_HOME)/include

objects := $(patsubst %.cpp,%.o,$(wildcard *.cpp))

all : main

main : $(objects)
	$(CXX) $(CXXFLAGS) $^ -o $@ -L. -L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lm

$(objects): %.o : %.cpp
	$(CXX) -c $(CXXFLAGS) $< -o $@

bfly.o : bfly.hpp
cmul.o : cmul.hpp bfly.hpp
ifft64.o : ifft64.hpp cmul.hpp bfly.hpp
ifft64_source.o : ifft64_source.hpp
ifft64_display.o : ifft64_display.hpp

main.o : bfly.hpp cmul.hpp ifft64.hpp ifft64_source.hpp ifft64_display.hpp

.PHONY: clean
clean :
	rm main $(objects)
