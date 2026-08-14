# Van's Solution

For my solution, I have implemented the GEMM utilizing two methods: **Shared Memory Tiling** and **Shared Memory Tiling with Warp-level primitve**

## Runtime Results

| | Shared Memory Tiling | Shared Memory Tiling with Warp-level primitive |
|---|---|---|
| **Runtime** | ~1.4ms | ~1.7ms |



## Shared Memory Tiling Solution

__ **Description** __

For my shared memory tiling solution I divided the input matrices into submatrices (e.g., given a 1024 x 1024 matrix, I partition it into 16 x 16 smaller matrices), then
for each of these submatrices I configured my ```dim3 gridDim()``` in such a way that would arrange enough thread blocks to each handle the final results for each of the sub
matrices' final results.

Since each thread block handles its own submatrix, the solution makes use of a ```for()``` loop where for each iteration traverses to both the next tile along the 
required row and required columns that are needed to complete the final results. For each output cell, it is managed by its own unique thread. This gave me the opportunity
to coalesce my reads from global memory onto the ```__shared__ buffer[DIMENSION][DIMENSION]``` that I have allocated on the GPU's shmem. 

The values accumulate further and further as it progresses until it reaches its last row and column submatrices required to complete the output and that submatrix completes its operation.


## Shared memory Tiling with Warp-level primitive

__ **Description** __

For my solution that involves warp-level primitives it follows the same procedure as the shared memory tiling solution in that I configured each threadblock to handle each submatrices
and I exploit global memory coalesced reads from and onto my shared memory. However, in this solution I tried to exploit the fast register access (through warp-level operations) instead of just shared memory access as I believed
that it would provide additional speedup (I believe this method is called, "Register level micro-tiling"). After each row is process it performs a warp level ```__shfl_down```  to all threads of the 0th index of each row and stores it into that thread's local int arr[];

When the shfl is completed the threadIdx.x == 0 performs the load from registers and onto global memory.
