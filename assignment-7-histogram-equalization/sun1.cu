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
    unsigned char r = inputchar[imageChannels * ii];
    unsigned char g = inputchar[(imageChannels * ii) + 1];
    unsigned char b = inputchar[(imageChannels * ii) + 2] ;
    //unsigned char temp = (unsigned char)(255.0 *((unsigned char)(0.21*r) + (unsigned char)(0.71*g) + (unsigned char)(0.07*b)));
    for (int i = 0 ; i <imageChannels;i++)
    {
      outputgray[(imageChannels * ii) + i] = (float) ((0.21*r) + (0.71*g) + (0.07*b));
      outputchar[(imageChannels * ii) + i] = (unsigned char)((unsigned char)(0.21*r) + (unsigned char)(0.71*g) + (unsigned char)(0.07*b));
      /*
        output
      */
    }
    
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
        
	inputrgb = decast(inputrgb, outputchar, imageWidth, imageHeight, imageChannels);
  

}



//Use total function from list-red
__device__ 
void histify(unsigned char* inputchar, int imageWidth, int imageHeight)
{
  //unsigned char** hgram = (unsigned char**)
  //  (malloc(imageWidth * imageHeight * sizeof(unsigned char*)));

  //int idx = threadIdx.x;
  int tidx = (blockDim.x * blockIdx.x) + threadIdx.x;
  
  __shared__ float hist[256];

  for (int i = tidx; i < imageWidth * imageHeight;i += blockDim.x * gridDim.x)
  {
    //hist[inputchar[i * 3]] += 1;
    atomicAdd2(&hist[(inputchar[i * 3])], hist[(inputchar[i * 3])] += 1);
    __syncthreads();
  }

  //have mini histograms done -> test
//...

}

__device__
float p(float x, int imageWidth, int imageHeight)
{
  return x / (imageWidth * imageHeight);
}


//cdf is actually in floats but holds 256 representing characters(rgb vals)
__device__
float* calc_cdf(float* cdf, float* inputchar, int imageWidth, int imageHeight)
{
  cdf[0] = p(inputchar[0], imageWidth, imageHeight);
  for (int i = 1; i < 256; i++)
  {
    cdf[i] = cdf[i - 1] + p(inputchar[i], imageWidth, imageHeight);
  }

  return cdf;
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
  unsigned char* cudaTempImageData;
  unsigned char* cudaTemp2ImageData;
  unsigned char* testingChar = (unsigned char*)malloc(sizeof(unsigned char) * imageHeight * imageWidth * imageChannels);
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
  //for testing purps
  cudaMemcpy(hostInputImageData, cudaInputImageData,
         (sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  cudaMemcpy(testingChar, cudaTemp2ImageData,
         (sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  
  wbLog(TRACE, "output is ");
  for (int i = 0; i < 20; i++)
  {
	
      wbLog(TRACE,i, " ", hostInputImageData[i], " ", hostOutputImageData[i], " ", testingChar[i] );
    
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
  free(testingChar);  
  
  return 0;

}

