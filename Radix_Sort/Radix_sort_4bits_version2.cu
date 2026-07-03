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


    __syncthreads();


    // if(threadId <=0 && current_bit_level==0){
    //     for(int i=0; i<((1 << bitSize));i++){
    //         printf("%d ",buckets[i]);
    //     }
    //     printf(
    //         "\n"
    //     );
    // }

    
    // if(threadId ==1 && current_bit_level==0){
    //     for(int i=0; i<((1 << bitSize));i++){
    //         printf("%d ",buckets[i]);
    //     }
    // }
    
    if(threadId==0 && current_bit_level==0){
     for(int i = threadId; i < (1 << bitSize) * total_thread_count; i ++){
        printf("%d ", global_memory[i]);
    }
}

    return;
}


// Exclusive Scan Phase
__global__ void ScanPhase(int *input, int *output){


    blelloch_scan(input,output, total_thread_count*(1 << bitSize));


    // __syncthreads();

    // if((int)threadIdx.x == 0){
    //    for(int i=0; i<(1 << bitSize)*total_thread_count;i++){
    //     printf("%d \n",output[i]);
    // }}
    
    
    return;
}



// Scatter phase
__global__ void scatter(int *input, int *secondary_input, int *output, int n, int current_bit_level){

    int threadId = threadIdx.x;
    uint32_t mask = 0xf << (4 * current_bit_level);

    int offset_array[(1 << 4)] = {0};
    

    for(int i=0; i < (1 << 4); i++){
        offset_array[i]=input[total_thread_count*i + threadId];
    }

    // index
    // 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    //
    // zero
    // 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30
    // 
    // one
    // 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31

    


      for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        int digit = (secondary_input[i] & (mask)) >> (4 * current_bit_level);

        output[offset_array[digit]]=secondary_input[i];
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


    for(int i=0; i<1;i++){
        
        HistogramGeneration<<<1,total_thread_count>>>(device_input,global_memory,i,n);



        cudaDeviceSynchronize();

        ScanPhase<<<1,((1<<bitSize)*total_thread_count)/2>>>(global_memory,scanPhase);


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

     // 1, 0, 1, 3, 2, 6, 4, 3
    input_array[0]=1;
    input_array[1]=0;
    input_array[2]=1;
    input_array[3]=3;
    input_array[4]=2;
    input_array[5]=6;
    input_array[6]=4;
    input_array[7]=3;

     int *output = radixSort(input_array,8);

    // for(int i=0; i<8;i++){
    //     printf("%d ",output[i]);
    // }



}