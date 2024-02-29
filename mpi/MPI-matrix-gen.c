#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include <mpi.h>



int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);
    int M;
    int N;
    int K;
    int seed;
    MPI_Comm comm_world_copy;

    if(argc!=6){
        printf("eseguire con ./<nomeEseguibile> <seed> <nomeCartella> <M> <N> <K>\n");
        return -1;
    }

    MPI_Comm_dup(MPI_COMM_WORLD, &comm_world_copy);

    seed=atoi(argv[1]);  
    M=atoi(argv[3]);
    N=atoi(argv[4]);
    K=atoi(argv[5]);
    if(M == 0 || N==0 || K==0){
        printf("malloc per la creazione dei file fallita\n");
        MPI_Abort(comm_world_copy, -1);
        MPI_Finalize();
        return -1;
    }
    int rank, size; 
    MPI_Comm_rank(comm_world_copy, &rank);
    MPI_Comm_size(comm_world_copy, &size);

    //check numero di processi
    if(size < 3) {
        printf("Sono necessari 3 processi per eseguire il programma\n");
        MPI_Abort(comm_world_copy, EXIT_FAILURE);
    }

    //MPI_File file;
    //MPI_File fileShadow;
    FILE * file;
    FILE * fileShadow;
    char *filename=(char*)malloc(sizeof(char)*(strlen(argv[2])+3));
    char *filenameShadow=(char*)malloc(sizeof(char)*(strlen(argv[2])+7));
    if(filename==NULL || filenameShadow==NULL ){
        printf("malloc per la creazione dei file fallita\n");
        MPI_Abort(comm_world_copy, -1);
        MPI_Finalize();
        return -1;
    }

    // Specifica il nome del file
    if(rank==0){
        sprintf(filename,"%s/A\0",argv[2]);
        sprintf(filenameShadow,"%s/A.txt\0",argv[2]);
        N=K;
    }
    if(rank==1){
        sprintf(filename,"%s/B\0",argv[2]);
        sprintf(filenameShadow,"%s/B.txt\0",argv[2]);
        M=K;
    }
    if(rank==2){
        sprintf(filename,"%s/C\0",argv[2]);
        sprintf(filenameShadow,"%s/C.txt\0",argv[2]);
    }
    // Inizializzazione di dati locali con valori casuali
    srand(seed+rank);  // Inizializza il seed del generatore di numeri casuali basato sul rank
    // Apertura del file per la scrittura
    // Processo 0 scrive le dimensioni della matrice nel file
   
    //MPI_File_open(MPI_COMM_SELF, filename, MPI_MODE_CREATE | MPI_MODE_WRONLY, MPI_INFO_NULL, &file);
    //MPI_File_open(MPI_COMM_SELF, filenameShadow, MPI_MODE_CREATE | MPI_MODE_WRONLY, MPI_INFO_NULL, &fileShadow);
    // file=fopen(filename,"w+");
    // fileShadow=(filenameShadow,"w+");
    if (rank < 3) {
        // MPI_File_open(MPI_COMM_SELF, filename, MPI_MODE_CREATE | MPI_MODE_WRONLY, MPI_INFO_NULL, &file);
        // MPI_File_open(MPI_COMM_SELF, filenameShadow, MPI_MODE_CREATE | MPI_MODE_WRONLY, MPI_INFO_NULL, &fileShadow);
        file=fopen(filename,"w+");
        fileShadow=fopen(filenameShadow,"w+");

        // MPI_File_write(file, &M, 1, MPI_INT, MPI_STATUS_IGNORE);
        // MPI_File_write(file, &N, 1, MPI_INT, MPI_STATUS_IGNORE);
        fwrite(&M,1,sizeof(int),file);
        fwrite(&N,1,sizeof(int),file);
        char buffer[100];
        sprintf(buffer,"%d,%d\n\0",M,N);
        fwrite(&buffer,strlen(buffer),sizeof(char),fileShadow);
        //MPI_File_write(fileShadow, &buffer,strlen(buffer), MPI_CHAR, MPI_STATUS_IGNORE);
        for(int i=0;i<M;i++){
            float s;
            char buffer2[20];
            for(int j=0;j<N-1;j++){
                s=((float) (rand()%1000000))/1000000.0;
                sprintf(buffer2,"%f,\0",s);
                //MPI_File_write(file, &s, 1, MPI_FLOAT, MPI_STATUS_IGNORE);
                fwrite(&s,1,sizeof(float),file);
                fwrite(&buffer2,strlen(buffer2),sizeof(char),fileShadow);
                //MPI_File_write(fileShadow, &buffer2,strlen(buffer2), MPI_CHAR, MPI_STATUS_IGNORE);
            }

            s=((float) (rand()%1000000))/1000000.0;
            sprintf(buffer2,"%f\n\0",s);
            fwrite(&s,1,sizeof(float),file);
            fwrite(&buffer2,strlen(buffer2),sizeof(char),fileShadow);
            // MPI_File_write(file, &s, 1, MPI_FLOAT, MPI_STATUS_IGNORE);
            // MPI_File_write(fileShadow, &buffer2, strlen(buffer2), MPI_CHAR, MPI_STATUS_IGNORE);
        }
        //MPI_File_close(&file);
        //MPI_File_close(&fileShadow);
        fclose(file);
        fclose(fileShadow);
    }
    // Chiusura del file
    MPI_Finalize();

    return 0;
}
