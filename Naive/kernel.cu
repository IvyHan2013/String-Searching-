
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);

__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
	
}


cudaError_t searchPattern(char *string,char*pat,int* res);

__global__ void searchPatternKernel(const char *string,const char*pat,int patlen,int segstringlen,int lastsegstringlen,int *res)
{
	int startIndex =threadIdx.x;
	printf("%d\n",startIndex);
	int pos;//the pos of this segment 

	//divide into 4 segment 0123
	pos = startIndex*segstringlen;
	printf("pos:%d\n",pos);
	/*if (string[i]==pat[0])
	{
		int j;
		for(j=1;j<4;j++)
		{ 
			if (string[i+j]!=pat[j])break;
			else res[i]=1;
		}
	}*/

	int strl;//the length of the segment
	if (startIndex<3)
	{
		strl=segstringlen+patlen;
	}
	else strl=lastsegstringlen;
	printf("%d\n",strl);
	
	printf("pati :%s %d\n",pat,startIndex);
	printf("string i:%s %d\n",string,startIndex);
	
	
	
	int i;
	for (i=pos;i<pos+strl-patlen+1;i++)
	{
	
	int flag=1;

		int j;
		for (j=0;j<patlen;j++)
		{
			if (pat[j]!=string[j+i]){flag=0;break;}
		}
			if(flag)res[i]=1;

	}

}



int main()
{
   /*const int arraySize = 5;
    const int a[arraySize] = { 1, 2, 3, 4, 5 };
    const int b[arraySize] = { 10, 20, 30, 40, 50 };
    int c[arraySize] = { 0 };

    // Add vectors in parallel.
   cudaError_t cudaStatus = addWithCuda(c, a, b, arraySize);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }

    printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
        c[0], c[1], c[2], c[3], c[4]);*/

	char string[]="wefdfewfjwfbhwyfghwqfbhweyhwefhwefewbfwfhbwuw";
    char pat[]="wef";
	int const  datasize= strlen(string);

	int* res;
	res=(int*)malloc((datasize)* sizeof(int));

	 memset(res, 0, datasize);
	 //searchPattern(char* string, char*pat)
	cudaError_t cudaStatus = searchPattern(string, pat,res);
if (cudaStatus != cudaSuccess) {
  fprintf(stderr, "searchPattern failed!");
  return 1;
}

// Print out the string match result position
int total_matches = 0;
for (int i=0; i<datasize; i++) {
  if (res[i] == 1) {
    printf("Character found at position % i\n", i);
    total_matches++;
  }
}
printf("Total matches = %d\n", total_matches);


    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }
	system("pause");
    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernel<<<1, size>>>(dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}


cudaError_t searchPattern(char* string, char*pat,int *res)
{
    char *dev_string = 0;
    char *dev_pat = 0;
    int *dev_res = 0;
	int stringlen=strlen(string);
	int patlen=strlen(pat);
		printf("%d\n",patlen);
	
	int segstrlen=stringlen/4;
		printf("%d\n",segstrlen);
	int lastsegstrlen= segstrlen+stringlen%4;
		printf("%d\n",lastsegstrlen);

    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_string,(stringlen)* sizeof(char));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }
	
	cudaStatus = cudaMalloc((void**)&dev_pat, (patlen) * sizeof(char));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_res, (stringlen) * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.

	cudaStatus = cudaMemcpy(dev_string, string, (stringlen) * sizeof(char), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy1 failed!");
        goto Error;
    }

	cudaStatus = cudaMemcpy(dev_pat, pat, (patlen)* sizeof(char), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy2 failed!");
        goto Error;
    }
	
	cudaStatus = cudaMemset(dev_res, 0, (stringlen)* sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemset failed!");
        goto Error;
    }
	
    // Launch a kernel on the GPU with one thread for each element.
    //searchPatternKernel<<<1, size>>>(dev_res, dev_string, dev_pat);

	searchPatternKernel<<<1,4>>>(dev_string,dev_pat,patlen,segstrlen,lastsegstrlen,dev_res);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "PatternKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
   // cudaStatus = cudaDeviceSynchronize();
	cudaStatus = cudaThreadSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching searchpatternKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(res, dev_res, (stringlen) * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
   cudaFree(dev_res);
    cudaFree(dev_pat);
    cudaFree(dev_string);
    
    return cudaStatus;
}
