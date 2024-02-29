#include <iostream>

#include <cuda_runtime.h>   //for CUDA runtime API
#include <helper_cuda.h>    //for checkCudaError macro
#include <helper_timer.h>   //for CUDA SDK timers

//#define XBD 512 //x-dimension of thread blocks
//#define YBD 2   //y-dimension of thread blocks



//simple CPU implementation of matrix-matrix product
void cpuMatrixProduct(int m, int k, int n, const float *A, const float *B, float *C) {
    //auxiliary variables
    int index_m;
    int index_k;
    int index_n;

    for(index_m=0; index_m<m; index_m++) {  //TODO: check which is the best order of the three nested loops.
        for(index_k=0; index_k<k; index_k++) {
            for(index_n=0; index_n<n; index_n++) {
                C[index_m*n + index_n] += A[index_m*k + index_k] * B[index_k*n + index_n];

            }

        }

    }

}



//GPU implementation of matrix-matrix product
//In this version, we use a block of threads for each block of rows of matrix C (and of matrix A) --> all threads work on entire matrix B.
__global__ void gpuMatrixProduct(int m, int k, int n, const float *A, const float *B, float *C) {
    //auxiiary variables
    int index_k;    //index_k is a pure loop index.
    int tid_x = threadIdx.x;
    int tid_y = threadIdx.y;
    int row = tid_y + blockIdx.x * blockDim.y;
    if(row >= m)  return; //case in which thread indexes exceed matrix C dimensions

    //use of shared memory in order to make faster matrix A accesses
    extern __shared__ float aux[];
    //initialization of shared memory
    for(tid_x = threadIdx.x; tid_x<k; tid_x += blockDim.x) {
        aux[tid_x+tid_y*k] = A[tid_x+row*k];
    }
    __syncthreads();

    //matrix matrix product
    for(tid_x = threadIdx.x; tid_x<n; tid_x += blockDim.x) {
        for(index_k=0; index_k<k; index_k++) {
            C[tid_x+row*n] += aux[index_k+tid_y*k] * B[tid_x+index_k*n];
        }

    }

}



int main(int argc, char **argv) {
    //auxiliary variables
    int row;    //row & col are used as indexes loop
    int col;
    int idx;    //matrix index (= row*ncols + col)

    if(argc < 7) {
        fprintf(stderr, "Usage: %s m k n exec_on_cpu XBD YBD\n", argv[0]);
        return -1;
    }

    int m = atoi(argv[1]);
    int k = atoi(argv[2]);
    int n = atoi(argv[3]);
    char *exec_cpu = argv[4];
    
    int XBD = atoi(argv[5]);
    int YBD = atoi(argv[6]);

    //HOST MEMORY INITIALIZATION
    float *h_A = new float[m*k];    //matrix A
    float *h_B = new float[k*n];    //matrix B
    float *h_C = new float[m*n];    //matrix C
    float *h_C_d = new float[m*n];  //output (matrix C) copied from device memory

    srand(123456);  //seed
    for(row=0; row<m; row++) {  //matrix A initialization
        for(col=0; col<k; col++) {
            idx = row*k + col;
            h_A[idx] = 100.0f * static_cast<float>(rand()) / RAND_MAX;

        }

    }
    for(row=0; row<k; row++) {  //matrix B initialization
        for(col=0; col<n; col++) {
            idx = row*n + col;
            h_B[idx] = 100.0f * static_cast<float>(rand()) / RAND_MAX;

        }

    }
    for(row=0; row<m; row++) {  //matrix C initialization
        for(col=0; col<n; col++) {
            idx = row*n + col;
            h_C[idx] = 100.0f * static_cast<float>(rand()) / RAND_MAX;

        }

    }

    //std::cout << "Test case: m=" << m << ", k=" << k << ", n=" << n << std::endl;

    //DEVICE MEMORY INITIALIZATION
    float *d_A; //matrix A
    float *d_B; //matrix B
    float *d_C; //matrix C

    checkCudaErrors(cudaMalloc((void **) &d_A, m*k*sizeof(float)));
    checkCudaErrors(cudaMalloc((void **) &d_B, k*n*sizeof(float)));
    checkCudaErrors(cudaMalloc((void **) &d_C, m*n*sizeof(float)));

    //copy matrices from the host (CPU) to the device (GPU)
    checkCudaErrors(cudaMemcpy(d_A, h_A, m*k*sizeof(float), cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(d_B, h_B, k*n*sizeof(float), cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(d_C, h_C, m*n*sizeof(float), cudaMemcpyHostToDevice));

    //CALCULATIONS ON THE CPU - it is useful to check if the calculations on the GPU are correctly made through a comparison of the results.
    float flopCnt = 2.e-6*m*k*n;    //in this case, FLOPS = 2*m*k*n/TIME
    float cpuFlops;
    float gpuFlops;

    //Create the CUDA SDK timer
    StopWatchInterface *timer = 0;
    sdkCreateTimer(&timer);

    if(exec_cpu[0] == 'y') {
        timer->start();
        cpuMatrixProduct(m, k, n, h_A, h_B, h_C);
        timer->stop();

        cpuFlops = flopCnt / timer->getTime();
        std::cout << "\"CPU_time\": " << timer->getTime() << ",  \"CPU_GFLOPS\":" << cpuFlops <<","<<std::endl;
        timer->reset();
    }

    //CALCULATIONS ON THE GPU
    const dim3 BLOCK_DIM(XBD, YBD);
    const dim3 GRID_DIM((m-1+YBD)/YBD); //this way we have the right number of block rows even if m is not multiple of YBD.

    timer->start();
    gpuMatrixProduct<<<GRID_DIM, BLOCK_DIM,k*YBD*sizeof(float)>>>(m, k, n, d_A, d_B, d_C);
    checkCudaErrors(cudaDeviceSynchronize());   //GPU kernel calls are asynchronous: cudaDeviceSynchronize() is useful to take the actual execution time on the GPU before timer->stop().
    timer->stop();

    gpuFlops = flopCnt / timer->getTime();
    std::cout << "\"GPU_time\":" << timer->getTime() << ",  \"GFLOPS\":" << gpuFlops <<std::endl;

    if(exec_cpu[0] == 'y') {
        //download the resulting matrix d_C from the device and store it in h_C_d.
        checkCudaErrors(cudaMemcpy(h_C_d, d_C, m*n*sizeof(float), cudaMemcpyDeviceToHost));

        //now let's check if the results are the same.
        float relativeDiff = 0.0f;
        float diff = 0.0f;
        float maxAbs;

        for(row=0; row<m; row++) {  //comparison between every single entry of h_C with every single entry of h_C_d.
            for(col=0; col<n; col++) {
                idx = row*n + col;

                maxAbs = std::max(std::abs(h_C[idx]), std::abs(h_C_d[idx]));
                if(maxAbs == 0.0)
                    maxAbs = 1.0;
                relativeDiff = std::max(relativeDiff, std:: abs(h_C[idx] - h_C_d[idx])/maxAbs);
                diff = std::max(diff, std::abs(h_C[idx] - h_C_d[idx]));

            }

        }
        //relativeDiff should be as close as possible to unit roundoff.
        //float corresponds to IEEE single precision, so unit roundoff is 1.19e-07.
        std::cout << ",\"Max_diff\":" << diff << ",\"Max_relative_diff\": " << relativeDiff << std::endl;
        std::cout << ",\"SPEED_UP\":" << gpuFlops/cpuFlops << std::endl;
    }

    //CLEANING UP
    delete timer;
    delete[] h_A;
    delete[] h_B;
    delete[] h_C;
    delete[] h_C_d;

    checkCudaErrors(cudaFree(d_A));
    checkCudaErrors(cudaFree(d_B));
    checkCudaErrors(cudaFree(d_C));

    return 0;

}
