#include "cuda_runtime.h"

#define COUNT 8

__global__
void hillis_steele(int*input,int* output, int n){

  int threadId = threadIdx.x;

  if(threadId>n){
    return;
  }

  for(int i=1;i<n;i*=2){
    
    if(threadId<i){
      input[threadId]=input[threadId];
    }

    else{
    input[threadId+i

    }




      __syncthreads();
  }

  

}

int main(){


  int *host_pointer = (int *)malloc(sizeof(int)*COUNT);
  int *device_pointer;
  int *output_device_pointer;
  host_pointer[0]=1;
  host_pointer[1]=2;
  host_pointer[2]=3;
  host_pointer[3]=4;
  host_pointer[4]=5;
  host_pointer[5]=6;
  host_pointer[6]=7;
  host_pointer[7]=8;
  

  cudaMalloc(&device_pointer, COUNT*sizeof(int));
  cudaMalloc(&output_device_pointer,COUNT*sizeof(int));

  cudaMemcpy(device_pointer,host_pointer,COUNT*sizeof(int),cudaMemcpyHostToDevice);

  hillis_steele<<<1,1024>>>(device_pointer,output_device_pointer,COUNT);


  
  cudaFree(device_pointer);
  cudaFree(output_device_pointer);
  free(host_pointer);


  return 0;
}
