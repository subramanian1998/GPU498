// Histogram Equalization

#include <wb.h>

#define HISTOGRAM_LENGTH 256
//TESTING UPDATES BITCH

//@@ insert code here


__global__
void cast(unsigned char* outputchar, 
	float* inputfloat, 
  float* outputfloat,
	int imageWidth, 
	int imageHeight, 
	int imageChannels, 
  int direction)
{
	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 

  if (direction == 1)
  {
    for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x * gridDim.x)
    {
      outputchar[i] = (unsigned char)((255 * (inputfloat[i])));
    }

    __syncthreads();
  }
  
	else {
    for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x * gridDim.x)
    {
      inputfloat[i] = (float)((outputchar[i] / 255.0f));

    }
  }

}



int main(int argc, char **argv) 
{
  wbArg_t args;
  int imageWidth;
  int imageHeight;
  int imageChannels;
  wbImage_t inputImage;
  wbImage_t outputImage;
  float* hostInputImageData;
  float* hostOutputImageData;
  const char *inputImageFile;

  //@@ Insert more code here
  //ANY SETUP IF NEED BE??
  
  

  args = wbArg_read(argc, argv); /* parse the input arguments */

  inputImageFile = wbArg_getInputFile(args, 0);

  wbTime_start(Generic, "Importing data and creating memory on host");
  inputImage = wbImport(inputImageFile);
  imageWidth = wbImage_getWidth(inputImage);
  imageHeight = wbImage_getHeight(inputImage);
  imageChannels = wbImage_getChannels(inputImage);
  
  wbTime_stop(Generic, "Importing data and creating memory on host");

  //@@ insert code here

  //get pointers to input and output images
  hostInputImageData = (float *)malloc(imageWidth * imageHeight * imageChannels * sizeof(float));
  hostInputImageData = wbImage_getData(inputImage);
  hostOutputImageData = (float *)malloc(imageWidth * imageHeight * imageChannels * sizeof(float));
  //alloc mem and dimensions
  float* cudaInputImageData;
  float* cudaOutputImageData;
  float* cudaTempImageData;
  unsigned char* cudaTemp2ImageData;
  unsigned char* testingChar;
  unsigned char* confirmedChar;
  testingChar = (unsigned char*)malloc(sizeof(unsigned char) * imageHeight * imageWidth * imageChannels);
  confirmedChar = (unsigned char*)malloc(sizeof(unsigned char) * imageHeight * imageWidth * imageChannels);
  cudaMalloc(&cudaInputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaTempImageData, (sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaTemp2ImageData, (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));
  cudaMemcpy(cudaInputImageData, hostInputImageData, 
  	(int)(sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyHostToDevice);

  for (int i = 0; i < imageChannels * imageHeight * imageWidth; i++ )
  {
    confirmedChar[i] = (unsigned char)(255 * (hostInputImageData[i]));
  }
  //wbLog(TRACE, "output is ", testingChar[0], ' ', (unsigned char)(255 * hostInputImageData[0]) );


  //send data to kernel
  cast<<<256,256>>>(cudaTemp2ImageData, cudaInputImageData, cudaTempImageData,
        imageWidth, imageHeight, imageChannels);

  
  cudaDeviceSynchronize();

  
  //Retrieve output image data
  cudaMemcpy(testingChar, cudaTemp2ImageData,
         (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  cudaMemcpy(hostOutputImageData, cudaTempImageData,
         (sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  
  /*
  wbLog(TRACE, "output is ");
  for (int i = 0; i < 20; i++)
  {
	   unsigned char temp = testingChar[i];
     wbLog(TRACE, "char" , confirmedChar[i], " ", temp);
     wbLog(TRACE, "float" , hostInputImageData[i] , " ", hostOutputImageData[i]);
  }
  */


 outputImage = wbImage_new(imageWidth, imageHeight, imageChannels, hostOutputImageData);
 wbSolution(args, outputImage);

  //@@ insert code here
  cudaFree(cudaInputImageData);
  cudaFree(cudaTemp2ImageData);
  free(hostInputImageData);
  free(hostOutputImageData);
  free(testingChar);  
  
  return 0;

}

