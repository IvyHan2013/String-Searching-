
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctime>
#include <iostream>
#include <Windows.h>
using namespace std;
#define MAXCHAR 256

#define N	1024
#define THREADS_PER_BLOCK 16
_LARGE_INTEGER time_start;
_LARGE_INTEGER time_over;
double dqFreq;
cudaError_t searchPattern(char *string,char*pat,int* res);

void makeBadCharTable(int* table, char* pat,int patlen)
{
    //init table with all char cannot be found
    int i;
    for (i=0; i<MAXCHAR;i++)
    {
        table[i]=patlen;//not found
    }
    for (i=0;i<patlen-1;i++)
    {
        table[pat[i]]=patlen-1-i;
    }

}

__global__ void searchPatternKernel(const char *string,const char*pat,int patlen,int segstringlen,int lastsegstringlen,int *res,int* table)
{
	int startIndex =threadIdx.x+blockIdx.x * blockDim.x;
	//printf("%d\n",startIndex);
	int pos;//the pos of this segment 

	//divide into nthread segment 
	pos = startIndex*segstringlen;
	
	

	int strl;//the length of the segment
	if (startIndex<N-1)
	{
		strl=segstringlen+patlen;
	}
	else strl=lastsegstringlen;
	

	int i;

	/*__shared__ char substring[49151];

	for (i=0;i<strl;i++)
	{
		substring[i]=string[i+pos];
	}*/

	for (i=pos;i<pos+strl-patlen+1;)
	{
	
		int j= patlen-1;

        while(j>=0&& pat[j]==string[i+j])
        {
            j--;
        }
        if (j<0)
        {
			res[i]=1;

        }

        i+=table[string[i+patlen-1]];
	}

	
	/*for (i=0;i<strl-patlen+1;)
	{
	
		int j= patlen-1;

        while(j>=0&& pat[j]==substring[i+j])
        {
            j--;
        }
        if (j<0)
        {
			res[i+pos]=1;

        }

        i+=table[substring[i+patlen-1]];
	}
	__syncthreads();*/

}


int main()
{

	char *string;
	char *pat;
	
	
	freopen("input6.txt", "r", stdin);


	/*char tmp;
	int ll=0;
	tmp=cin.get();

	while (tmp!='\n')
	{
		ll++;
		tmp=cin.get();
	}

	printf("%d\n",ll);
	tmp=cin.get();
	ll=0;
	while (tmp!='\n')
	{
		ll++;
		tmp=cin.get();
	}
	printf("%d\n",ll);
	return 0;*/



	string = new char[400000000];
	pat = new char[40000];

	cin.getline(string, 400000000, '\n');
	cin.getline(pat, 40000, '\n');


	
	//char string[]="wefdfewfjwfbhwyfghwqfbhweyhwefhwefewbfwfhbwuw";
    //char pat[]="wef";
	int const  datasize= strlen(string);

	int* res;
	res=(int*)malloc((datasize)* sizeof(int));

	memset(res, 0, datasize);

	 //searchPattern(char* string, char*pat)


	 clock_t start_time=clock();

    
        cudaError_t cudaStatus = searchPattern(string, pat,res);
     

     clock_t end_time=clock();
     
	
	

	
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
	//printf("time cost: %fms\n", 1000 * ((time_over.QuadPart - time_start.QuadPart) / dqFreq));
	 cout<< "Running time is: "<<static_cast<double>(end_time-start_time)/CLOCKS_PER_SEC*1000<<"ms"<<endl;//输出运行时间
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


cudaError_t searchPattern(char* string, char*pat,int *res)
{
    char *dev_string = 0;
    char *dev_pat = 0;
    int *dev_res = 0;
	int stringlen=strlen(string);
	int patlen=strlen(pat);
	//	printf("%d\n",patlen);
	
	int segstrlen=stringlen/N;
		//printf("%d\n",segstrlen);

	int lastsegstrlen= segstrlen+stringlen%N;
		//printf("%d\n",lastsegstrlen);


	
	 int table[MAXCHAR];
	
    makeBadCharTable(table,pat,patlen);

	int *dev_table=0;

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

	cudaStatus = cudaMalloc((void**)&dev_table, (MAXCHAR) * sizeof(int));
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

	cudaStatus = cudaMemcpy(dev_table, table, (MAXCHAR)* sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy2 failed!");
        goto Error;
    }
	
	cudaStatus = cudaMemset(dev_res, 0, (stringlen)* sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemset failed!");
        goto Error;
    }
		LARGE_INTEGER f;
	QueryPerformanceFrequency(&f);
	dqFreq = (double)f.QuadPart;
    // Launch a kernel on the GPU with one thread for each element.
   
	QueryPerformanceCounter(&time_start);

	
	searchPatternKernel<<<N/THREADS_PER_BLOCK,THREADS_PER_BLOCK>>>(dev_string,dev_pat,patlen,segstrlen,lastsegstrlen,dev_res,dev_table);
	
	
	QueryPerformanceCounter(&time_over);


	


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
