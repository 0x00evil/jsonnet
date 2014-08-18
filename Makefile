# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###################################################################################################
# User-servicable parts:
###################################################################################################

# C/C++ compiler -- clang also works
CXX ?= g++
CC ?= gcc

# Emscripten -- For Jsonnet in the browser
EMCXX ?= em++
EMCC ?= emcc

CP = cp

CXXFLAGS ?= -g -O3 -Wall -Wextra -pedantic -std=c++0x
CFLAGS ?= -g -O3 -Wall -Wextra -pedantic -std=c99
EMCXXFLAGS = $(CXXFLAGS) --memory-init-file 0 -s DISABLE_EXCEPTION_CATCHING=0
EMCFLAGS = $(CFLAGS) --memory-init-file 0 -s DISABLE_EXCEPTION_CATCHING=0
LDFLAGS ?=

PYTHON_CFLAGS ?= -I/usr/include/python2.7
PYTHON_LDFLAGS ?=

SHARED_CFLAGS ?= -fPIC
SHARED_LDFLAGS ?= -shared

###################################################################################################
# End of user-servicable parts
###################################################################################################

SRC = lexer.cpp parser.cpp static_analysis.cpp vm.cpp
LIB_SRC = $(SRC) libjsonnet.cpp

ALL = jsonnet libjsonnet.so libjsonnet_test_snippet libjsonnet_test_file _jsonnet.so libjsonnet.js
ALL_HEADERS = vm.h static_analysis.h parser.h lexer.h ast.h static_error.h state.h

default: jsonnet

all: $(ALL)

test: jsonnet libjsonnet.so libjsonnet_test_snippet libjsonnet_test_file _jsonnet.so
	cd test_suite ; ./run_tests.sh
	cd examples ; ./check.sh
	test `python jsonnet_test_snippet.py "({ x: 1, y: self.x } { x: 2 }).y == 2"` == "true"
	test `python jsonnet_test_file.py "test_suite/object.jsonnet"` == "true"
	test `./libjsonnet_test_snippet "({ x: 1, y: self.x } { x: 2 }).y == 2"` == "true"
	test `./libjsonnet_test_file "test_suite/object.jsonnet"` == "true"

# Commandline executable.
jsonnet: jsonnet.cpp $(SRC) $(ALL_HEADERS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(SRC) $< -o $@

# C binding.
libjsonnet.so: $(LIB_SRC) $(ALL_HEADERS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(LIB_SRC) $(SHARED_CFLAGS) $(SHARED_LDFLAGS) -o $@

# Javascript build of C binding
libjsonnet.js: $(LIB_SRC) $(ALL_HEADERS)
	$(EMCXX) -s 'EXPORTED_FUNCTIONS=["_jsonnet_evaluate_snippet", "_jsonnet_delete"]' $(EMCXXFLAGS) $(LDFLAGS) $(LIB_SRC) -o $@
	$(CP) $@ doc/

# Tests for C binding.
libjsonnet_test_snippet: libjsonnet_test_snippet.c libjsonnet.so libjsonnet.h
	$(CC) $(CFLAGS) $(LDFLAGS) $< libjsonnet.so -o $@

libjsonnet_test_file: libjsonnet_test_file.c libjsonnet.so libjsonnet.h
	$(CC) $(CFLAGS) $(LDFLAGS) $< libjsonnet.so -o $@

# Python binding.
_jsonnet.o: _jsonnet.c
	$(CC) $(CFLAGS) $(PYTHON_CFLAGS) $(SHARED_CFLAGS) $< -c -o $@

_jsonnet.so: _jsonnet.o $(LIB_SRC) $(ALL_HEADERS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(LIB_SRC) $< $(SHARED_CFLAGS) $(SHARED_LDFLAGS) -o $@

clean:
	rm -vf */*~ *~ */.*.swp .*.swp $(ALL) *.o 
