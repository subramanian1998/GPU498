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

//Use total function from list-red
__device__ 
void histify(float* globHist, unsigned char* inputchar, int imageWidth, int imageHeight)
{
  //unsigned char** hgram = (unsigned char**)
  //  (malloc(imageWidth * imageHeight * sizeof(unsigned char*)));

  //int idx = threadIdx.x;
  int tidx = (blockDim.x * blockIdx.x) + threadIdx.x;
  
  __shared__ float hist[256];


  for (int x = 0; x < gridDim.x; x++)
  {
    if (blockIdx.x == x)
    {
      for (int i = tidx; i < imageWidth * imageHeight; i += blockDim.x * gridDim.x)
      {
        //hist[inputchar[i * 3]] += 1;
        unsigned int offset = (unsigned int)((unsigned int)inputchar[i * 3]);
	      float * addr = (float *)(hist + (unsigned int)offset);
        atomicAdd((float *)(addr), (unsigned int)(1));
        //atomicAdd(&hist[(inputchar[i * 3])], hist[(inputchar[i * 3])] += 1);
        __syncthreads();
      }
      __syncthreads();
    }

   __syncthreads();
    
  }
  

  //have mini histograms done -> test -> sum upppp
  /*
  for (int i = tidx; i < 256; i+= blockDim.x * gridDim.x)
  {
    atomicAdd(&globHist[i], hist[i]);
    __syncthreads();
  }
  */

    for (int i = threadIdx.x; i < 256; i+= blockDim.x * gridDim.x)
    {
      //unsigned char offset = (unsigned char)inputchar[i * 3];
      atomicAdd((float *)(globHist + i),(unsigned int) hist[i]);
      //atomicAdd(&globHist[i], hist[i]);
      //globHist[i] = hist[i];
      __syncthreads();
    }

}

__device__
float p(unsigned char x, int imageWidth, int imageHeight)
{
  return (float)( (x * 1.0f) / (imageWidth * imageHeight));
}


//cdf is actually in floats but holds 256 representing characters(rgb vals)
__device__
float* calc_cdf(float* cdf, float* hist, int imageWidth, int imageHeight)
{
  cdf[0] = p(hist[0], imageWidth, imageHeight);
  for (int i = 1; i < 256; i++)
  {
    cdf[i] = cdf[i - 1] + p(hist[i], imageWidth, imageHeight);
  }

  return cdf;
}

__device__
unsigned char clamp(unsigned char x, unsigned char start, unsigned char end)
{
  return min(max(x, start), end);
}

__device__
unsigned char correct_val(float* cdf, unsigned char val)
{
  return clamp(255 * (cdf[val] - cdf[0]) / (1.0 - cdf[0]), 0, 255);
}

__device__
void applyhist(unsigned char * outputchar, float* cdf, int imageWidth, int imageHeight, int imageChannels)
{
  int tidx = (blockDim.x * blockIdx.x) + threadIdx.x;

  for (int i = tidx; i < imageWidth * imageHeight * imageChannels; i += blockDim.x * gridDim.x)
  {
    outputchar[i] = correct_val(cdf, outputchar[i]);
  }
}



__global__ 
void grayify(float* outputgray, 
  float* inputrgb, 
  float* hist,
  float* cdf,
  unsigned char* outputchar,
  unsigned char* inputchar,
  int imageWidth, 
  int imageHeight, 
  int imageChannels)
{

  //cast
  cast(inputchar, inputrgb, imageWidth, imageHeight, imageChannels, 1);
  
  __syncthreads();

  int tidx = (blockIdx.x * blockDim.x) + threadIdx.x; 
  
  //grayify
  for (int x = tidx; x < (imageWidth * imageHeight); x += blockDim.x)
  {
    int col = (x) % imageWidth;
    int row = (x) / imageWidth;
    int ii = (row * imageWidth) + col;

    unsigned char r = (unsigned char)(0.21 * inputchar[imageChannels * ii]);
    unsigned char g =  (unsigned char)(0.71 * inputchar[(imageChannels * ii) + 1]);
    unsigned char b = (unsigned char)(0.07 * inputchar[(imageChannels * ii) + 2]);

    __syncthreads();
    for (int i = 0 ; i <imageChannels;i++)
    {
      outputchar[(imageChannels * ii) + i] = (unsigned char)(r + g + b);
    }
  }

  //histify
  histify(hist, outputchar, imageWidth, imageHeight);

  //calc hist
  cdf = calc_cdf(cdf, hist, imageWidth, imageHeight);

  //apply hist to image
  applyhist(outputchar, cdf, imageWidth, imageHeight, imageChannels);

  //recast
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
  unsigned char* cudaInputChar;
  unsigned char* cudaOutputChar;
  float* cudaHist;
  float* hostHist;
  hostHist = (float *)malloc(256 * sizeof(float));

  float* cudaCdf;
  cudaMalloc(&cudaCdf, (sizeof(float) * 256));

  cudaMalloc(&cudaInputImageData, (int)(sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaOutputImageData, (sizeof(float) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaHist, (sizeof(float) * 256));
  cudaMalloc(&cudaInputChar, (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));
  cudaMalloc(&cudaOutputChar, (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth));

  cudaMemcpy(cudaInputImageData, hostInputImageData, 
  	(int)(sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyHostToDevice);


  //send data to kernel
  grayify<<<256,256>>>(cudaOutputImageData, cudaInputImageData, cudaHist, cudaCdf, cudaOutputChar, cudaInputChar,
        imageWidth, imageHeight, imageChannels);

  
  cudaDeviceSynchronize();

  
  //Retrieve output image data
  //cudaMemcpy(testingChar, cudaChar,
   //      (sizeof(unsigned char) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  cudaMemcpy(hostOutputImageData, cudaOutputImageData,
         (sizeof(float) * imageChannels * imageHeight * imageWidth), cudaMemcpyDeviceToHost);
  cudaMemcpy(hostHist, cudaCdf,
         (sizeof(float) * 256), cudaMemcpyDeviceToHost);
  
  
  wbLog(TRACE, "output is ");
  for (int i = 0; i < 256; i++)
  {
     wbLog(TRACE, "float" , hostInputImageData[i] , " ", hostOutputImageData[i]);
    wbLog(TRACE, "hist " , hostHist[i]);
  }
  


 outputImage = wbImage_new(imageWidth, imageHeight, imageChannels, hostOutputImageData);
 wbSolution(args, outputImage);

  //@@ insert code here
  cudaFree(cudaInputImageData);
  cudaFree(cudaOutputChar);
  cudaFree(cudaInputChar);
  cudaFree(cudaHist);
  free(hostInputImageData);
  free(hostOutputImageData);
  //free(testingChar);  
  
  return 0;

}

