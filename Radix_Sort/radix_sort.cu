#include "cuda_runtime.h"
#include "../Blelloch.hpp"
#include <thrust/device_ptr.h>
#include <vector>
#include <vector>
#include <thrust/extrema.h>
#include <cmath>



const int RADIX = 2;
const int total_thread_count = 2;

__global__ void counting_sort(int *input, int * global_sum, int *global_memory, int *global_memory_2, int current_bit_level, int n){

    // configuration
    int threadId = threadIdx.x;
    uint32_t mask = 1 << current_bit_level;
    int* buckets = (int *)malloc(sizeof(int)*RADIX);
    memset(buckets,0,sizeof(int)*RADIX);
    int* exclusive_scan_result = (int *)malloc(sizeof(int) * RADIX);
    int end = std::pow(2,RADIX)-1;

   

    // histogram construction
    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        buckets[input[i] & (1 << current_bit_level) ? 1 : 0]++;
    }

    for(int i=0; i<RADIX;i++){
        global_memory[i*total_thread_count + threadId] = buckets[i];
    }
    __syncthreads();


    // scan bucket
    
        //inclusive scan results is stored in global_sum array
            blelloch_scan(global_memory, exclusive_scan_result, total_thread_count*RADIX);


        
            int total_zero = exclusive_scan_result[total_thread_count-1]+global_memory[total_thread_count-1];
            // for(int i=0; i<total_thread_count;i++){
            //     total_zero += global_memory[i*RADIX+0];

            // }


            //0 2 4

            
            int prior_zero = exclusive_scan_result[threadId];
            int prior_one = exclusive_scan_result[total_thread_count+threadId];

            int offset_zero = prior_zero;
            int offset_one = total_zero+prior_one;
            



    __syncthreads();


    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){


    }




    delete[] buckets;
    delete[] exclusive_scan_result;
}   


int* radixSort(int *input, int n){


    int *global_sum;
    int *global_memory;
    int *global_memory_2;

    cudaMalloc(&global_sum,sizeof(int)*RADIX*total_thread_count);
    cudaMalloc(&global_memory,sizeof(int)*RADIX*total_thread_count);
    cudaMalloc(&global_memory_2,sizeof(int)*n);

    for(int i=0; i<32;i++){

        counting_sort<<<1,total_thread_count>>>(input,global_sum,global_memory,global_memory_2,i,n);

    }




    cudaFree(global_memory);
    cudaFree(global_sum);
    cudaFree(global_memory_2);
    return input;
}




int main(){

    int *input_array = (int *)malloc(sizeof(int)*5);

    input_array[0]=1;
    input_array[1]=0;
    input_array[2]=1;
    input_array[3]=3;
    input_array[4]=2;

    thrust::device_ptr<int> d_ptr(input_array);

    thrust::device_ptr<int> max_ptr = thrust::max_element(d_ptr,d_ptr+4);
    int max_value = *max_ptr;




}
