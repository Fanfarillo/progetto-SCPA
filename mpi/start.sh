#! /bin/bash
mkdir target
mkdir kobero-result
mkdir fanfa-result

module load gnu mpich cuda;
mpicc MPI-matrix-gen.c -o target/MPI-matrix-gen -O3 -march=native
mpicc MPI-prod-kobero.c -o target/MPI-prod-kobero -O3 -march=native
mpicc MPI-prod-fanfa.c -o target/MPI-prod-fanfa -lm -O3 -march=native
cd target

seed=123456789

for K in {500,750,1000,2000,5000,10000}
do 
     dir="kobero-squared-$K"
     mkdir $dir
     mpirun -n 3 ./MPI-matrix-gen $seed $dir $K $K $K
    if [ $K -le 2000 ]; then
        mpirun -n 1 ./MPI-prod-kobero $dir > ../kobero-result/result-$K-1
    fi
    for p in {4,8,12,16,20}
    do
        echo "[" > ../kobero-result/result-$K-$p

        for n in {1..9}
        do
            echo "dimensione problema: $K numero processi: $p ";
            echo "{\"iterazione\":$n,\"vettore\":[" >> ../kobero-result/result-$K-$p
            mpirun -n $p ./MPI-prod-kobero $dir >> ../kobero-result/result-$K-$p
            echo "{}]}," >> ../kobero-result/result-$K-$p
        done
        echo "{\"iterazione\":10,\"vettore\":[" >> ../kobero-result/result-$K-$p
        mpirun -n $p ./MPI-prod-kobero $dir >> ../kobero-result/result-$K-$p
        echo "{}]}]" >> ../kobero-result/result-$K-$p

    done
done



for K in {32,64,128,256}
do
    dir="kobero-rectangular-$K"
    mkdir $dir
    mpirun -n 3 MPI-matrix-gen $seed $dir 15000 15000 $K
    mpirun -n 1 MPI-prod-kobero $dir > ../kobero-result/result-$K-1

    for p in {4,8,12,16,20}
    do
        echo "[" > ../kobero-result/result-$K-$p

        for n in {1..9}
        do
            echo "dimensione problema: $K numero processi: $p ";
            echo "{\"iterazione\":$n,\"vettore\":[" >> ../kobero-result/result-$K-$p
            mpirun -n $p MPI-prod-kobero $dir >> ../kobero-result/result-$K-$p
            echo "{}]}," >> ../kobero-result/result-$K-$p
        done
        echo "{\"iterazione\":10,\"vettore\":[" >> ../kobero-result/result-$K-$p
        mpirun -n $p MPI-prod-kobero $dir >> ../kobero-result/result-$K-$p
        echo "{}]}]" >> ../kobero-result/result-$K-$p

    done
done



for K in {500,10000}
do 
    dir="fanfa-squared-$K"
    mkdir $dir
    mpirun -n 3 ./MPI-matrix-gen $seed $dir $K $K $K
    if [ $K -le 2000 ]; then
       mpirun -n 1 ./MPI-prod-fanfa $dir 1 1 > ../fanfa-result/result-$K-1-1
    fi
    for kb in {1,2,4,8,16}
    do

        for p in {4,8,12,16,20}
        do
            echo "[" > ../fanfa-result/result-$K-$kb-$p

            for n in {1..9}
            do
                echo "dimensione problema: $K numero processi: $p ";
                echo "{\"iterazione\":$n,\"vettore\":[" >> ../fanfa-result/result-$K-$kb-$p
                mpirun -n $p ./MPI-prod-fanfa $dir $kb $kb >> ../fanfa-result/result-$K-$kb-$p
                echo "{}]}," >> ../fanfa-result/result-$K-$kb-$p
            done
            echo "{\"iterazione\":10,\"vettore\":[" >> ../fanfa-result/result-$K-$kb-$p
            mpirun -n $p ./MPI-prod-fanfa $dir $kb $kb >> ../fanfa-result/result-$K-$kb-$p
            echo "{}]}]" >> ../fanfa-result/result-$K-$kb-$p

        done
    done
done



for K in {32,64,128,256}
do 
    dir="fanfa-rectangular-$K"
    mkdir $dir
    mpirun -n 3 MPI-matrix-gen $seed $dir 15000 15000 $K
    mpirun -n 1 MPI-prod-fanfa $dir 1 1 > ../fanfa-result/result-$K-1-1

    for kb in {1,2,4,8,16}
    do

        for p in {4,8,12,16,20}
        do
            echo "[" > ../fanfa-result/result-$K-$kb-$p

            for n in {1..9}
            do
                echo "dimensione problema: $K numero processi: $p ";
                echo "{\"iterazione\":$n,\"vettore\":[" >> ../fanfa-result/result-$K-$kb-$p
                mpirun -n $p MPI-prod-fanfa $dir $kb $kb >> ../fanfa-result/result-$K-$kb-$p
                echo "{}]}," >> ..fanfa-result/result-$K-$kb-$p
            done
            echo "{\"iterazione\":10,\"vettore\":[" >> ../fanfa-result/result-$K-$kb-$p
            mpirun -n $p MPI-prod-fanfa $dir $kb $kb >> ../fanfa-result/result-$K-$kb-$p
            echo "{}]}]" >> ../fanfa-result/result-$K-$kb-$p

        done
    done
done
