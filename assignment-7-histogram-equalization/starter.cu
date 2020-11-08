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
  /*
	for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x)
	{
		outputchar[i] = (unsigned char)(255 * inputfloat[i]);
	}
  */

  outputchar[tidx] = (unsigned char)(255); //* inputfloat[tidx]);

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
  /*
	for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i+= blockDim.x)
	{
		outputfloat[tidx] = (float)(inputchar[tidx] / 255.0);
	}
    */

  outputfloat[tidx] = (float)(1.0);//inputchar[tidx] / 255.0);
	return outputfloat;

}

__global__ 
void grayify(float* outputgray, 
	float* inputrgb, 
	unsigned char* inputchar,
	int imageWidth, 
	int imageHeight, 
	int imageChannels)
{

	//cast(inputchar, inputrgb, imageWidth, imageHeight, imageChannels);
	
	__syncthreads();

	int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
        /*  
	for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i += blockDim.x)
	{
    //TODO for (int i = 0 )
		float r = inputchar[imageChannels * i];
		float g = inputchar[(imageChannels * i) + 1];
		float b = inputchar[(imageChannels * i) + 2];
		__syncthreads();
		inputchar[i] = (unsigned char) (0.21*r + 0.71*g + 0.07*b);
	}

        */
	//outputgray = decast(outputgray, inputchar, imageWidth, imageHeight, imageChannels);
        outputgray = inputrgb;

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
  
  wbTime_stop(Generic, "Importing data and creating memory on host");

  //@@ insert code here

  //get pointers to input and output images
  hostInputImageData = wbImage_getData(inputImage);
  //hostOutputImageData = wbImage_getData(outputImage);

  //alloc mem and dimensions
  float* cudaInputImageData;
  float* cudaOutputImageData;
  unsigned char* cudaTempImageData;
  cudaMalloc((void **)&cudaInputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc((void **)&cudaOutputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaTempImageData, (int)(sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));
  cudaMemcpy(cudaInputImageData, hostInputImageData, 
  	sizeof(float) * imageChannels * imageHeight * imageWidth, cudaMemcpyHostToDevice);

  //send data to kernel
  grayify<<<256,256>>>(cudaOutputImageData, cudaInputImageData, 
  	cudaTempImageData, imageWidth, imageHeight, imageChannels);


  cudaDeviceSynchronize();


  //Retrieve output image data
  cudaMemcpy(&hostOutputImageData, &cudaOutputImageData, 
  	(int)(sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);


  outputImage = wbImage_new(imageWidth, imageHeight, imageChannels, hostOutputImageData);
  wbSolution(args, outputImage);

  //@@ insert code here

  

  return 0;

}

