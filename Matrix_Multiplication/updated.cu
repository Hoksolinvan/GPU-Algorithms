
void printMatrix(int* mat) {
    for (int i = 0; i < dimension; i++) {
        for (int j = 0; j < dimension; j++)
            std::cout << mat[i * dimension + j] << " ";
        std::cout << std::endl;
    }
    std::cout << std::endl;
}

#define tx threadIdx.x


__global__ void shared_memory_matrix(const int* A, const int* B, int* C){

    __shared__ int A_shared[TILE_SIZE][TILE_SIZE];
    __shared__ int B_shared[TILE_SIZE][TILE_SIZE];

    int result[TILE_SIZE] = {0};

    int row = blockIdx.y * TILE_SIZE + threadIdx.y;
    int col = blockIdx.x * TILE_SIZE + threadIdx.x;


    for(int i=0; i<dimension/TILE_SIZE;i++){
        

        // for (int j = 0; j < TILE_SIZE; j++) {
        A_shared[threadIdx.y][threadIdx.x] =A[row * dimension + i * TILE_SIZE + threadIdx.x];
        //}

       
       // for (int j = 0; j < TILE_SIZE; j++) {
        B_shared[threadIdx.y][threadIdx.x] =B[(i * TILE_SIZE + threadIdx.y) * dimension + blockIdx.x * TILE_SIZE + threadIdx.x];
        //}


        // synchronizes entire thread block
        __syncthreads();


        // each thread handle 1 row. Therefore, if our tile is 4x4 then we have four threads
        
       if(!(threadIdx.x % TILE_SIZE) ){
        int temp[TILE_SIZE] = {0};

        // load current row based on thread and all that
        
        for(int j=0; j<TILE_SIZE;j++){
            temp[j] = A_shared[threadIdx.y][j];
        }

        

        for(int j=0; j<TILE_SIZE;j++){

            for(int k=0; k<TILE_SIZE;k++){
                result[j] += temp[k] * B_shared[k][j];
            }
           
      }

        }
    }


    if(!(threadIdx.x % TILE_SIZE)){
    for(int i=0; i < TILE_SIZE; i++){
      int cur_row = blockIdx.y * TILE_SIZE + threadIdx.y;
        int cur_col = blockIdx.x * TILE_SIZE + i;

        C[cur_row * dimension + cur_col] = result[i];
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
