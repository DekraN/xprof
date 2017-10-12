#include <stdio.h>
#include <stdlib.h>

#include <sys/time.h>

#if(defined(PERFCOUNT) || defined(PERFCOUNT2))
	#include <papi.h>
	#include <papiStdEventDefs.h>
	#define PERFCOUNTX
#endif

// #define VERBOSE
#define DEFAULT_NMAX 100000
#define DEFAULT_NR DEFAULT_NMAX
#define DEFAULT_INC 10
#define DEFAULT_XIDX 0

#define MAX_PATH_LENGTH 1024

#define ERROR_DESC stderr

// #define WINOS
#define STACKALLOC

#ifdef WINOS 
	#include <windows.h>
#endif

static void dummy(double A[], double B[], double C[], double D[])
{
	return;
}

static double simulation(int N, int R)
{
	int i, j;
	
	#ifdef STACKALLOC
		double A[N];
		double B[N];
		double C[N];
		double D[N];
	#else
		double * A = malloc(N*sizeof(double));
		double * B = malloc(N*sizeof(double));
		double * C = malloc(N*sizeof(double));
		double * D = malloc(N*sizeof(double));
	#endif
	
	double elaps;
	
	for (i = 0; i < N; ++i)
	{
	    A[i] = 0.00;
	    B[i] = 1.00;
	    C[i] = 2.00;
	    D[i] = 3.00;
  	}
	
	#ifdef WINOS
		FILETIME tp;
		GetSystemTimePreciseAsFileTime(&tp);
		elaps = - (double)(((ULONGLONG)tp.dwHighDateTime << 32) | (ULONGLONG)tp.dwLowDateTime)/10000000.0;
	#else
		struct timeval tp;
		gettimeofday(&tp, NULL);
		elaps = -(double)(tp.tv_sec + tp.tv_usec/1000000.0);
	#endif
	
	for(j=0; j<R; ++j)
	{
		for(i=0; i<N; ++i)
			A[i] = B[i] + C[i]*D[i];
			
		if(A[2] < 0) dummy(A, B, C, D);
	}
	
	#ifndef STACKALLOC
		free(A);
		free(B); 
		free(C);
		free(D);
	#endif
	
	#ifdef WINOS
		GetSystemTimePreciseAsFileTime(&tp);
		return elaps + (double)(((ULONGLONG)tp.dwHighDateTime << 32) | (ULONGLONG)tp.dwLowDateTime)/10000000.0;
	#else
		gettimeofday(&tp, NULL);
		return elaps + ((double)(tp.tv_sec + tp.tv_usec/1000000.0));
	#endif
}

enum
{
	NOERROR_EXIT = 0
	#ifdef PERFCOUNTX
	, ERROR_PAPIADDEVENTTOTCYC,
	ERROR_PAPIADDEVENTTOTINS,
	ERROR_PAPIADDEVENTL2TCM,
	ERROR_PAPIADDEVENTL3TCM,
	ERROR_PAPIADDEVENTLDINS,
	ERROR_PAPIADDEVENTSRINS,
	ERROR_PAPIADDEVENTFPOPS,
	ERROR_PAPIADDEVENTFPINS,
	MAX_PAPICOUNTERS = ERROR_PAPIADDEVENTFPINS,
	ERROR_PAPICREATEEVSET,
	ERROR_PAPISTART,
	ERROR_PAPISTOP,
	ERROR_PAPIVER
	#endif
};

#ifdef PERFCOUNTX

#ifdef PERFCOUNT
enum
{
	PAPI_TOTCYC,
	PAPI_TOTINS,
	PAPI_L2TCM,
	PAPI_L3TCM,
	PAPI_LDINS,
	PAPI_SRINS,
	PAPI_FPOPS,
	PAPI_FPINS,
	MAX_PERFCOUNT
};
#else
#ifdef PERFCOUNT2
enum
{
	PAPI_UOPSEXECUTEDSTALLCYCLES,
	PAPI_LLCPREFETCHMISSESPREFETCH,
	PAPI_FPCOMPOPSEXEX87,
	PAPI_FPCOMPOPSEXESSESCALARDOUBLE,
	PAPI_ARITHFPUDIVACTIVE,
	PAPI_ARITHFPUDIV,
	MAX_PERFCOUNT
};
#endif 
#endif
	

static inline void handle_error(int retval)
{
	fprintf(ERROR_DESC, "%s\n", PAPI_strerror(retval));
	return;
}
#endif

int main(int argc, char *argv[])
{
	const int NR = argc > 1 ? atoi(argv[1]) : DEFAULT_NR;
	const int NMAX = argc > 2 ? atoi(argv[2]) : DEFAULT_NMAX;
	const int inc = argc > 3 ? atoi(argv[3]) : DEFAULT_INC;
	
	#ifdef VERBOSE
		const int xidx = argc > 4 ? atoi(argv[4]) : DEFAULT_XIDX;
	#endif
	
	int i, j, k;
	
	#ifdef VERBOSE
		FILE * fp;
		printf("\n*** Schonauer Triad benchmark ***\n");
	
		char csvname[MAX_PATH_LENGTH];
	  	sprintf(csvname, "data%d.csv", xidx);
	
		if(!(fp = fopen(csvname, "a+")))
		{
			printf("\nError whilst writing to file\n");
			return 1;
		}
	#endif
	
	int R, N;
	double MFLOPS;
	double elaps;
	
	#ifdef PERFCOUNTX
		double cpu_time = 0.00;

		printf("\nInitializing PAPI Library..\n");
		printf("PAPI_VER_CURRENT value: %d\n", PAPI_VER_CURRENT);
		int EventSet = PAPI_NULL;
		int retval = PAPI_library_init(PAPI_VER_CURRENT);
		if(retval != PAPI_VER_CURRENT && retval > 0)
		{
			fprintf(ERROR_DESC,"PAPI library version mismatch!\en");
			handle_error(retval);			
			return ERROR_PAPIVER;
		}

		if (retval < 0)
		{
			fprintf(ERROR_DESC, "Some library error occurred: ");
			handle_error(retval);
			return ERROR_PAPIVER;
		}
		retval = PAPI_is_initialized();
		if ((retval = PAPI_is_initialized()) != PAPI_LOW_LEVEL_INITED)
		{
			fprintf(ERROR_DESC, "Some library low-level initialization error occurred: ");
			handle_error(retval);
			return ERROR_PAPIVER;
		}		

		if((retval = PAPI_create_eventset(&EventSet)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_create_eventset(): ");
			handle_error(retval);	
			return ERROR_PAPICREATEEVSET;
		}
		if((retval = PAPI_add_event(EventSet, PAPI_TOT_CYC)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_TOT_CYC): ");	
			handle_error(retval);				
			return ERROR_PAPIADDEVENTTOTCYC;
		}
		if((retval = PAPI_add_event(EventSet, PAPI_TOT_INS)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_TOT_INS): ");
			handle_error(retval);	
			return ERROR_PAPIADDEVENTTOTINS;
		}
		if((retval = PAPI_add_event(EventSet, PAPI_L2_TCM)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_L2_TCM): ");
			handle_error(retval);		
			return ERROR_PAPIADDEVENTL2TCM;
		}
		if((retval = PAPI_add_event(EventSet, PAPI_L3_TCM)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_L3_TCM): ");
			handle_error(retval);	
			return ERROR_PAPIADDEVENTL3TCM;
		}
		if((retval = PAPI_add_event(EventSet, PAPI_LD_INS)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_LD_INS): ");
			handle_error(retval);	
			return ERROR_PAPIADDEVENTLDINS;
		}
		if((retval = PAPI_add_event(EventSet, PAPI_SR_INS)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_SR_INS)");
			handle_error(retval);	
			return ERROR_PAPIADDEVENTSRINS;
		}
		if((retval = PAPI_add_event(EventSet, PAPI_FP_OPS)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_FP_OPS): ");
			handle_error(retval);	
			return ERROR_PAPIADDEVENTFPOPS;
		}	
		if((retval = PAPI_add_event(EventSet, PAPI_FP_INS)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_add_event(PAPI_FP_INS): ");
			handle_error(retval);	
			return ERROR_PAPIADDEVENTFPINS;	
		}
	
		if((retval = PAPI_start(EventSet)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_start(): ");
			handle_error(retval);	
			return ERROR_PAPISTART;
		}
	
		// count_init();
		// count_start();
	#endif
	
	for(N=1; N<=NMAX; N += inc)
	{
		R = NR/N;
		elaps = simulation(N, R);
		#ifdef PERFCOUNTX
			cpu_time += elaps;
		#endif
		#ifdef VERBOSE		
			MFLOPS = ((R*N)<<1)/(elaps*1000000);
			fprintf(fp, "%d,%lf\n", N, MFLOPS);
			printf("N = %d, R = %d\n", N, R);
			printf("Elapsed time: %lf\n", elaps);
			printf("MFLOPS: %lf\n", MFLOPS);
		#endif
	}

	#ifdef PERFCOUNTX
		// count_stop();
		// count_finalize();
	
		long_long ret_values[MAX_PERFCOUNT];
		
		if((retval = PAPI_stop(EventSet, ret_values)) != PAPI_OK)
		{
			fprintf(ERROR_DESC, "error on PAPI_stop(): ");
			handle_error(retval);	
			return ERROR_PAPISTOP;
		}


		printf("*** Start PAPI counters listings ***\n");
		#ifdef PERFCOUNT
			printf("PAPI_STOP_OUTPUT: PAPI_TOT_CYC: %lld\n", ret_values[PAPI_TOTCYC]);
			printf("PAPI_STOP_OUTPUT: PAPI_TOT_INS: %lld\n", ret_values[PAPI_TOTINS]);
			printf("PAPI_STOP_OUTPUT: PAPI_L2_TCM: %lld\n", ret_values[PAPI_L2TCM]);
			printf("PAPI_STOP_OUTPUT: PAPI_L3_TCM: %lld\n", ret_values[PAPI_L3TCM]);
			printf("PAPI_STOP_OUTPUT: PAPI_LD_INS: %lld\n", ret_values[PAPI_LDINS]);
			printf("PAPI_STOP_OUTPUT: PAPI_SR_INS: %lld\n", ret_values[PAPI_SRINS]);
			printf("PAPI_STOP_OUTPUT: PAPI_FP_OPS: %lld\n", ret_values[PAPI_FPOPS]);
			printf("PAPI_STOP_OUTPUT: PAPI_FP_INS: %lld\n", ret_values[PAPI_FPINS]);
		#else
		#ifdef PERFCOUNT2
			printf("PAPI_STOP_OUTPUT: UOPS_EXECUTED:STALL-CYCLES: %lld\n", ret_values[PAPI_UOPSEXECUTEDSTALLCYCLES]);
			printf("PAPI_STOP_OUTPUT: LLC-PREFETCH-MISSES: %lld\n", ret_values[PAPI_LLCPREFETCHMISSESPREFETCH]);
			printf("PAPI_STOP_OUTPUT: FP_COMP_OPS_EXE:X87: %lld\n", ret_values[PAPI_FPCOMPOPSEXEX87]);
			printf("PAPI_STOP_OUTPUT: FP_COMP_OPS_EXE:SSE_SCALAR_DOUBLE: %lld\n", ret_values[PAPI_FPCOMPOPSEXESSESCALARDOUBLE]);		
			printf("PAPI_STOP_OUTPUT: ARITH:FPU_DIV_ACTIVE: %lld\n", ret_values[PAPI_ARITHFPUDIVACTIVE]);
			printf("PAPI_STOP_OUTPUT: ARITH:FPU_DIV: %lld\n", ret_values[PAPI_ARITHFPUDIV]);
		#endif
		#endif
		
		printf("\nExecution time: %lf\n\n", cpu_time);
	#endif
	
	#ifdef VERBOSE
		fclose(fp);
		(void) getchar();
	#endif
	return 0;
}
