#include <iostream>
#include <cuda_runtime.h>
#include <random>


#define TILE_SIZE 4
#define dimension 8


__global__ void matrix_multiplication_naive(const int* A, const int* B, int* C) {


int row = blockIdx.y * blockDim.y + threadIdx.y;
int col = blockIdx.x * blockDim.x + threadIdx.x;

int sum = 0;
for(int i=0; i<dimension; i++){
   sum += A[row*dimension + i] * B[i*dimension+col];
}


C[row*dimension+col] = sum;


}


// __global__ void matrix_multiplication_warp(const int* A, const int* B, int* C){

//    int lane = threadIdx.x;


//    int row = blockIdx.y;
//    int col = blockIdx.x;
//    int sum = 0;

//    for(int i=0; i<dimension;i+=32){

//     int offset = i+lane;


//     int cur_value = 0;

//     if(offset < dimension){
//     cur_value+=A[row*dimension + i] * B[i*dimension+col];

//     }


//     cur_value += __shfl_down_sync(0xffffffff,16);
//     cur_value += __shfl_down_sync(0xffffffff,8);
//     cur_value += __shfl_down_sync(0xffffffff,4);
//     cur_value += __shfl_down_sync(0xffffffff,2);
//     cur_value += __shfl_down_sync(0xffffffff,1);


//     if(lane==0){
//         sum+=cur_value;
//     }

//    }





//     if(lane == 0){
//         c[dimension*row+col] = sum;
//     }


// }

void printMatrix(int* mat) {
    for (int i = 0; i < dimension; i++) {
        for (int j = 0; j < dimension; j++)
            std::cout << mat[i * dimension + j] << " ";
        std::cout << std::endl;
    }
    std::cout << std::endl;
}



__global__ void shared_memory_matrix(const int* A, const int* B, int* C){

    __shared__ int A_shared[TILE_SIZE][TILE_SIZE];
    __shared__ int B_shared[TILE_SIZE][TILE_SIZE];

    int acc[TILE_SIZE] = {0};

    int row = blockIdx.y * TILE_SIZE + threadIdx.y;
    int col = blockIdx.x * TILE_SIZE + threadIdx.x;

    


    for(int i=0; i<dimension/TILE_SIZE;i++){
        

        // for (int j = 0; j < TILE_SIZE; j++) {
        A_shared[threadIdx.y][threadIdx.x] = A[row * dimension + i * TILE_SIZE + threadIdx.x];
        //}

       
       // for (int j = 0; j < TILE_SIZE; j++) {
        B_shared[threadIdx.y][threadIdx.x] = B[(i * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + threadIdx.x];
        //}


        // synchronizes entire thread block
        __syncthreads();


        // each thread handle 1 row. Therefore, if our tile is 4x4 then we have four threads
        
        int term = 0;
        for(int j = 0; j<TILE_SIZE;j++){

            term = A_shared[threadIdx.y][threadIdx.x] * B_shared[threadIdx.x][j];

            for(int k=TILE_SIZE/2; k >= 1 ; k/=2){


                term +=__shfl_down_sync(0x0000FFFF,term,k,TILE_SIZE);
            }


            if (threadIdx.x == 0) {
                acc[j] += term;
            }
            
        }


        __syncthreads();
     
        
    }



    if (threadIdx.x == 0) {
        for (int j = 0; j < TILE_SIZE; j++) {
            C[row * dimension + blockIdx.x * TILE_SIZE + j] = acc[j];
        }
    }

}




int main() {
    int *matrixA = new int[dimension*dimension];
    int *matrixB = new int[dimension*dimension];
    int *result = new int[dimension*dimension];
    int *device_matrixA;
    int *device_matrixB;
    int *device_matrixC;

    cudaMalloc(&device_matrixA, sizeof(int)*dimension*dimension);
    cudaMalloc(&device_matrixB, sizeof(int)*dimension*dimension);
    cudaMalloc(&device_matrixC, sizeof(int)*dimension*dimension);
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<int> int_dist(1, 10);

    for(int i=0; i<(dimension*dimension);i++){
        matrixA[i]=int_dist(gen);
        matrixB[i]=int_dist(gen);
    }
    cudaMemcpy(device_matrixA,matrixA,sizeof(int)*dimension*dimension,cudaMemcpyHostToDevice);
    cudaMemcpy(device_matrixB,matrixB,sizeof(int)*dimension*dimension,cudaMemcpyHostToDevice);

    dim3 blockDim(TILE_SIZE, TILE_SIZE, 1);
    dim3 gridDim(dimension/TILE_SIZE, dimension/TILE_SIZE, 1);
    shared_memory_matrix<<<gridDim, blockDim>>>(device_matrixA, device_matrixB, device_matrixC);
    cudaDeviceSynchronize();

    cudaMemcpy(result, device_matrixC, sizeof(int)*dimension*dimension, cudaMemcpyDeviceToHost);

    std::cout << "Matrix A:" << std::endl;
    printMatrix(matrixA);
    std::cout << "Matrix B:" << std::endl;
    printMatrix(matrixB);
    std::cout << "Result:" << std::endl;
    printMatrix(result);

    delete[] matrixA;
    delete[] matrixB;
    delete[] result;
    cudaFree(device_matrixA);
    cudaFree(device_matrixB);
    cudaFree(device_matrixC);
    return 0;
}
