#include <iostream>
#include <cuda_runtime.h>
#include <random>

#define TILE_SIZE 16
#define dimension 32

__global__ void matmult(int* A, int* B, int* C){

    __shared__ int As[TILE_SIZE][TILE_SIZE];
    __shared__ int Bs[TILE_SIZE][TILE_SIZE];
    int row = blockIdx.y * TILE_SIZE + threadIdx.y;
    int col = blockIdx.x * TILE_SIZE + threadIdx.x;
    int sum = 0;

    for (int t = 0; t < dimension / TILE_SIZE; t++) {
        As[threadIdx.y][threadIdx.x] = A[row * dimension + t * TILE_SIZE + threadIdx.x];
        Bs[threadIdx.y][threadIdx.x] = B[(t * TILE_SIZE + threadIdx.y) * dimension + col];
        __syncthreads();  
        for (int k = 0; k < TILE_SIZE; k++)
            sum += As[threadIdx.y][k] * Bs[k][threadIdx.x];
        __syncthreads();  
    }
    C[row * dimension + col] = sum;
    return;
}


__global__ void matmultsingle(int* A, int* B, int* C, int y_offset,int x_offset){
  __shared__ int As[TILE_SIZE][TILE_SIZE];
  __shared__ int Bs[TILE_SIZE][TILE_SIZE];

  int row = y_offset * TILE_SIZE + threadIdx.y;
  int col = x_offset * TILE_SIZE + threadIdx.x;
  int sum = 0;

  
  for(int t= 0; t < dimension/TILE_SIZE; t++){
    As[threadIdx.y][threadIdx.x] = A[row*dimension + t*TILE_SIZE + threadIdx.x];
    Bs[threadIdx.y][threadIdx.x] = B[(t*TILE_SIZE+threadIdx.y) * dimension+col];
   // Bs[threadIdx.y][threadIdx.x] = B[row*dimension+t*TILE_SIZE+threadIdx.x];
    __syncthreads();
    for(int k=0; k<TILE_SIZE; k++){
      sum+= As[threadIdx.y][k] * Bs[k][threadIdx.x];
    }
    __syncthreads();
  }


  C[row * dimension + col] = sum;
  return;
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
    matmult<<<gridDim, blockDim>>>(device_matrixA, device_matrixB, device_matrixC);
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
