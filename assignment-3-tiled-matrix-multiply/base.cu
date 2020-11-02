
#include <wb.h>

using namespace std;

#define wbCheck(stmt)                                                     \\
  do {                                                                    \\
    cudaError_t err = stmt;                                               \\
    if (err != cudaSuccess) {                                             \\
      wbLog(ERROR, "Failed to run stmt ", #stmt);                         \\
      wbLog(ERROR, "Got CUDA error ...  ", cudaGetErrorString(err));      \\
      return -1;                                                          \\
    }                                                                     \\
  } while (0)

// Compute C = A * B
__global__ void matrixMultiply(float *A, float *B, float *C, int numARows,
                               int numAColumns, int numBRows,
                               int numBColumns, int numCRows,
                               int numCColumns) {
  //@@ Insert code to implement matrix multiplication here

  for (int i = (blockIdx.x * blockDim.x) + threadIdx.x; i < numCRows * numCColumns; i += blockDim.x) {
    int aindex = ((int)(i / numCColumns)) * numAColumns;
    int bindex = (i % numCColumns); 
    float sum = 0;

    for (int j = 0; j < numAColumns; j++) {
      sum += A[aindex] * B[bindex];
      aindex += 1;
      bindex += numBColumns;      
    }

    C[i] = sum;

  }
}

int main(int argc, char **argv) {
  wbArg_t args;
  float *hostA; // The A matrix
  float *hostB; // The B matrix
  float *hostC; // The output C matrix
  float *deviceA;
  float *deviceB;
  float *deviceC;
  int numARows;    // number of rows in the matrix A
  int numAColumns; // number of columns in the matrix A
  int numBRows;    // number of rows in the matrix B
  int numBColumns; // number of columns in the matrix B
  int numCRows;    // number of rows in the matrix C (you have to set this)
  int numCColumns; // number of columns in the matrix C (you have to set
                   // this)

  args = wbArg_read(argc, argv);

  wbTime_start(Generic, "Importing data and creating memory on host");
  hostA = (float *)wbImport(wbArg_getInputFile(args, 0), &numARows,
                            &numAColumns);
  hostB = (float *)wbImport(wbArg_getInputFile(args, 1), &numBRows,
                            &numBColumns);

  //@@ Set numCRows and numCColumns
  numCRows = 0;
  numCColumns = 0;
  numCRows = (numAColumns == numBRows) * numARows;
  numCColumns = numBColumns;

  if (numCRows == 0 || numCColumns == 0) {
    cerr << "Not valid C matrix" << endl;
    exit(1);
  }

  //@@ Allocate the hostC matrix
  hostC = (float*)malloc(sizeof(float) * numCRows * numCColumns); 
  //hostC = new float[numCRows * numCColumns];
  //hostC.reserve(numCRows * numCColumns);

  wbTime_stop(Generic, "Importing data and creating memory on host");
  wbLog(TRACE, "The dimensions of A are ", numARows, " x ", numAColumns);
  wbLog(TRACE, "The dimensions of B are ", numBRows, " x ", numBColumns);
  wbTime_start(GPU, "Allocating GPU memory.");

  //@@ Allocate GPU memory here
  cudaMalloc(&deviceA, sizeof(float) * numARows * numAColumns);
  cudaMalloc(&deviceB, sizeof(float) * numBRows * numBColumns);
  cudaMalloc(&deviceC, sizeof(float) * numCRows * numCColumns);  

  wbTime_stop(GPU, "Allocating GPU memory.");
  wbTime_start(GPU, "Copying input memory to the GPU.");

  //@@ Copy memory to the GPU here
  cudaMemcpy(deviceA, hostA, sizeof(float) * numARows * numAColumns, cudaMemcpyHostToDevice);
  cudaMemcpy(deviceB, hostB, sizeof(float) * numBRows * numBColumns, cudaMemcpyHostToDevice);

  wbTime_stop(GPU, "Copying input memory to the GPU.");

  //@@ Initialize the grid and block dimensions here
  
  wbTime_start(Compute, "Performing CUDA computation");

  //@@ Launch the GPU Kernel here
  matrixMultiply<<<256,1>>>(deviceA, deviceB, deviceC,
  numARows, numAColumns, numBRows, numBColumns, numCRows, numCColumns);

  cudaDeviceSynchronize();

  wbTime_stop(Compute, "Performing CUDA computation");
  wbTime_start(Copy, "Copying output memory to the CPU");

  //@@ Copy the GPU memory back to the CPU here
  cudaMemcpy(hostC, deviceC, sizeof(float) * numCRows * numCColumns, cudaMemcpyDeviceToHost);

  wbTime_stop(Copy, "Copying output memory to the CPU");
  wbTime_start(GPU, "Freeing GPU Memory");

  wbLog(TRACE, "C[0] IS ", hostC[0]);

  //@@ Free the GPU memory here
  cudaFree(deviceA);
  cudaFree(deviceB);
  cudaFree(deviceC);

  wbTime_stop(GPU, "Freeing GPU Memory");
  wbSolution(args, hostC, numCRows, numCColumns);

  free(hostA);
  free(hostB);
  free(hostC);

  return 0;
}
