import pandas as pd
import numpy as np
import sys
import json 
import matplotlib.pyplot as plt
from pandasql import sqldf
def funcMean(fileName):
    with open(fileName, "r") as file:
        data = json.load(file)
    # Estrai i dati relevanti in una lista di dizionari
    processed_data = []
    for entry in data:
        for result in entry['result']:
            processed_data.append({
                'XDB': entry['XDB'],
                'YDB': entry['YDB'],
                'M': entry['M'],
                'K': entry['K'],
                'AsseX':(entry['M'],entry['K']),
                'GFLOPS': result['GFLOPS']
            })

    # Crea un DataFrame da processed_data
    df1 = pd.DataFrame(processed_data)

    # Calcola la media di GFLOPS per ogni oggetto JSON
    return df1.groupby(['XDB', 'YDB','K','M','AsseX'])['GFLOPS'].mean().reset_index()

def main():
    # Check su se il programma è stato invocato con il parametro adeguato
    print(sys.argv[1])
    if len(sys.argv) < 2 or not (sys.argv[1] == "squared" or sys.argv[1] == "rectangular" or sys.argv[1] == "special"):
        print("Usage: python performance.py <folder_name>")
        exit(-1)

    
    # Calcola la media di GFLOPS per ogni oggetto JSON
    df_cuda_prod = funcMean(sys.argv[1] + "/file_cuda_prod.json").sort_values(["K","M"])
    df_cuda_prod_ms = funcMean(sys.argv[1] + "/file_cuda_prod_ms.json").sort_values(["K","M"])
    df_cuda_prod_v2 = funcMean(sys.argv[1] + "/file_cuda_prod_v2.json").sort_values(["K","M"])
    
    df_cuda_prod_ms = df_cuda_prod_ms[df_cuda_prod_ms["K"]*df_cuda_prod_ms["YDB"]*8<49000]
    
    # Stampa il DataFrame risultante

    # Combina i dataframe
    print(df_cuda_prod)
    print(df_cuda_prod_ms)
    print(df_cuda_prod_v2)
    fig, axes = plt.subplots(nrows=2, ncols=1, figsize=(10, 10))
    
    for (xdb, ydb), group in df_cuda_prod.groupby(['XDB', 'YDB']):
        ax=int((xdb/512)-1)
        group.plot(x='AsseX', y='GFLOPS',kind="bar", ax=axes[ax], label=f'df_cuda_prod',width=0.3, position=1)
    for (xdb, ydb), group in df_cuda_prod_ms.groupby(['XDB', 'YDB']):
        ax=int((xdb/512)-1)
        group.plot(x='AsseX', y='GFLOPS',kind="bar", ax=axes[ax], label=f'df_cuda_prod_ms',width=0.3,position=2,color="g")
    for (xdb, ydb), group in df_cuda_prod_v2.groupby(['XDB', 'YDB']):
        ax=int((xdb/512)-1)
        group.plot(x='AsseX', y='GFLOPS',kind="bar" , ax=axes[ax], label=f'df_cuda_prod_v2',width=0.3,color="r",position=0)

    for i, ax in enumerate(axes):
        ax.set_title(f'Andamento GFLOPS - XDB={512*(i+1)}, YDB={int(1024/(512*(i+1)))}')
        ax.set_xlabel('K & M')
        ax.set_ylabel('GFLOPS')
        ax.set_yscale("linear")
        ax.set_xlim((ax.get_xlim()[0]-0.4,ax.get_xlim()[1]+0.4))

    plt.tight_layout()
    plt.savefig('andamento_GFLOPS_'+sys.argv[1]+'.pdf')

    plt.show()
    # # Eliminazione delle entry di df2 relative alle esecuzioni che richiedono più shared memory del massimo consentito
    # df2 = df2[df2["K"]*df2["YDB"]*8<49000]

    # # Unione dei DataFrame in base alle colonne XDB, YBD, M, K
    # merged_df = pd.merge(df1, df2, on=['XDB','YDB','M','K'], suffixes=('_df1', '_df2'))

    # # Calcolo del valore massimo di GFLOPS per ogni quadrupla (XDB, YDB, M, K)
    # merged_df['Max_GFLOPS'] = merged_df[['GFLOPS_df1', 'GFLOPS_df2']].max(axis=1)

    # # Confronto tra i valori massimi per determinare quale DataFrame ha il valore maggiore
    # merged_df['Max_GFLOPS_df'] = merged_df.apply(lambda row: 'df1' if row['Max_GFLOPS'] == row['GFLOPS_df1'] else 'df2', axis=1)

    # # Calcolo della differenza tra il numero di GFLOPS nel caso senza shared memory e il numero di GFLOPS nel caso con shared memory
    # merged_df["DIFF_df"]=abs(merged_df["GFLOPS_df2"]-merged_df["GFLOPS_df1"])

    # """
    # merged_df=merged_df[merged_df["DIFF_df"]<2]
    # tabellaDF1 = merged_df[merged_df["Max_GFLOPS_df"]=="df1"]
    # tabellaDF2 = merged_df[merged_df["Max_GFLOPS_df"]=="df2"]
    # """

    # sorted_df=merged_df.sort_values("Max_GFLOPS") 
    # # Stampa del DataFrame risultante
    # print(sorted_df)



if __name__ == "__main__":
    main()
