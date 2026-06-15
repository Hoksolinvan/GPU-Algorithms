#include "cuda_runtime.h"
#include "../Blelloch.hpp"
#include <thrust/device_ptr.h>
#include <vector>
#include <vector>
#include <thrust/extrema.h>
#include <cmath>



const int RADIX = 2;
const int total_thread_count = 2;

__global__ void counting_sort(int *input, int * global_sum, int *global_memory, int current_max, int current_bit_level, int n){

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
    int first_term_sum = 0;

    
    //inclusive scan results is stored in global_sum array
    inclusive_blelloch_scan<<<1,2/2>>>(buckets,buckets[1], buckets[0], exclusive_scan_result, RADIX);
    for(int i=0; i<RADIX;i++){
        global_sum[threadId*RADIX + i]=exclusive_scan_result[i];
    }


    //
    for(int i=0; i< RADIX;i++){
        first_term_sum+=global_memory[threadId];    
    }
    
    

    int second_term_sum = 0;

    for(int i=0; i<total_thread_count; i++){
        second_term_sum+=global_memory[i*RADIX + threadId];
    }


    int index_position = first_term_sum + second_term_sum;

    __syncthreads();




    delete[] buckets;
    delete[] exclusive_scan_result;
}   


int* radixSort(int *input, int n){



    for(int i=0; i<32;i++){

        counting_sort<<<1,total_thread_count>>>();

    }


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
