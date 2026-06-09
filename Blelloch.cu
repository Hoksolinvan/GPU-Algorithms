#include "cuda_runtime.h"
#include <cmath>
#include <cstdlib>
#include <cstdio>
#include <chrono>
#include <iostream>



#define COUNT 4 




__global__
void blelloch_scan(int *input, int *output, int n ){


int thid = threadIdx.x;
int offset = 1;

for(int i= n >> 1; i>0; i>>=1){
    __syncthreads();
    if(thid < i){
        int ai= offset * (2 * thid + 1) - 1;
        int bi = offset * (2*thid + 2) - 1;
        input[bi]+=input[ai];
    }
    offset *= 2;
}


if(thid == 0)
{
    input[n-1]=0;
}

for(int i=1; i<n; i*=2){

    offset>>=1;
    __syncthreads();
    if(thid < i){
        int   ai = offset * (2 * thid + 1) - 1;
        int   bi = offset * (2 * thid + 2) - 1;

        auto t = input[ai];
        input[ai]=input[bi];
        input[bi]+=t;
    }
}


__syncthreads();
output[2*thid]=input[2*thid];
output[2*thid+1]=input[2*thid+1];

}



int main(){

  int *host_pointer = (int *)malloc(sizeof(int)*COUNT);
  int *device_pointer;
  int *output_device_pointer;



  cudaMalloc(&device_pointer,sizeof(int)*COUNT);
  cudaMalloc(&output_device_pointer,sizeof(int)*COUNT);

  for(int i=0; i<COUNT;i++){
    host_pointer[i]=i;
  }

  cudaMemcpy(device_pointer,host_pointer,sizeof(int)*COUNT,cudaMemcpyHostToDevice);

auto start = std::chrono::high_resolution_clock::now();

  blelloch_scan<<<1,COUNT/2>>>(device_pointer,output_device_pointer,COUNT);

auto end = std::chrono::high_resolution_clock::now();
auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
  std::cout << duration.count() << " ms\n";
  
  cudaMemcpy(host_pointer,output_device_pointer,sizeof(int)*COUNT,cudaMemcpyDeviceToHost);


  for(int i=0; i<COUNT;i++){
    printf("%d ",host_pointer[i]);
  }

  free(host_pointer);
  cudaFree(device_pointer);
  cudaFree(output_device_pointer);
  return 0;
}
