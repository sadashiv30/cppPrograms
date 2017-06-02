#CXX=g++
CXX=clang++-3.8
RM=rm -f
CPPFLAGS= -o0 -g
LDFLAGS=

SRCS := $(wildcard *.cpp)
#OBJS := $(patsubst %.cpp,%.o,$(SRCS))
TARGETS = $(patsubst %.cpp,%,$(SRCS))

all: $(TARGETS)

perimeter: perimeter.cpp
movie: movie.cpp
bill : bill.cpp
guess : guess.cpp
defaultParam : defaultParam.cpp
selectionSort : selectionSort.cpp



$(TARGETS):
	$(CXX) $(CPPFLAGS) -o $@  $^

format:
	@find . -type f -name '*.cpp' | xargs clang-format -i
	@find . -type f -name '*.h' | xargs clang-format -i
	
clean:
	rm -f $(OBJS) $(TARGETS)
PHONY: clean all format