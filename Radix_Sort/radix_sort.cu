#include "cuda_runtime.h"
#include "../Blelloch.hpp"
#include <thrust/device_ptr.h>
#include <thrust/extrema.h>






__device__ void counting_sort(int *input, int current_max){



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