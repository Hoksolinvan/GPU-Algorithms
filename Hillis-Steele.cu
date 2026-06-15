#include "Hillis_Steele.hpp"




__device__
void hillis_steele_inclusive_scan(int*input,int* output, int n){

  int threadId = blockIdx.x * blockDim.x + threadIdx.x;
   


  if(threadId>n){
    return;
  }

  for(int i=1;i<n;i*=2){
    
    if(threadId<i){
      input[threadId]=input[threadId];
    }

    else{
      int previous = threadId - std::pow(2,i-1);
    input[threadId]+=input[previous];

    }




      __syncthreads();
  }

  output[threadId]=input[threadId];

  return;

}

__global__
void hillis_steele_exclusive_scan(int* input, int* buffer,int n){

  int threadId = blockIdx.x * blockDim.x + threadIdx.x;


   
  if(threadId > n){
    return;
  }


  for(int i=1; i<n; i*=2){


    if(threadId < i){
     buffer[threadId]=buffer[threadId];
    }
    else{
        int offset = threadId - std::pow(2,i-1);
      buffer[threadId]+=input[threadId-offset];
    }

    __syncthreads();
  }


  return;

}






}

// int main(){       
//   int *host_pointer = (int *)malloc(sizeof(int)*COUNT);
//   int *device_pointer;
//   int *output_device_pointer;
  

//   for(int i=0; i<COUNT;i++){
//     host_pointer[i]=i;
//   }
  

//   cudaMalloc(&device_pointer, COUNT*sizeof(int));
//   cudaMalloc(&output_device_pointer,COUNT*sizeof(int));

//   cudaMemcpy(device_pointer,host_pointer,COUNT*sizeof(int),cudaMemcpyHostToDevice);
// auto start = std::chrono::high_resolution_clock::now();
//   hillis_steele_inclusive_scan<<<1,1024>>>(device_pointer,output_device_pointer,COUNT);
//   cudaDeviceSynchronize();
// auto end = std::chrono::high_resolution_clock::now();
// auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
//   std::cout << duration.count() << " ms\n";
  

//   cudaMemcpy(host_pointer,device_pointer,COUNT*sizeof(int),cudaMemcpyDeviceToHost);

//   printf("Inclusive Prefix Sum (Hillis-Steele): ");
//   for(int i=0; i<COUNT;i++){
//     //printf("%d ",host_pointer[i]);
//   }
//   printf("\n");


  
//  int *host_pointer_2 = (int *)malloc(COUNT*sizeof(int));
//  int *device_pointer_2;
//  int *output_device_pointer_2;

//  for(int i=0; i<COUNT;i++){
//   host_pointer_2[i]=i;
//  }

//  cudaMalloc(&device_pointer_2, COUNT*sizeof(int));
//  cudaMalloc(&output_device_pointer_2,COUNT*sizeof(int));

//  cudaMemcpy(device_pointer_2, host_pointer_2,COUNT*sizeof(int),cudaMemcpyHostToDevice);
// start = std::chrono::high_resolution_clock::now();
//  hillis_steele_exclusive_scan<<<1,1024>>>(device_pointer_2,output_device_pointer_2,COUNT);
//  cudaDeviceSynchronize(); 
//   end = std::chrono::high_resolution_clock::now();
//  duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
//   std::cout << duration.count() << " ms\n";
  

//  cudaMemcpy(host_pointer_2,output_device_pointer_2,COUNT*sizeof(int),cudaMemcpyDeviceToHost);

//  printf("Exclusive Prefix Sum (Hillis-Steele): ");
//  for(int i=0; i<COUNT;i++){
//   //printf("%d ",host_pointer_2[i]);
//  }
//  printf("\n");




//  int arr[COUNT];

//  for(int i=0; i<COUNT;i++){
//   arr[i]=i;
//  }

//   start = std::chrono::high_resolution_clock::now();

//  for(int i=1; i<COUNT;i++){
//     arr[i]+=arr[i-1];
//  }
//   end = std::chrono::high_resolution_clock::now();
//  duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
//   std::cout << duration.count() << " ms\n";


//   cudaFree(output_device_pointer_2);
//   cudaFree(device_pointer_2);
//   cudaFree(device_pointer);
//   cudaFree(output_device_pointer);
//   free(host_pointer);
//   free(host_pointer_2);


//   return 0;
// }
