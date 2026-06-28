#include "cuda_runtime.h"
#include "../Blelloch.hpp"
#include <cmath>

#define CCCL_IGNORE_MSVC_TRADITIONAL_PREPROCESSOR_WARNING

const int total_thread_count = 2;
const int bitSize = 4;



// Histogram Generation Phase
__global__ void HistogramGeneration(int *input, int *global_memory, int current_bit_level, int n){

    int threadId = threadIdx.x;
    uint32_t mask = 0xf << (4 * current_bit_level);

    int buckets[(1 << bitSize)] = {0};


    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        buckets[(input[i] & (mask))>>(4*current_bit_level)]++;  
    }

    for(int i=0; i<(1<<(bitSize));i++){
        global_memory[i*total_thread_count + threadId] = buckets[i];
    }


    return;
}


// Exclusive Scan Phase
__global__ void scanPhase(int *input, int *output){


    blelloch_scan(input,output, total_thread_count*(1 << bitSize));
    
    return;
}



// Scatter phase
__global__ void scatter(int *input, int *secondary_input, int *output, int n, int current_bit_level){

    int threadId = threadIdx.x;
    uint32_t mask = 0xf << (4 * current_bit_level);

    int offset_array[(1 << 5)] = {0};
    

    for(int i=0; i < (1 << 5); i++){
        offset_array[i]=input[total_thread_count*i + threadId];
    }

      for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        int digit = (input[i] & (mask)) >> (4 * current_bit_level);

        output[offset_array[digit]]=input[i];
        offset_array[digit]++;
   

    }


    return;
}


int* radixSort(int* input_array, int n){


    int *output_array = (int *)malloc(sizeof(input_array));
    int *device_input;
    int *global_memory;
    int *scanPhase;
    int *scatterOutput;
    

    cudaMalloc(&device_input,sizeof(int)*n);
    cudaMalloc(&global_memory,sizeof(int)* (1 << bitSize) * total_thread_count);
    cudaMalloc(&scanPhase, sizeof(int)* (1 << bitSize)*total_thread_count);
    cudaMalloc(&scatterOutput,sizeof(int)*n);
    
    cudaMemcpy(device_input,input_array,sizeof(int)*n,cudaMemcpyHostToDevice);


    for(int i=0; i<(32/bitSize);i++){
        
        HistogramGeneration<<<1,total_thread_count>>>(device_input,global_memory,i,n);

        cudaDeviceSynchronize();

        scanPhase<<<1,((1<<bitSize)*total_thread_count)/2>>>(global_memory,scanPhase);


        cudaDeviceSynchronize();

        scatter<<<1,total_thread_count>>>(scanPhase, device_input, scatterOutput,n, i);

        cudaDeviceSynchronize();


        std::swap(device_input,scatterOutput);
    }


    cudaMemcpy(output_array,device_input,sizeof(int)*n,cudaMemcpyDeviceToHost);

    cudaFree(scatterOutput);    
    cudaFree(scanPhase);
    cudaFree(global_memory);
    cudaFree(device_input);
    return output_array;
}




int main(){

     int *input_array = (int *)malloc(sizeof(int)*8);

    input_array[0]=1;
    input_array[1]=0;
    input_array[2]=1;
    input_array[3]=3;
    input_array[4]=2;
    input_array[5]=6;
    input_array[6]=4;
    input_array[7]=3;

     int *output = radixSort(input_array,8);

    for(int i=0; i<8;i++){
        printf("%d ",output[i]);
    }



}