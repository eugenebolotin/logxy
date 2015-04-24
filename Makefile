BINARY=logxy
CXX=g++
CXXFLAGS=-std=c++0x -O3 -g
LDFLAGS=
LDLIBS=-lzmq

all:
	$(CXX) -o$(BINARY) src/*.cpp $(CXXFLAGS) $(LDFLAGS) $(LDLIBS)

clean:
	$(RM) $(BINARY)
