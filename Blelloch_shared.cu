#include "cuda_runtime.h"
#include "Blelloch.hpp"

__device__
void blelloch_scan_shared(int *input, int *output, int n ){


int thid = threadIdx.x;
int offset = 1;

__shared__ int temp[1024];

temp[2*thid]=input[2*thid];
temp[2*thid+1]=input[2*thid+1];


for(int i= n >> 1; i>0; i>>=1){
    __syncthreads();
    if(thid < i){
        int ai= offset * (2 * thid + 1) - 1;
        int bi = offset * (2*thid + 2) - 1;
        temp[bi]+=temp[ai];
    }
    offset *= 2;
}


if(thid == 0)
{
    temp[n-1]=0;
}

for(int i=1; i<n; i*=2){

    offset>>=1;
    __syncthreads();
    if(thid < i){
        int   ai = offset * (2 * thid + 1) - 1;
        int   bi = offset * (2 * thid + 2) - 1;

        auto t = temp[ai];
        temp[ai]=temp[bi];
        temp[bi]+=t;
    }
}


__syncthreads();
output[2*thid]=temp[2*thid];
output[2*thid+1]=temp[2*thid+1];

}
