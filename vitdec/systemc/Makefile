##
# WLAN short preamble detection
#
# @file
# @version 0.1

# compiler
CXX = g++

# Flags passed to the C++ compiler.
CXXFLAGS += -g -Wall -Wextra -I. -I$(SYSTEMC_HOME)/include

objects := $(patsubst %.cpp, %.o, $(wildcard *.cpp))

all : vitdec_test

vitdec_test : $(objects)
	$(CXX) $(CXXFLAGS) $^ -o $@ -L. -L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lm

$(objects): %.o : %.cpp
	$(CXX) -c $(CXXFLAGS) $< -o $@

vitdec_source.o : vitdec_source.hpp
vitdec.o : vitdec.hpp
vitdec_display.o : vitdec_display.hpp
vitdec_test.o : vitdec_source.hpp vitdec.hpp vitdec_display.hpp

.PHONY: clean
clean :
	rm vitdec_test $(objects)

# end
