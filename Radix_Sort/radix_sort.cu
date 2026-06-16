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
    int* exclusive_scan_result = (int *)malloc(sizeof(int) * RADIX);
    int end = std::pow(2,RADIX)-1;

   

    // histogram construction
    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        buckets[input[i] & (1 << current_bit_level) ? 1 : 0]++;
    }

    for(int i=0; i<RADIX;i++){
        global_memory[threadId*RADIX + i]=buckets[i];
    }
    __syncthreads();


    // scan bucket
  
    //inclusive scan results is stored in global_sum array
    blelloch_scan<<<1,1>>>(buckets,exclusive_scan_result, RADIX);
    

    int first_term_sum_zero=exclusive_scan_result[threadId*RADIX];
    int first_term_sum_one=exclusive_scan_result[threadId*RADIX+1];    
    
    
    

    int second_term_sum_zero = 0;
    int second_term_sum_one = 0;

    for(int i=0; i<total_thread_count; i++){
        second_term_sum_zero+=global_memory[i*RADIX+0];
    }

    for(int i=0; i<total_thread_count;i++){
        second_term_sum_one+=global_memory[i*RADIX+1];
    }


   int index_position_zero = first_term_sum_zero+second_term_sum_zero;
   int index_position_one = first_term_sum_one+second_term_sum_one;

    global_memory_2[index_position_zero]=buckets[0];
    global_memory_2[index_position_one]=buckets[1];

    __syncthreads();




    delete[] buckets;
    delete[] exclusive_scan_result;
}   


int* radixSort(int *input, int n){


    int *global_sum;
    int *global_memory;
    int *global_memory_2;

    cudaMalloc(&global_sum,sizeof(int)*n*total_thread_count);
    cudaMalloc(&global_memory,sizeof(int)*n*total_thread_count);
    cudaMalloc(&global_memory_2,sizeof(int)*n*total_thread_count);

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
