// Histogram Equalization

#include <wb.h>

#define HISTOGRAM_LENGTH 256
//TESTING UPDATES BITCH

//@@ insert code here
__global__
unsigned char * cast( float * outputchar, 
	float * inputfloat, 
	int imageWidth, 
	int imageHeight, 
	int imageChannels)
{
	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
	for (int i = tidx; i < imageWidth * imageHeight * imageChannels, i+= blockDim.x)
	{
		outputchar[i] = (unsigned char)(255 * inputfloat[i]);
	}

	return outputchar;
}

__global__ 
void grayify( float * outputgray, 
	float * inputrgb, 
	int imageWidth, 
	int imageHeight, 
	int imageChannels)
{

	outputgray = cast(outputgray, inputrgb, imageWidth, imageHeight, imageChannels);
	
	synchronize();

	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 

	for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i += blockDim.x)
	{
		r = outputgray[imageChannels * i];
		g = outputgray[(imageChannels * i) + 1];
		b = outputgray[(imageChannels * i) + 1];
		synchronize();
		outputgray[tidx] = (unsigned char) (0.21*r + 0.71*g + 0.07*b);
	}

}


int main(int argc, char **argv) {
  wbArg_t args;
  int imageWidth;
  int imageHeight;
  int imageChannels;
  wbImage_t inputImage;
  wbImage_t outputImage;
  float *hostInputImageData;
  float *hostOutputImageData;
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
  outputImage = wbImage_new(imageWidth, imageHeight, imageChannels);
  wbTime_stop(Generic, "Importing data and creating memory on host");

  //@@ insert code here

  //get pointers to input and output images
  hostInputImageData = wbImage_getData(inputImage);
  hostOutputImageData = wbImage_getData(outputImage);

  //alloc mem and dimensions
  float * cudaInputImageData, cudaOutputImageData;
  cudaMalloc(&cudaInputImageData, sizeof(FLOAT) * imageChannels * imageHeight * imageWidth);
  cudaMemcpy(cudaInputImageData, hostInputImageData, 
  	sizeof(FLOAT) * imageChannels * imageHeight * imageWidth, cudaMemcpyHostToDevice);

  //send data to kernel
  grayify<<<256,256>>>(cudaOutputImageData, cudaInputImageData, 
  	imageWidth, imageHeight, imageChannels);


  cudaDeviceSynchronize();


  //Retrieve output image data
  cudaMemcpy(hostOutputImageData, cudaOutputImageData, 
  	sizeof(FLOAT) * imageChannels * imageHeight * imageWidth, cudaMemcpyDeviceToHost);


  wbSolution(args, outputImage);

  //@@ insert code here

  


  return 0;
}
