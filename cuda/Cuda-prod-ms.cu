#include <cstdio>
#include <iostream>

#include <cuda_runtime.h>   //for CUDA runtime API
#include <helper_cuda.h>    //for checkCudaError macro
#include <helper_timer.h>   //for CUDA SDK timers

#define BD 1024   //x-dimension of thread blocks



//simple CPU implementation of matrix-matrix product
void cpuMatrixProduct(int m, int k, int n, const float *A, const float *B, float *C) {
    //auxiliary variables
    int index_m;
    int index_k;
    int index_n;

    for(index_m=0; index_m<m; index_m++) {
        for(index_k=0; index_k<k; index_k++) {
            for(index_n=0; index_n<n; index_n++) {
                C[index_m*n + index_n] += A[index_m*k + index_k] * B[index_k*n + index_n];

            }

        }

    }

}



__device__ void reduce(volatile float *sdata, int tid) {
    sdata[tid] += sdata[tid+16];
    sdata[tid] += sdata[tid+8];
    sdata[tid] += sdata[tid+4];
    sdata[tid] += sdata[tid+2];
    sdata[tid] += sdata[tid+1];
}



//GPU implementation of matrix-matrix product
//In this version, we use a block of threads foreach matrix C component and we divide A-rows and B-columns between multiple threads belonging to the same block.
__global__ void gpuMatrixProduct(int m, int k, int n, const float *A, const float *B, float *C) {
    //auxiiary variables
    int index_k;    //index_k depends on tid (threadIdx.x); we loop on index_k in order to iterate on a single A-row and on a single B-column.
    int tid = threadIdx.x;
    int c_row = blockIdx.y;
    int c_col = blockIdx.x;
    float t = 0.0;  //partial result of matrix matrix product
    if(c_row >= m || c_col >= n)  return; //case in which thread indexes exceed matrix C dimensions

    //use of shared memory
    extern __shared__ float aux[BD];
    //matrix matrix product
    for(index_k=tid; index_k<k; index_k += blockDim.x) { 
        t += A[index_k+c_row*k] * B[c_col+index_k*n];
    }
    aux[tid] = t;
    __syncthreads();
    //reduction    
    for(int s=BD/2; s>=32; s>>=1) {
        if(tid<s)
            aux[tid] += aux[tid+s];
        __syncthreads();
    }
    if(tid<16)
        reduce(aux, tid);
    //write result to global memory
    if(tid == 0)
        C[c_col+c_row*n] += aux[0];

}



int main(int argc, char **argv) {
    //auxiliary variables
    int row;    //row & col are used as indexes loop
    int col;
    int idx;    //matrix index (= row*ncols + col)

    if(argc < 5) {
        fprintf(stderr, "Usage: %s m k n exec_on_cpu\n", argv[0]);
        return -1;
    }

    int m = atoi(argv[1]);
    int k = atoi(argv[2]);
    int n = atoi(argv[3]);
    char *exec_cpu = argv[4];

    //HOST MEMORY INITIALIZATION
    float *h_A = new float[m*k];    //matrix A
    float *h_B = new float[k*n];    //matrix B
    float *h_C = new float[m*n];    //matrix C
    float *h_C_d = new float[m*n];  //output (matrix C) copied from device memory

    srand(123456);  //seed
    for(row=0; row<m; row++) {  //matrix A initialization
        for(col=0; col<k; col++) {
            idx = row*k + col;
            //h_A[idx] = 100.0f * static_cast<float>(rand()) / RAND_MAX;
            h_A[idx] = 1.0*(idx%10);

        }

    }
    for(row=0; row<k; row++) {  //matrix B initialization
        for(col=0; col<n; col++) {
            idx = row*n + col;
            //h_B[idx] = 100.0f * static_cast<float>(rand()) / RAND_MAX;
            h_B[idx] = 2.0*(idx%10);

        }

    }
    for(row=0; row<m; row++) {  //matrix C initialization
        for(col=0; col<n; col++) {
            idx = row*n + col;
            //h_C[idx] = 100.0f * static_cast<float>(rand()) / RAND_MAX;
            h_C[idx] = 1.0;

        }

    }

    std::cout << "Test case: m=" << m << ", k=" << k << ", n=" << n << std::endl;

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
    const dim3 BLOCK_DIM(BD);
    const dim3 GRID_DIM(n, m); //this way we have one thread-block foreach matrix C component.

    timer->start();
    gpuMatrixProduct<<<GRID_DIM, BLOCK_DIM>>>(m, k, n, d_A, d_B, d_C);
    checkCudaErrors(cudaDeviceSynchronize());   //GPU kernel calls are asynchronous: cudaDeviceSynchronize() is useful to take the actual execution time on the GPU before timer->stop().
    timer->stop();

    gpuFlops = flopCnt / timer->getTime();
    std::cout << "\"GPU_time\": " << timer->getTime() << ",  \"GFLOPS\":" << gpuFlops <<std::endl;

    if(exec_cpu[0] == 'y') {
        //download the resulting matrix d_C from the device and store it in h_C_d.
        checkCudaErrors(cudaMemcpy(h_C_d, d_C, m*n*sizeof(float), cudaMemcpyDeviceToHost));

        //now let's check if the results are the same.
        float relativeDiff = 0.0f;
        float diff = 0.0f;
        float maxAbs;
        int errCount = 0;

        for(row=0; row<m; row++) {  //comparison between every single entry of h_C with every single entry of h_C_d.
            for(col=0; col<n; col++) {
                idx = row*n + col;

                maxAbs = std::max(std::abs(h_C[idx]), std::abs(h_C_d[idx]));
                if(maxAbs == 0.0)
                    maxAbs = 1.0;
                relativeDiff = std::max(relativeDiff, std:: abs(h_C[idx] - h_C_d[idx])/maxAbs);
                diff = std::max(diff, std::abs(h_C[idx] - h_C_d[idx]));

                if(relativeDiff > 0.001)
                    errCount++;

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
