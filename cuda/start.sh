#! /bin/bash
make

mkdir squared
mkdir rectangular
mkdir special

echo "[" > squared/file_cuda_prod.json
echo "[" > squared/file_cuda_prod_v2.json
echo "[" > squared/file_cuda_prod_ms.json
echo "[" > squared/file_cuda_prod_ms_v2.json
for XBD in {512,1024} #{1,2,4,16,32,64,128,256,512,1024}
do    
    YBD=$((1024 / $XBD))
    echo "$XBD, $YBD"
    for K in {500,750,1000,2000,3000,5000,7000,10000,12000,15000}
    do
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$K,\"K\":$K,\"result\":[ " >> squared/file_cuda_prod.json
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$K,\"K\":$K,\"result\":[ " >> squared/file_cuda_prod_v2.json
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$K,\"K\":$K,\"result\":[ " >> squared/file_cuda_prod_ms.json
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$K,\"K\":$K,\"result\":[ " >> squared/file_cuda_prod_ms_v2.json
        for i in {1..9}
        do
            echo "{" >> squared/file_cuda_prod.json
            echo "{" >> squared/file_cuda_prod_v2.json
            echo "{" >> squared/file_cuda_prod_ms.json
            echo "{" >> squared/file_cuda_prod_ms_v2.json
            
            ./Cuda-prod $K $K $K n $XBD $YBD >> squared/file_cuda_prod.json
            ./Cuda-prod-v2 $K $K $K n $XBD $YBD >> squared/file_cuda_prod_v2.json
            ./Cuda-prod-ms-read $K $K $K n $XBD $YBD >> squared/file_cuda_prod_ms.json
            ./Cuda-prod-ms-v2 $K $K $K n >> squared/file_cuda_prod_ms_v2.json
            
            echo "}," >> squared/file_cuda_prod.json
            echo "}," >> squared/file_cuda_prod_v2.json
            echo "}," >> squared/file_cuda_prod_ms.json
            echo "}," >> squared/file_cuda_prod_ms_v2.json

        done
        echo "{" >> squared/file_cuda_prod.json
        echo "{" >> squared/file_cuda_prod_v2.json
        echo "{" >> squared/file_cuda_prod_ms.json
        echo "{" >> squared/file_cuda_prod_ms_v2.json
        
        ./Cuda-prod $K $K $K n $XBD $YBD >> squared/file_cuda_prod.json
        ./Cuda-prod-v2 $K $K $K n $XBD $YBD >> squared/file_cuda_prod_v2.json
        ./Cuda-prod-ms-read $K $K $K n $XBD $YBD >> squared/file_cuda_prod_ms.jsonv
        ./Cuda-prod-ms-v2 $K $K $K n >> squared/file_cuda_prod_ms_v2.json

        echo "}]" >> squared/file_cuda_prod.json
        echo "}]" >> squared/file_cuda_prod_v2.json
        echo "}]" >> squared/file_cuda_prod_ms.json
        echo "}]" >> squared/file_cuda_prod_ms_v2.json
        
        
        echo "}," >> squared/file_cuda_prod.json
        echo "}," >> squared/file_cuda_prod_v2.json
        echo "}," >> squared/file_cuda_prod_ms.json
        echo "}," >> squared/file_cuda_prod_ms_v2.json
    done
done
truncate -s -2 squared/file_cuda_prod.json
truncate -s -2 squared/file_cuda_prod_v2.json
truncate -s -2 squared/file_cuda_prod_ms.json
truncate -s -2 squared/file_cuda_prod_ms_v2.json

echo "]" >> squared/file_cuda_prod.json
echo "]" >> squared/file_cuda_prod_v2.json
echo "]" >> squared/file_cuda_prod_ms.json
echo "]" >> squared/file_cuda_prod_ms_v2.json

echo "[" > rectangular/file_cuda_prod.json
echo "[" > rectangular/file_cuda_prod_v2.json
echo "[" > rectangular/file_cuda_prod_ms.json
echo "[" > rectangular/file_cuda_prod_ms_v2.json
for XBD in {512,1024} #{1,2,4,16,32,64,128,256,512,1024}
do    
    YBD=$((1024 / $XBD))
    echo "$XBD, $YBD"
    M=16384 #2**14
    for K in {32,64,128,256,512,1024,2048,4096,8192}
    do
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> rectangular/file_cuda_prod.json
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> rectangular/file_cuda_prod_v2.json
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> rectangular/file_cuda_prod_ms.json
        echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> rectangular/file_cuda_prod_ms_v2.json
        for i in {1..9}
        do
            echo "{" >> rectangular/file_cuda_prod.json
            echo "{" >> rectangular/file_cuda_prod_v2.json
            echo "{" >> rectangular/file_cuda_prod_ms.json
            echo "{" >> rectangular/file_cuda_prod_ms_v2.json

            ./Cuda-prod $M $K $M n $XBD $YBD >> rectangular/file_cuda_prod.json
            ./Cuda-prod-v2 $M $K $M n $XBD $YBD >> rectangular/file_cuda_prod_v2.json
            ./Cuda-prod-ms-read $M $K $M n $XBD $YBD >> rectangular/file_cuda_prod_ms.json
            ./Cuda-prod-ms-v2 $K $K $K n >> rectangular/file_cuda_prod_ms_v2.json

            echo "}," >> rectangular/file_cuda_prod.json
            echo "}," >> rectangular/file_cuda_prod_v2.json
            echo "}," >> rectangular/file_cuda_prod_ms.json
            echo "}," >> rectangular/file_cuda_prod_ms_v2.json
        done
        echo "{" >> rectangular/file_cuda_prod.json
        echo "{" >> rectangular/file_cuda_prod_v2.json
        echo "{" >> rectangular/file_cuda_prod_ms.json
        echo "{" >> rectangular/file_cuda_prod_ms_v2.json
        
        ./Cuda-prod $M $K $M n $XBD $YBD >> rectangular/file_cuda_prod.json
        ./Cuda-prod-v2 $M $K $M n $XBD $YBD >> rectangular/file_cuda_prod_v2.json
        ./Cuda-prod-ms-read $M $K $M n $XBD $YBD >> rectangular/file_cuda_prod_ms.json
        ./Cuda-prod-ms-v2 $M $K $M n >> squared/file_cuda_prod_ms_v2.json
        
        echo "}]" >> rectangular/file_cuda_prod.json
        echo "}]" >> rectangular/file_cuda_prod_v2.json
        echo "}]" >> rectangular/file_cuda_prod_ms.json
        echo "}]" >> rectangular/file_cuda_prod_ms_v2.json
        
        echo "}," >> rectangular/file_cuda_prod.json
        echo "}," >> rectangular/file_cuda_prod_v2.json
        echo "}," >> rectangular/file_cuda_prod_ms.json
        echo "}," >> rectangular/file_cuda_prod_ms_v2.json

    done
done
truncate -s -2 rectangular/file_cuda_prod.json
truncate -s -2 rectangular/file_cuda_prod_v2.json
truncate -s -2 rectangular/file_cuda_prod_ms.json
truncate -s -2 rectangular/file_cuda_prod_ms_v2.json

echo "]" >> rectangular/file_cuda_prod.json
echo "]" >> rectangular/file_cuda_prod_v2.json
echo "]" >> rectangular/file_cuda_prod_ms_v2.json



echo "[" > special/file_cuda_prod.json
echo "[" > special/file_cuda_prod_v2.json
echo "[" > special/file_cuda_prod_ms.json
echo "[" > special/file_cuda_prod_ms_v2.json
for XBD in {512,1024} #{1,2,4,16,32,64,128,256,512,1024}
do    
    YBD=$((1024 / $XBD))
    echo "$XBD, $YBD"
    for K in {32,64,128,256,512,1024,2048}
    do
        for M in {256,512,1024,2048,4096,8192}
        do
            echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> special/file_cuda_prod.json
            echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> special/file_cuda_prod_v2.json
            echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> special/file_cuda_prod_ms.json
            echo "{ \"XDB\":$XBD,\"YDB\":$YBD,\"M\":$M,\"K\":$K,\"result\":[ " >> special/file_cuda_prod_ms_v2.json

            for i in {1..9}
            do
                echo "{" >> special/file_cuda_prod.json
                echo "{" >> special/file_cuda_prod_v2.json
                echo "{" >> special/file_cuda_prod_ms.json
                echo "{" >> special/file_cuda_prod_ms_v2.json
                
                ./Cuda-prod $M $K $M n $XBD $YBD >> special/file_cuda_prod.json
                ./Cuda-prod-v2 $M $K $M n $XBD $YBD >> special/file_cuda_prod_v2.json
                ./Cuda-prod-ms-read $M $K $M n $XBD $YBD >> special/file_cuda_prod_ms.json
                ./Cuda-prod-ms-v2 $M $K $M n >> special/file_cuda_prod_ms_v2.json
                
                echo "}," >> special/file_cuda_prod.json
                echo "}," >> special/file_cuda_prod_v2.json
                echo "}," >> special/file_cuda_prod_ms.json
                echo "}," >> special/file_cuda_prod_ms_v2.json

            done
            echo "{" >> special/file_cuda_prod.json
            echo "{" >> special/file_cuda_prod_v2.json
            echo "{" >> special/file_cuda_prod_ms.json
            echo "{" >> special/file_cuda_prod_ms_v2.json

            ./Cuda-prod $M $K $M n $XBD $YBD >> special/file_cuda_prod.json
            ./Cuda-prod-v2 $M $K $M n $XBD $YBD >> special/file_cuda_prod_v2.json
            ./Cuda-prod-ms-read $M $K $M n $XBD $YBD >> special/file_cuda_prod_ms.json
            ./Cuda-prod-ms-v2 $M $K $M n >> special/file_cuda_prod_ms_v2.json
            
            echo "}]" >> special/file_cuda_prod.json
            echo "}]" >> special/file_cuda_prod_v2.json
            echo "}]" >> special/file_cuda_prod_ms.json
            echo "}]" >> special/file_cuda_prod_ms_v2.json

            echo "}," >> special/file_cuda_prod.json
            echo "}," >> special/file_cuda_prod_v2.json
            echo "}," >> special/file_cuda_prod_ms.json
            echo "}," >> special/file_cuda_prod_ms_v2.json
        done
    done
done
truncate -s -2 special/file_cuda_prod.json
truncate -s -2 special/file_cuda_prod_v2.json
truncate -s -2 special/file_cuda_prod_ms.json
truncate -s -2 special/file_cuda_prod_ms_v2.json

echo "]" >> special/file_cuda_prod.json
echo "]" >> special/file_cuda_prod_v2.json
echo "]" >> special/file_cuda_prod_ms.json
echo "]" >> special/file_cuda_prod_ms.json
