// Histogram Equalization

#include <wb.h>

#define HISTOGRAM_LENGTH 256
//TESTING UPDATES BITCH

//@@ insert code here


__global__
void cast(float* outputchar, 
	float* inputfloat, 
	int imageWidth, 
	int imageHeight, 
	int imageChannels)
{
	/*	for (int i = 0; i< 1000; i++) 
{
	outputchar[i] = (unsigned char)('c');
}*/
	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
  
	for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x * gridDim.x)
	{
	  outputchar[i] = (unsigned char)((int)(255 * (inputfloat[i])));
          //outputchar[i] = temp;
	  //outputchar[i] = 'c';
  }

  for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x * gridDim.x)
  {
    inputfloat[i] = (float)((outputchar[i] / 255.0f));
          //outputchar[i] = temp;
    //outputchar[i] = 'c';
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
  //alloc mem and dimensions
  float* cudaInputImageData;
  float* cudaOutputImageData;
  float* cudaTemp2ImageData;
  unsigned char* testingChar;
  testingChar = (unsigned char*)malloc(sizeof(unsigned char) * imageHeight * imageWidth * imageChannels);
  cudaMalloc(&cudaInputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaTemp2ImageData, (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));
  cudaMemcpy(cudaInputImageData, hostInputImageData, 
  	(int)(sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyHostToDevice);

  //send data to kernel
  imageHeight = 10;
  imageWidth = 10;
  imageChannels = 3;
  cast<<<256,256>>>(cudaTemp2ImageData, cudaInputImageData, 
        imageWidth, imageHeight, imageChannels);

  
  cudaDeviceSynchronize();

  
  //Retrieve output image data
  cudaMemcpy(testingChar, cudaTemp2ImageData,
         (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  cudaMemcpy(hostInputImageData, cudaInputImageData,
         (sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  
  wbLog(TRACE, "output is ");
  for (int i = 0; i < 20; i++)
  {
	   unsigned char temp = testingChar[i]
      wbLog(TRACE, hostInputImageData[i], " ", temp);
    
  }
  
 outputImage = wbImage_new(imageWidth, imageHeight, imageChannels, hostOutputImageData);
 wbSolution(args, outputImage);

  //@@ insert code here
  cudaFree(cudaInputImageData);
  cudaFree(cudaTemp2ImageData);
  free(hostInputImageData);
  free(testingChar);  
  
  return 0;

}

