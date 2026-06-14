#pragma once

#include "cuda_runtime.h"
#include <cmath>
#include <cstdlib>
#include <cstdio>
#include <chrono>
#include <iostream>



#define COUNT 4 




__device__ void blelloch_scan(int *input, int *output, int n);