#include "cuda_runtime.h"
#include "../Blelloch.hpp"
#include <cmath>


# define CCCL_IGNORE_MSVC_TRADITIONAL_PREPROCESSOR_WARNING
const int RADIX = 2;
const int total_thread_count = 2;

__global__ void counting_sort(int *input, int * global_sum, int *global_memory, int *global_memory_2, int current_bit_level, int n){

    // configuration
    int threadId = threadIdx.x;
    uint32_t mask = 1 << current_bit_level;


    int buckets[RADIX] = {0};
    int exclusive_scan_result[total_thread_count*RADIX] = {0};

   //thread0 : 0 ; 2
   //thread1 : 2 ; 4    

    // histogram construction
    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        buckets[input[i] & (mask) ? 1 : 0]++;
    }

    for(int i=0; i<RADIX;i++){
        global_memory[i*total_thread_count + threadId] = buckets[i];
    }

    // 0+0 (0); 2+0; 0+1; 2+1
    // 0; 2; 1; 3
    // for(int i=0; i<RADIX;i++){
    //     printf("ThreadId %d = Bit position %d = : %d \n",threadId, current_bit_level, buckets[i]);
    // }
   
    // for(int i=0; i<RADIX; i++){
    //    printf("ThreadId %d = Bit position %d = : %d \n",threadId, current_bit_level, global_memory[i*total_thread_count + threadId]);
    // }
    // printf("\n");
    __syncthreads();


    // scan bucket
    
        //inclusive scan results is stored in global_sum array
            blelloch_scan(global_memory, exclusive_scan_result, total_thread_count*RADIX);


            __syncthreads()
            for(int i=0; i<total_thread_count*RADIX; i++){
                 printf("ThreadId %d = Bit position %d = : %d \n",threadId, current_bit_level, exclusive_scan_result[i]);
            }
        
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
        int digit = (input[i] >> current_bit_level) & 1;
    if(digit == 0){
        global_memory_2[offset_zero] = input[i];
        offset_zero++;
    } else {
        global_memory_2[offset_one] = input[i];
        offset_one++;
    }

    }

    __syncthreads();


}   


int* radixSort(int *input, int n){

    int *input_array;
    int *global_sum;
    int *global_memory;
    int *global_memory_2;


    cudaMalloc(&input_array,sizeof(int)*5);
    cudaMalloc(&global_sum,sizeof(int)*RADIX*total_thread_count);
    cudaMalloc(&global_memory,sizeof(int)*RADIX*total_thread_count);
    cudaMalloc(&global_memory_2,sizeof(int)*n);

    cudaMemcpy(input_array,input,sizeof(int)*5, cudaMemcpyHostToDevice);
    for(int i=0; i<32;i++){

        counting_sort<<<1,total_thread_count>>>(input_array,global_sum,global_memory,global_memory_2,i,n);
        //cudaDeviceSynchronize();
    }

    cudaMemcpy(input,global_memory_2,sizeof(int)*5, cudaMemcpyDeviceToHost);




    cudaFree(input_array);
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


    int *output = radixSort(input_array,4);

    for(int i=0; i<4;i++){
        printf("%d ",output[i]);
    }

}
