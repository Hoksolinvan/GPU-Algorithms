#include <iostream>
#include <cuda_runtime.h>
#include <random>



#define TILE_SIZE 4
#define dimension 24

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

    // int row = blockIdx.y * TILE_SIZE + threadIdx.y;

    


    for(int i=0; i<dimension/TILE_SIZE;i++){
        

        // for (int j = 0; j < TILE_SIZE; j++) {
        A_shared[threadIdx.y][threadIdx.x] = (A[(blockIdx.y * TILE_SIZE + threadIdx.y) * dimension + i * TILE_SIZE + threadIdx.x]);
        //}

       
       // for (int j = 0; j < TILE_SIZE; j++) {
        B_shared[threadIdx.y][threadIdx.x] = (B[(i * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + threadIdx.x]);
        //}


        // synchronizes entire thread block
        __syncthreads();


        // each thread handle 1 row. Therefore, if our tile is 4x4 then we have four threads
        
        int term = 0;

      
        for(int j = 0; j<TILE_SIZE;j++){

            term = A_shared[threadIdx.y][threadIdx.x] * B_shared[threadIdx.x][j];

            for(int k=TILE_SIZE/2; k >= 1 ; k/=2){


                term +=__shfl_down_sync(__activemask(),term,k,TILE_SIZE);
               // C[row * dimension + blockIdx.x * TILE_SIZE + threadIdx.x] += term;
            }

            
            if (threadIdx.x == 0) {
                  acc[j] += term;
            }

            // if(threadIdx.x == 0){
            //     C[row * dimension + blockIdx.x * TILE_SIZE + j] += term;
            // }
            
        }

     
        
    }



    if (threadIdx.x == 0) {
        for (int j = 0; j < TILE_SIZE; j++) {
            C[(blockIdx.y * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + j] = acc[j];
        }
    }


}





// __global__ void shared_memory_with_warp_matrix_second(const int* A, const int* B, int* C){

//     __shared__ int A_shared[TILE_SIZE][TILE_SIZE];
//     __shared__ int B_shared[TILE_SIZE][TILE_SIZE];


//     int acc[TILE_SIZE] = {0};

//     int row = blockIdx.y * TILE_SIZE + threadIdx.y;

//     cg::thread_block block = cg::this_thread_block();
//     cg::thread_block_tile<TILE_SIZE> tile = cg::tiled_partition<TILE_SIZE>(block);


//     for(int i=0; i<dimension/TILE_SIZE;i++){
        

//         A_shared[threadIdx.y][threadIdx.x] = __ldg(&A[row * dimension + i * TILE_SIZE + threadIdx.x]);
//         B_shared[threadIdx.y][threadIdx.x] = __ldg(&B[(i * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + threadIdx.x]);



//         block.sync();


        
//         int term = 0;

//         for(int j = 0; j<TILE_SIZE;j++){
            
//             term = A_shared[threadIdx.y][threadIdx.x] * B_shared[threadIdx.x][j];

//             term = cg::reduce(tile, term, cg::plus<int>());
            


//             if (tile.thread_rank() == 0) {
//                acc[j] += term;
//             }
            
//         }


     
        
//     }

//     if (tile.thread_rank() == 0) {
//         for(int j = 0; j<TILE_SIZE;j++){
//             C[row * dimension + blockIdx.x * TILE_SIZE + j] = acc[j];
//         }
//     }
    



// }

#define INNER_TILE_SIZE 2
__global__ void shared_memory_1D_matrix(const int* A, const int* B, int* C){

    
    __shared__ int A_shared[TILE_SIZE][INNER_TILE_SIZE];
    __shared__ int B_shared[INNER_TILE_SIZE][TILE_SIZE];

    int threadRow = threadIdx.y;
    int threadCol = threadIdx.x;

    int blockRow = blockIdx.y * TILE_SIZE;
    int blockCol = blockIdx.x * TILE_SIZE;

    int threadResult[INNER_TILE_SIZE] = {0};


    int totalThreadCount = blockDim.x * blockDim.y;
    int threadId = threadIdx.y * blockDim.x + threadIdx.x;


    


    for(int i=0; i<dimension/INNER_TILE_SIZE; i++){

        for(int loader = threadId; loader < TILE_SIZE * INNER_TILE_SIZE; loader += totalThreadCount){
            int row = loader / INNER_TILE_SIZE;
            int col = loader % INNER_TILE_SIZE;

            A_shared[row][col] = A[(blockRow + row) * dimension + (i * INNER_TILE_SIZE + col)];
        }

        for(int loader = threadId; loader < TILE_SIZE * INNER_TILE_SIZE; loader += totalThreadCount){
            int row = loader / TILE_SIZE;
            int col = loader % TILE_SIZE;

            B_shared[row][col] = B[(i * INNER_TILE_SIZE + row) * dimension + (blockCol + col)];
        }

        __syncthreads();


        for (int k = 0; k < INNER_TILE_SIZE; k++) {
            int temp = B_shared[k][threadCol];
            for (int v = 0; v < INNER_TILE_SIZE; v++) {
                threadResult[v] += A_shared[threadRow * INNER_TILE_SIZE + v][k] * temp;
            }
        }


    }


    
for (int v = 0; v < INNER_TILE_SIZE; v++) {
    int row = blockRow + threadRow * INNER_TILE_SIZE + v;
    int col = blockCol + threadCol;
    C[row * dimension + col] = threadResult[v];
}


}



__global__ void shared_memory_matrix(const int* A, const int* B, int* C){

    
    __shared__ int A_shared[TILE_SIZE][TILE_SIZE];
    __shared__ int B_shared[TILE_SIZE][TILE_SIZE];


   // int row = blockIdx.y * TILE_SIZE + threadIdx.y;



    for(int i=0; i<dimension/TILE_SIZE;i++){
        

        A_shared[threadIdx.y][threadIdx.x] = A[(blockIdx.y * TILE_SIZE + threadIdx.y) * dimension + i * TILE_SIZE + threadIdx.x];
        B_shared[threadIdx.y][threadIdx.x] = B[(i * TILE_SIZE + threadIdx.y) * dimension  + blockIdx.x * TILE_SIZE + threadIdx.x];

        __syncthreads();
        
        for(int j = 0; j<TILE_SIZE;j++){
            C[(blockIdx.y * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + threadIdx.x] += A_shared[threadIdx.y][j] * B_shared[j][threadIdx.x];
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
    // shared_memory_with_warp_matrix<<<gridDim, blockDim>>>(device_matrixA, device_matrixB, device_matrixC);
    shared_memory_matrix<<<gridDim, blockDim>>>(device_matrixA, device_matrixB, device_matrixC);


    dim3 block(TILE_SIZE,  TILE_SIZE/ INNER_TILE_SIZE);
dim3 grid(dimension/TILE_SIZE, dimension/TILE_SIZE);

shared_memory_1D_matrix<<<grid, block>>>(device_matrixA, device_matrixB, device_matrixC);
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaMemcpy(result, device_matrixC, sizeof(int)*dimension*dimension, cudaMemcpyDeviceToHost));

    std::cout << "Matrix A:" << std::endl;
    printMatrix(matrixA);
    std::cout << "Matrix B:" << std::endl;
    printMatrix(matrixB);
    std::cout << "Result:" << std::endl;
    printMatrix(result);

    delete[] matrixA;
    delete[] matrixB;
    delete[] result;
    CUDA_CHECK(cudaFree(device_matrixA));
    CUDA_CHECK(cudaFree(device_matrixB));
    CUDA_CHECK(cudaFree(device_matrixC));
    return 0;
}
