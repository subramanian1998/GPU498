// Histogram Equalization

#include <wb.h>

#define HISTOGRAM_LENGTH 256
//TESTING UPDATES BITCH

//@@ insert code here

__device__
unsigned char* cast(unsigned char* outputchar, 
	float* inputfloat, 
	int imageWidth, 
	int imageHeight, 
	int imageChannels)
{
	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
  
	for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x)
	{
		outputchar[i] = (unsigned char)(255 * inputfloat[i]);
	}
  

	return outputchar;
}

__device__
float * decast( float * outputfloat, 
	unsigned char * inputchar, 
	int imageWidth, 
	int imageHeight, 
	int imageChannels)
{
	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
  
	for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x)
	{
		outputfloat[tidx] = (float)(inputchar[i] / 255.0);
	}
    
	return outputfloat;

}

__global__ 
void grayify(float* outputgray, 
	float* inputrgb, 
	unsigned char* inputchar,
  unsigned char* outputchar,
	int imageWidth, 
	int imageHeight, 
	int imageChannels)
{

	cast(inputchar, inputrgb, imageWidth, imageHeight, imageChannels);
	
	__syncthreads();

	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
  


  for (int x = tidx; x < imageWidth * imageHeight; x += blockDim.x)
  {
    int col = x % imageWidth;
    int row = x / imageWidth;
    int ii = (row * imageWidth) + col;
    float r = inputchar[imageChannels * ii] / 255.0 ;
    float g = inputchar[(imageChannels * ii) + 1]/ 255.0;
    float b = inputchar[(imageChannels * ii) + 2] / 255.0;
    //unsigned char temp = (unsigned char)(255.0 *((unsigned char)(0.21*r) + (unsigned char)(0.71*g) + (unsigned char)(0.07*b)));
    outputgray[ii] = (float) ((0.21*r) + (0.71*g) + (0.07*b));
  }
  
  /*
  for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i += blockDim.x)
	{
    //TODO for (int i = 0 )
		float r = inputchar[imageChannels * i] / 255.0 ;
		float g = inputchar[(imageChannels * i) + 1]/ 255.0;
		float b = inputchar[(imageChannels * i) + 2] / 255.0;
		__syncthreads();
		unsigned char temp = (unsigned char)(255.0 *((unsigned char)(0.21*r) + (unsigned char)(0.71*g) + (unsigned char)(0.07*b)));
		outputgray[i] = (float) (temp);
		//outputchar[i] = 258;
		//outputchar[i] = temp;
		//outputchar[i] = (unsigned char)((unsigned char)(0.21*r) + (unsigned char)(0.71*g) + (unsigned char)(0.07*b));

	}
        */
        
	//outputgray = decast(outputgray, outputchar, imageWidth, imageHeight, imageChannels);
  

}



/*
__device__ 
unsigned char** hist(unsigned char* inputchar, int imageWidth, int imageHeight)
{
  unsigned char** hgram = (unsigned char**)
    (malloc(imageWidth * imageHeight * sizeof(unsigned char*)));

  for(int i = )

}
*/




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
  unsigned char* cudaTempImageData;
  unsigned char* cudaTemp2ImageData;
  cudaMalloc(&cudaInputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaOutputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaTempImageData, (int)(sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaTemp2ImageData, (int)(sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));
  cudaMemcpy(cudaInputImageData, hostInputImageData, 
  	(int)(sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyHostToDevice);

  //send data to kernel
  grayify<<<256,256>>>(cudaOutputImageData, cudaInputImageData, 
  	cudaTempImageData, cudaTemp2ImageData, imageWidth, imageHeight, imageChannels);

  
  cudaDeviceSynchronize();

  
  //Retrieve output image data
  cudaMemcpy(hostOutputImageData, cudaOutputImageData, 
  	(sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);

  
  wbLog(TRACE, "output is ");
  for (int i = 0; i < 10; i++)
  {

      wbLog(TRACE,i, " ", hostInputImageData[i], " ", hostOutputImageData[i] );
    
  }
  
 outputImage = wbImage_new(imageWidth, imageHeight, imageChannels, hostOutputImageData);
 wbSolution(args, outputImage);

  //@@ insert code here
  cudaFree(cudaInputImageData);
  cudaFree(cudaOutputImageData);
  cudaFree(cudaTempImageData);
  cudaFree(cudaTemp2ImageData);
  free(hostInputImageData);
  free(hostOutputImageData);
  
  
  return 0;

}

