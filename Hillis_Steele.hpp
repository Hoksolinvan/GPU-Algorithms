#pragma once

#include "cuda_runtime.h"
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <cstdio>
#include <chrono>

#define COUNT 40000


__global__ void hillis_steele_inclusive_scan(int*input,int* output, int n);


__global__
void hillis_steele_exclusive_scan(int* input, int* buffer,int n);