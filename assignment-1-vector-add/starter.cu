#include <wb.h>

#define wbCheck(stmt)                                                     \
  do {                                                                    \
    cudaError_t err = stmt;                                               \
    if (err != cudaSuccess) {                                             \
      wbLog(ERROR, "Failed to run stmt ", #stmt);                         \
      wbLog(ERROR, "Got CUDA error ...  ", cudaGetErrorString(err));      \
      return -1;                                                          \
    }                                                                     \
  } while (0)

void printme(float *in1, float* in2, float *in3, int len)
{
	for (int i = 0; i < len; i++)
	{
		wbLog(TRACE, in1[i], " ",in2[i] ," " ,in3[i]);
	}
}



__global__ void vecAdd(float *in1, float *in2, float *out, int len) {
  //@@ Insert code to implement vector addition here
	//return; 
        for (int i = (blockIdx.x * blockDim.x) + threadIdx.x; i < len; i+= blockDim.x)
	{
		out[i] = in1[i] + in2[i];
	}
}

int main(int argc, char **argv) {
  wbArg_t args;
  int inputLength;
  float *hostInput1;
  float *hostInput2;
  float *hostOutput;
  float *deviceInput1;
  float *deviceInput2;
  float *deviceOutput;

  args = wbArg_read(argc, argv);

  wbTime_start(Generic, "Importing data and creating memory on host");
  hostInput1 =
      (float *)wbImport(wbArg_getInputFile(args, 0), &inputLength);
  hostInput2 =
      (float *)wbImport(wbArg_getInputFile(args, 1), &inputLength);
  hostOutput = (float *)malloc(inputLength * sizeof(float));
  wbTime_stop(Generic, "Importing data and creating memory on host");

  wbLog(TRACE, "The input length is ", inputLength);

  wbTime_start(GPU, "Allocating GPU memory.");
  //@@ Allocate GPU memory here
	cudaMalloc(&deviceInput1,(int)(inputLength * sizeof(float)));
	cudaMalloc(&deviceInput2,(int) (sizeof(float) *  inputLength));
	cudaMalloc(&deviceOutput,(int)(sizeof(float) *  inputLength));	

 wbLog(TRACE, "DONE GPU MEM ALLOC");
  wbTime_stop(GPU, "Allocating GPU memory.");

  wbTime_start(GPU, "Copying input memory to the GPU.");
  //@@ Copy memory to the GPU here
	cudaMemcpy(deviceInput1, hostInput1, sizeof(float) * inputLength, cudaMemcpyHostToDevice);
	cudaMemcpy(deviceInput2, hostInput2, sizeof(float) * inputLength, cudaMemcpyHostToDevice);

  wbTime_stop(GPU, "Copying input memory to the GPU.");

  //@@ Initialize the grid and block dimensions here
	int num_threads = 32;
	int num_blocks = 2;	

  wbTime_start(Compute, "Performing CUDA computation");
  //@@ Launch the GPU Kernel here
	vecAdd<<<num_threads, num_blocks>>>(deviceInput1,deviceInput2, deviceOutput, inputLength);

  cudaDeviceSynchronize();
  wbTime_stop(Compute, "Performing CUDA computation");

	wbLog(TRACE,"Done running kernel atleast");
  wbTime_start(Copy, "Copying output memory to the CPU");
  //@@ Copy the GPU memory back to the CPU here
	cudaMemcpy(hostOutput, deviceOutput, sizeof(float) * inputLength, cudaMemcpyDeviceToHost);
  wbTime_stop(Copy, "Copying output memory to the CPU");

  wbTime_start(GPU, "Freeing GPU Memory");
  //@@ Free the GPU memory here
	cudaFree(deviceInput1);
	cudaFree(deviceInput2);
	cudaFree(deviceOutput);
  wbTime_stop(GPU, "Freeing GPU Memory");


	printme(hostInput1, hostInput2, hostOutput, inputLength);
  wbSolution(args, hostOutput, inputLength);

  free(hostInput1);
  free(hostInput2);
  free(hostOutput);

  return 0;
}
