// Histogram Equalization

#include <wb.h>

#define HISTOGRAM_LENGTH 256
//TESTING UPDATES BITCH

//@@ insert code here

__device__ inline void atomicAdd2(float* address, float value)

{

  float old = value;  

  float new_old;

do

  {

  new_old = atomicExch(address, 0.0f);

  new_old += old;

  }

  while ((old = atomicExch(address, new_old))!=0.0f);

};

__device__
void cast(unsigned char* outputchar, 
	float* inputfloat, 
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

__global__ 
void grayify(float* outputgray, 
  float* inputrgb, 
  float* hist,
  unsigned char* outputchar,
  int imageWidth, 
  int imageHeight, 
  int imageChannels)
{

  cast(outputchar, inputrgb, imageWidth, imageHeight, imageChannels, 1);
  
  __syncthreads();

  int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
  

  //ONLY 1/3 of image and 3x small images
  //Casting not working
  for (int x = tidx; x < (imageWidth * imageHeight); x += blockDim.x)
  {
    int col = (x) % imageWidth;
    int row = (x) / imageWidth;
    int ii = (row * imageWidth) + col;
    //float r = inputchar[imageChannels * ii] / 255.0 ;
    //float g = inputchar[(imageChannels * ii) + 1]/ 255.0;
    //float b = inputchar[(imageChannels * ii) + 2] / 255.0;
    unsigned char r = (unsigned char)(0.21 * inputchar[imageChannels * ii]);
    unsigned char g =  (unsigned char)(0.71 * inputchar[(imageChannels * ii) + 1]);
    unsigned char b = (unsigned char)(0.07 * inputchar[(imageChannels * ii) + 2]) ;
    //unsigned char temp = (unsigned char)(255.0 *((unsigned char)(0.21*r) + (unsigned char)(0.71*g) + (unsigned char)(0.07*b)));
    for (int i = 0 ; i <imageChannels;i++)
    {
      //outputgray[(imageChannels * ii) + i] = (float) ((0.21*r) + (0.71*g) + (0.07*b));
      outputchar[(imageChannels * ii) + i] = (unsigned char)(r + g + b);
    }
  }
        
  cast(outputchar, outputgray, imageWidth, imageHeight, imageChannels, 2);
  

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
  unsigned char* cudaChar;
  float* cudaHist;
  float* hostHist;
  hostHist = (float *)malloc(256 * sizeof(float));
  //unsigned char* testingChar;
  //unsigned char* confirmedChar;
  //testingChar = (unsigned char*)malloc(sizeof(unsigned char) * imageHeight * imageWidth * imageChannels);
  //confirmedChar = (unsigned char*)malloc(sizeof(unsigned char) * imageHeight * imageWidth * imageChannels);
  cudaMalloc(&cudaInputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaOutputImageData, (sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaHist, (sizeof(float) * 256));
  cudaMalloc(&cudaChar, (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));
  cudaMemcpy(cudaInputImageData, hostInputImageData, 
  	(int)(sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyHostToDevice);

  /*
  for (int i = 0; i < imageChannels * imageHeight * imageWidth; i++ )
  {
    confirmedChar[i] = (unsigned char)(255 * (hostInputImageData[i]));
  }
  */
  //wbLog(TRACE, "output is ", testingChar[0], ' ', (unsigned char)(255 * hostInputImageData[0]) );


  //send data to kernel
  cast<<<256,256>>>(cudaOutputImageData, cudaInputImageData, cudaHist, cudaChar,
        imageWidth, imageHeight, imageChannels);

  
  cudaDeviceSynchronize();

  
  //Retrieve output image data
  cudaMemcpy(testingChar, cudaChar,
         (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  cudaMemcpy(hostOutputImageData, cudaOutputImageData,
         (sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  cudaMemcpy(hostHist, cudaHist,
         (sizeof(float) * 256), cudaMemcpyDeviceToHost);
  
  
  wbLog(TRACE, "output is ");
  for (int i = 0; i < 20; i++)
  {
	   //unsigned char temp = testingChar[i];
     //wbLog(TRACE, "char" , confirmedChar[i], " ", temp);
     wbLog(TRACE, "float" , hostInputImageData[i] , " ", hostOutputImageData[i]);
  }
  


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

