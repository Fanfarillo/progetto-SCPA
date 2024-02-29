#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define DIMS 2  //number of dimensions of a matrix
#define NO (0)
#define YES NO+1
#define DEBUG

#define CONVERTOA(i,j) 2*sizeof(int) + sizeof(int)*i*(proc_dims[0])*K + sizeof(int)*my_coord[0]*K + sizeof(int)*j
#define CONVERTOB(i,j) 2*sizeof(int) + sizeof(int)*i*N + sizeof(int)*j*(proc_dims[1])+ sizeof(int)*my_coord[1]
#define CONVERTOC(i,j) 2*sizeof(int) + sizeof(int)*i*(proc_dims[0])*N + sizeof(int)*my_coord[0]*N + sizeof(int)*j*(proc_dims[1])+sizeof(int)*my_coord[1]


//i->j->z
void calcolo_Computazionale1(int m,int n,int k,const float* localA,const float* localB,float* localC){
    for(int i=0;i<m;i++){
        for(int j=0;j<n;j++){
            for(int z=0;z<k;z++){
                localC[i*n+j]+=localA[i*k+z]*localB[j*k+z];
            }
        }
    }
}
//i->z->j
void calcolo_Computazionale2(int m,int n,int k,const float* localA,const float* localB,float* localC){
    for(int i=0;i<m;i++){
        for(int z=0;z<k;z++){
            for(int j=0;j<n;j++){
                localC[i*n+j]+=localA[i*k+z]*localB[j*k+z];
            }
        }
    }
}
//j->i->z
void calcolo_Computazionale3(int m,int n,int k,const float* localA,const float* localB,float* localC){
    for(int j=0;j<n;j++){
        for(int i=0;i<m;i++){
            for(int z=0;z<k;z++){
                localC[i*n+j]+=localA[i*k+z]*localB[j*k+z];
            }
        }
    }
}
//j->z->i
void calcolo_Computazionale4(int m,int n,int k,const float* localA,const float* localB,float* localC){
    for(int j=0;j<n;j++){
        for(int z=0;z<k;z++){
            for(int i=0;i<m;i++){
                localC[i*n+j]+=localA[i*k+z]*localB[j*k+z];
            }
        }
    }
}
//z->i->j
void calcolo_Computazionale5(int m,int n,int k,const float* localA,const float* localB,float* localC){
    for(int z=0;z<k;z++){
        for(int i=0;i<m;i++){
            for(int j=0;j<n;j++){
                localC[i*n+j]+=localA[i*k+z]*localB[j*k+z];
            }
        }
    }
}
//z->j->i
void calcolo_Computazionale6(int m,int n,int k,const float* localA,const float* localB,float* localC){
    for(int z=0;z<k;z++){
        for(int j=0;j<n;j++){
            for(int i=0;i<m;i++){
                localC[i*n+j]+=localA[i*k+z]*localB[j*k+z];
            }
        }
    }
}

int main(int argc, char **argv) {

    //servono per verificare il corretto passaggio dei file
    int KA,MA;
    int KB,NB;
    int MC,NC;
    int MR,NR;
    //informazioni che il processo 0 deve inviare agli altri processi
    int K;  //Numero Colonne A //Numero righe B
    int M;  //Numero Righe di A //Numero righe di C 
    int N;  //Numero Colonne di B //Numero colonne di C
    int nb =1;      //Iper-parametro della mattonella
    int mb =1;      //iper-parametro della mttonella
    //porzioni locali delle matrici
    // float *localA;
    // float *localB;
    // float *localC;
    // float *C;   //variabile utilizzata solo dal processo 0
    //variabili MPI
    int my_rank;        //il rank personale all'interno dell comunicatore globale
    int my_coord[DIMS]; //le cordinate sulla griglia all'interno del comunicatore cartesiano 
    int p;              //Numero di processi utilizzati
    MPI_Comm comm_world_copy;   //copia del comunicatore MPI_COMM_WORLD (è sempre buona norma averla)
    MPI_Comm comm_cart;         //nuovo comunicatore relativo alla griglia di processi da associare alla matrice C
    //variabili utili per suddividere il lavoro dei processi
    int n;                      //numero di colonne per la sottomatrice (di C) da assegnare a ciascun processo
    int m;                      //numero di righe per la sottomatrice (di C) da assegnare a ciascun processo
    int proc_dims[DIMS];        //[0]: indica le righe della griglia dei processi [1]: indica le colonne
    //variabili di appoggio
    int periods[DIMS];          //array che indica se ciascuna dimensione della matrice deve essere periodica (i.e. circolare) o meno
    //indici ciclo for
    int i;
    int j;
    int k;
    //variabili per misurare le prestazioni
    double start;
    double startAftearCreate;
    double end;
    //variabili per lettura da file
    char * nomeFileA;
    char * nomeFileB;
    char * nomeFileC;
    char * nomeFileCResult;
    MPI_File fdA;
    MPI_File fdB;
    MPI_File fdC;
    MPI_File fdR;
    MPI_File fdRShadow;
    int openResult; //variabile per verificare la corretta apertura del file
    double flops;
    double totalFlops;

    FILE *FileRes;
    FILE *cFile;
    FILE *aFile;
    FILE *bFile;
    //serve per misurare la correttezza del programma 
    double startSingleExecution;
    double endSingleExecution;
    double startSingleComputation;
    
    MPI_Init(&argc, &argv);
    //verifico che venga passata la cartella dove cercare le matrici
    if(argc < 2){
        printf("%d input non valido \n",my_rank);
        printf("mpirun [-n numProc] eseguibile <cartella>\n");
        MPI_Abort(comm_world_copy, EXIT_FAILURE);
    }
    MPI_Comm_dup(MPI_COMM_WORLD, &comm_world_copy); //duplicazione del comunicatore MPI_COMM_WORLD
    MPI_Comm_size(MPI_COMM_WORLD, &p);
    MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);

    MPI_Barrier(comm_world_copy);
    start=MPI_Wtime();

    //inizializzazione di periods a soli false + inizializzazione di proc_dims a soli 0
    for(i=0; i<DIMS; i++) {
        periods[i] = NO;
        proc_dims[i] = 0;   //proc_dims[0] = #righe della mesh di processi; proc_dims[1] = #colonne della mesh di processi
    }
    //definizione (e successiva creazione) della topologia più quadrata possibile per i p processi
    MPI_Dims_create(p, DIMS, proc_dims);
    MPI_Cart_create(comm_world_copy, DIMS, proc_dims, periods, NO, &comm_cart);
    MPI_Cart_coords(comm_cart, my_rank, DIMS,my_coord);
    
    nomeFileA=(char*)malloc(sizeof(char)*(strlen(argv[1])+2));
    nomeFileB=(char*)malloc(sizeof(char)*(strlen(argv[1])+2));
    nomeFileC=(char*)malloc(sizeof(char)*(strlen(argv[1])+2));
    if(nomeFileA==NULL || nomeFileB==NULL || nomeFileC==NULL){
        printf("malloc per la creazione dei file fallita\n");
        return -1;
    }
    sprintf(nomeFileA,"%s/A\0",argv[1]);    
    sprintf(nomeFileB,"%s/B\0",argv[1]);
    sprintf(nomeFileC,"%s/C\0",argv[1]);

    // Apri il file per la lettura
    //openResult = MPI_File_open(MPI_COMM_SELF, nomeFileA, MPI_MODE_RDONLY, MPI_INFO_NULL, &fdA);
    aFile=fopen(nomeFileA,"r");
    if (aFile == NULL) {
        // Gestisci l'errore e termina il programma
        printf("Errore nell'apertura del file A.\n");
        MPI_Abort(MPI_COMM_WORLD, openResult);
        MPI_Finalize();
        return 1;
    }
    //openResult = MPI_File_open(MPI_COMM_SELF,nomeFileB, MPI_MODE_RDONLY, MPI_INFO_NULL, &fdB);
    bFile=fopen(nomeFileB,"r");
    if (bFile == NULL) {
        // Gestisci l'errore e termina il programma
        printf("Errore nell'apertura del file B.\n");
        MPI_Abort(MPI_COMM_WORLD, openResult);
        MPI_Finalize();
        return 1;
    }
    cFile=fopen(nomeFileC,"r");
    if (cFile == NULL) {
        // Gestisci l'errore e termina il programma
        printf("Errore nell'apertura del file C.\n");
        MPI_Abort(MPI_COMM_WORLD, openResult);
        MPI_Finalize();
        return 1;
    }

    //leggo l'header dei file e verifico la coerenza delle matrici
    // MPI_File_read(fdA, &MA,1, MPI_INT, MPI_STATUS_IGNORE);
    // MPI_File_read(fdA, &KA, 1, MPI_INT, MPI_STATUS_IGNORE);
    fread(&MA,sizeof(int),1,aFile);
    fread(&KA,sizeof(int),1,aFile);

    // MPI_File_read(fdB, &KB,1, MPI_INT, MPI_STATUS_IGNORE);
    // MPI_File_read(fdB, &NB, 1, MPI_INT, MPI_STATUS_IGNORE);
    fread(&KB,sizeof(int),1,bFile);
    fread(&NB,sizeof(int),1,bFile);
    // MPI_File_read(fdC, &MC,1, MPI_INT, MPI_STATUS_IGNORE);
    // MPI_File_read(fdC, &NC, 1, MPI_INT, MPI_STATUS_IGNORE);
    fread(&MC,sizeof(int),1,cFile);
    fread(&NC,sizeof(int),1,cFile);
    if(MA!=MC || KA!=KB || NC!=NB){
        fprintf(stderr, "le matrici sono di dimensioni diverse\n");
        MPI_Abort(MPI_COMM_WORLD, -1);
        MPI_Finalize();
        return 1;
    }
    //trasferisco sulle variabili standard e comuni;
    M=MC;
    N=NC;
    K=KA;
    
    //calcolo delle dimensioni di base delle sottomatrici (di C) da assegnare a ciascun processo
    n = N/(proc_dims[1]*nb);
    int resto_colonne = N-n*(proc_dims[1]*nb);
    m = M/(proc_dims[0]*mb);
    int resto_righe = N-n*(proc_dims[0]*mb);
    if(my_coord[1]<resto_colonne) n++;
    if(my_coord[0]<resto_righe) m++;

    float* localA = (float *) malloc(sizeof(float)*m*K);
    float* localB = (float *) malloc(sizeof(float)*n*K);
    float* localC = (float *) malloc(sizeof(float)*n*m);
    //inizializzo localA
     if(!(localA && localB && localC)){
        fprintf(stderr, "non riesco a vare allocazione %d %d %d\n",m,K,n);
        MPI_Abort(comm_world_copy, EXIT_FAILURE);
     }
   
    //MPI_File_seek(fdA,(my_coord[0])*K*sizeof(int),MPI_SEEK_CUR);
    for(int i=0;i<m;i++){ 
        for(int j=0;j<K;j++){
            fseek(aFile,CONVERTOA(i,j),SEEK_SET);
            float data;
            //MPI_File_read(fdA, &(data),1, MPI_INT, MPI_STATUS_IGNORE);
            fread(&data,sizeof(float),1,aFile);
            localA[K*i+j]=data;
        }
    }
    //inizializzo localB
    //MPI_File_seek(fdB,my_coord[1]*sizeof(int),MPI_SEEK_CUR); 
    for(int i=0;i<K;i++){
        for(int j=0;j<n;j++){
            fseek(bFile,CONVERTOB(i,j),SEEK_SET);
            float data;
            fread(&data,sizeof(float),1,bFile);
            localB[K*j+i]=data;
            //MPI_File_seek(fdB,((proc_dims[1]-1))*sizeof(int),MPI_SEEK_CUR);
        }

    }
    //inizializzo localC
    for(i=0;i<m;i++){
        for(j=0;j<n;j++){
            fseek(cFile,CONVERTOC(i,j),SEEK_SET);
            float data;
            fread(&data,sizeof(float),1,cFile);
            localC[i*n+j]=data;
        }
    }
    //stampa la matrice c per i vari processi

    MPI_Barrier(comm_world_copy);
    startAftearCreate=MPI_Wtime();

    MPI_Barrier(comm_world_copy);
    calcolo_Computazionale1(m,n,K,localA,localB,localC); //i->j->z

    MPI_Barrier(comm_world_copy);
    end=MPI_Wtime();
    totalFlops = 2*K*N*M/(end-start);
    flops = 2*K*N*M/(end-startAftearCreate);
    
    nomeFileCResult=(char*)malloc(strlen(argv[1])+6);
    sprintf(nomeFileCResult,"%s/CRes\0",argv[1]);

    //calcolo MAX DIFF
    if(p==1){
            //in caso sono in computazione singola scrivo i risultati sul file
            char *nomeFileCResultShadow=(char*)malloc(strlen(argv[1])+10);
            sprintf(nomeFileCResultShadow,"%s/CRes.txt\0",argv[1]);
            MPI_File_open(MPI_COMM_SELF, nomeFileCResult, MPI_MODE_CREATE | MPI_MODE_WRONLY, MPI_INFO_NULL, &fdR);
            MPI_File_open(MPI_COMM_SELF, nomeFileCResultShadow, MPI_MODE_CREATE | MPI_MODE_WRONLY, MPI_INFO_NULL, &fdRShadow);
            
            MPI_File_write(fdR, &M, 1, MPI_INT, MPI_STATUS_IGNORE);
            MPI_File_write(fdR, &N, 1, MPI_INT, MPI_STATUS_IGNORE);
    
            char buffer[50];
            sprintf(buffer,"%d,%d\n\0",M,N);
            MPI_File_write(fdRShadow, &buffer,strlen(buffer), MPI_CHAR, MPI_STATUS_IGNORE);
            for(int i=0;i<M;i++){
                char buffer2[50];
                for(int j=0;j<N-1;j++){
                    sprintf(buffer2,"%f,\0",localC[i*N+j]);
                    MPI_File_write(fdR, &(localC[i*N+j]), 1, MPI_FLOAT, MPI_STATUS_IGNORE);
                    MPI_File_write(fdRShadow, &buffer2,strlen(buffer2), MPI_CHAR, MPI_STATUS_IGNORE);
                }
                sprintf(buffer2,"%f\n\0",localC[i*N+N-1]);
                MPI_File_write(fdR, &(localC[i*N+N-1]), 1, MPI_FLOAT, MPI_STATUS_IGNORE);
                MPI_File_write(fdRShadow, &buffer2, strlen(buffer2), MPI_CHAR, MPI_STATUS_IGNORE);
            }

            MPI_File_close(&fdR);
            MPI_File_close(&fdRShadow);
            printf("{\"processo\":%d,\"tempo_senza_creazione\":%f,\"tempo_totale\":%f,\"flop_senza_creazione\":%f,\"flop_totali\":%f}\n",
                my_rank, end-startAftearCreate, end-start, flops, totalFlops);

    }else{
        
        FileRes=fopen(nomeFileCResult,"r");
        if(FileRes!=NULL){
            //controllo la differenza solo se esiste il file dei risultati 
            fread(&MR,sizeof(int),1,FileRes);
            fread(&NR,sizeof(int),1,FileRes);
            if(MR!= M || NR !=N){
                fprintf(stderr, "le matrici sono dei risultati sono di dimensioni diverse\n");
                MPI_Abort(MPI_COMM_WORLD, -1);
                MPI_Finalize();
                return 1;
            }
            double maxErr=0.0;
            double relative_err = 0.0;
            for(int i=0;i<m;i++){
                for(int j=0;j<n;j++){
                    fseek(FileRes,CONVERTOC(i,j),SEEK_SET);
                    float data;
                    fread(&data,sizeof(float),1,FileRes);
                    if(maxErr<(localC[i*n+j] - data)){
                        maxErr = localC[i*n+j] - data;
                        relative_err = maxErr/data;
                    }
                }
            }
           printf("{\"processo\":%d,\"max_Error\":%f,\"relative_err\":%lf,\"tempo_senza_creazione\":%f,\"tempo_totale\":%f,\"flop_senza_creazione\":%f,\"flop_totali\":%f},\n",
               my_rank, maxErr,relative_err, end-startAftearCreate, end-start, flops, totalFlops);
        }else{
            printf("{\"processo\":%d,\"tempo_senza_creazione\":%f,\"tempo_totale\":%f,\"flop_senza_creazione\":%f,\"flop_totali\":%f},\n",
               my_rank, end-startAftearCreate, end-start, flops, totalFlops);
        }
    }  
    free(localA);
    free(localB);
    free(localC);
    MPI_Finalize();
    return 0;
}
