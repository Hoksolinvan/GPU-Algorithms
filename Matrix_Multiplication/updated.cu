#include <iostream>
#include <cuda_runtime.h>
#include <random>


#define TILE_SIZE 16
#define dimension 1024

#define CUDA_CHECK(call) \
    do { \
        cudaError_t error = call; \
        if (error != cudaSuccess) { \
            std::cerr << "CUDA Error: " << cudaGetErrorString(error) \
                      << " in " << __FILE__ << " at line " << __LINE__ << std::endl; \
            exit(EXIT_FAILURE); \
        } \
    } while (0)






__global__ void shared_memory_with_warp_matrix(const int* A, const int* B, int* C){

    __shared__ int A_shared[TILE_SIZE][TILE_SIZE];
    __shared__ int B_shared[TILE_SIZE][TILE_SIZE];


    int acc[TILE_SIZE] = {0};

    unsigned int mask = __activemask();

    int row = blockIdx.y * TILE_SIZE + threadIdx.y;

    
    for(int i=0; i<dimension/TILE_SIZE;i++){
        

        A_shared[threadIdx.y][threadIdx.x] = __ldg(&A[row * dimension + i * TILE_SIZE + threadIdx.x]);
        B_shared[threadIdx.y][threadIdx.x] = __ldg(&B[(i * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + threadIdx.x]);



        __syncthreads();


        
        int term = 0;

        for(int j = 0; j<TILE_SIZE;j++){

            term = A_shared[threadIdx.y][threadIdx.x] * B_shared[threadIdx.x][j];

            for(int k=TILE_SIZE/2; k >= 1 ; k/=2){

                term +=__shfl_down_sync(mask,term,k,TILE_SIZE);
            }


            if (threadIdx.x == 0) {
               C[row * dimension + blockIdx.x * TILE_SIZE + j] = acc[j];
            }
            
        }


     
        
    }



}


__global__ void shared_memory_matrix(const int* A, const int* B, int* C){

    
    __shared__ int A_shared[TILE_SIZE][TILE_SIZE];
    __shared__ int B_shared[TILE_SIZE][TILE_SIZE];


    int row = blockIdx.y * TILE_SIZE + threadIdx.y;

    for(int i=0; i<dimension/TILE_SIZE;i++){
        

        A_shared[threadIdx.y][threadIdx.x] = __ldg(&A[row * dimension + i * TILE_SIZE + threadIdx.x]);
        B_shared[threadIdx.y][threadIdx.x] = __ldg(&B[(i * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + threadIdx.x]);

        __syncthreads();


        for(int j = 0; j<TILE_SIZE;j++){
            C[row * dimension + blockIdx.x * TILE_SIZE + threadIdx.x] += A_shared[threadIdx.y][j] * B_shared[j][threadIdx.x];
        }


}

}




void printMatrix(int* mat) {
    for (int i = 0; i < dimension; i++) {
        for (int j = 0; j < dimension; j++)
            std::cout << mat[i * dimension + j] << " ";
        std::cout << std::endl;
    }
    std::cout << std::endl;
}




int main() {
    int *matrixA = new int[dimension*dimension];
    int *matrixB = new int[dimension*dimension];
    int *result = new int[dimension*dimension];
    int *device_matrixA;
    int *device_matrixB;
    int *device_matrixC;

    CUDA_CHECK(cudaMalloc(&device_matrixA, sizeof(int)*dimension*dimension));
    CUDA_CHECK(cudaMalloc(&device_matrixB, sizeof(int)*dimension*dimension));
    CUDA_CHECK(cudaMalloc(&device_matrixC, sizeof(int)*dimension*dimension));
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<int> int_dist(1, 10);

    for(int i=0; i<(dimension*dimension);i++){
        matrixA[i]=int_dist(gen);
        matrixB[i]=int_dist(gen);
    }
    CUDA_CHECK(cudaMemcpy(device_matrixA, matrixA, sizeof(int)*dimension*dimension, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(device_matrixB, matrixB, sizeof(int)*dimension*dimension, cudaMemcpyHostToDevice));

    dim3 blockDim(TILE_SIZE, TILE_SIZE, 1);
    dim3 gridDim(dimension/TILE_SIZE, dimension/TILE_SIZE, 1);
    shared_memory_with_warp_matrix<<<gridDim, blockDim>>>(device_matrixA, device_matrixB, device_matrixC);
    shared_memory_matrix<<<gridDim, blockDim>>>(device_matrixA, device_matrixB, device_matrixC);
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaMemcpy(result, device_matrixC, sizeof(int)*dimension*dimension, cudaMemcpyDeviceToHost));

    // std::cout << "Matrix A:" << std::endl;
    // printMatrix(matrixA);
    // std::cout << "Matrix B:" << std::endl;
    // printMatrix(matrixB);
    // std::cout << "Result:" << std::endl;
    // printMatrix(result);

    delete[] matrixA;
    delete[] matrixB;
    delete[] result;
    CUDA_CHECK(cudaFree(device_matrixA));
    CUDA_CHECK(cudaFree(device_matrixB));
    CUDA_CHECK(cudaFree(device_matrixC));
    return 0;
}
