#include "cuda_runtime.h"
#include "../Blelloch.hpp"
#include <cmath>


#define CCCL_IGNORE_MSVC_TRADITIONAL_PREPROCESSOR_WARNING
const int RADIX = 2;
const int total_thread_count = 2;
const int bitSize = 4;

__global__ void counting_sort(int *input, int * global_sum, int *global_memory, int *global_memory_2, int *buffer, int current_bit_level, int n){

    // configuration
    int threadId = threadIdx.x;
    uint32_t mask = 0xf << current_bit_level;


    int buckets[(1<<(bitSize+1))] = {0};

   //thread0 : 0 ; 2
   //thread1 : 2 ; 4    

    // histogram construction
    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        buckets[input[i] & (mask)]++;
    }

    for(int i=0; i<(1<<(bitSize+1));i++){
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
            blelloch_scan(global_memory, buffer, total_thread_count*(1<<(bitSize+1)));

           // __syncthreads();
        //     if(current_bit_level <=0 && threadId == 1){
        //     for(int i=0; i<total_thread_count*RADIX; i++){
        //          printf("ThreadId %d = Bit position %d = : %d \n",threadId, current_bit_level, buffer[i]);
        //     }
        // }

        
            int total_zero = buffer[total_thread_count];
            // int total_zero = exclusive_scan_result[total_thread_count]+global_memory[total_thread_count-1];

            // for(int i=0; i<total_thread_count;i++){
            //     total_zero += global_memory[i*RADIX+0];

            // }

            
            //0 2 4

            
            // int prior_zero = buffer[threadId];
            // int prior_one = buffer[total_thread_count+threadId];

            // int offset_zero = prior_zero;
            // int offset_one = prior_one;

            int offset_array[(1 << 5)] {0};

            for(int i=0; i<(1 << 5);i++){
                offset_array[i]=buffer[total_thread_count*i +threadId];
            }


           
            // if(current_bit_level==0){

            //     printf("ThreadId %d : total_zero %d : prior_zero %d : prior_one %d\n",threadId, total_zero,prior_zero,prior_one);
            // }



    __syncthreads();


    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
        int digit = input[i] & (mask);

        global_memory_2[offset_array[digit]]=input[i];
        offset_array[digit]++;
    // if(digit == 0){
    //     global_memory_2[offset_zero] = input[i];
    //     offset_zero++;
    // } else {
    //     global_memory_2[offset_one] = input[i];
    //     offset_one++;
    // }

    }

    //    for(int i=(n/total_thread_count)*threadId; i<(n/total_thread_count)*(threadId+1);i++){
    //     int digit = input[i] & (mask) ? 1 : 0;
    // if(digit == 0){
    //     global_memory_2[offset_zero] = input[i];
    //     offset_zero++;
    // } else {
    //     global_memory_2[offset_one] = input[i];
    //     offset_one++;
    // }

    // }

    __syncthreads();


}   


int* radixSort(int *input, int n){

    int *input_array;
    int *global_sum;
    int *global_memory;
    int *global_memory_2;
    int *buffer;

    cudaMalloc(&buffer,sizeof(int)*RADIX*total_thread_count);
    cudaMalloc(&input_array,sizeof(int)*n);
    cudaMalloc(&global_sum,sizeof(int)*RADIX*total_thread_count);
    cudaMalloc(&global_memory,sizeof(int)*RADIX*total_thread_count);
    cudaMalloc(&global_memory_2,sizeof(int)*n);

    cudaMemcpy(input_array,input,sizeof(int)*n, cudaMemcpyHostToDevice);
    for(int i=0; i<(32/bitSize); i++){
    counting_sort<<<1,total_thread_count>>>(input_array, global_sum, global_memory, global_memory_2, buffer, i, n);
    cudaDeviceSynchronize();
    std::swap(input_array, global_memory_2);   // output becomes next pass's input
}
    cudaMemcpy(input,input_array,sizeof(int)*n, cudaMemcpyDeviceToHost);



    cudaFree(buffer);
    cudaFree(input_array);
    cudaFree(global_memory);
    cudaFree(global_sum);
    cudaFree(global_memory_2);
    return input;
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
