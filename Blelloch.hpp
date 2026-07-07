#pragma once

#include "cuda_runtime.h"
#include <cmath>
#include <cstdlib>
#include <cstdio>
#include <chrono>
#include <iostream>



#define COUNT 4 




__device__ void blelloch_scan(int *input, int *output, int n);


__device__ void inclusive_blelloch_scan(int *input, int original_one, int original_zero, int *output, int n );


__device__ void blelloch_scan_shared(int *input, int *output, int n );

