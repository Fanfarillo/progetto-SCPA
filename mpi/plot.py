import json
import matplotlib.pyplot as plt
import pandas as pd
def grafico_confronto(l1,l2,name,metrica):
    data1= pd.DataFrame(l1)
    if(metrica=="Speed_up" or metrica=="relative_err"):
        data1=data1[data1["K"]<5000]
    data1 = data1[data1['processi'] == 20]  # Filtraggio dei dati per il valore di 'processi'
    plt.plot(data1["K"],data1[metrica], label=f'divisione di C')

    data2= pd.DataFrame(l2)
    if(metrica=="Speed_up" or metrica=="relative_err"):
        data2=data2[data2["K"]<5000]
    data2 = data2[data2['processi'] == 20]  # Filtraggio dei dati per il valore di 'processi'
    for kb, group in data2.groupby('kb'):
        plt.plot(group['K'], group[metrica], label=f'divisione di A kb={kb}')     
    plt.grid(True)
    plt.xlabel('K')
    plt.ylabel(metrica)
    plt.title(f'Andamento '+metrica)
    plt.legend()
    nome_file = f"image/confronto_{name}_{metrica}.svg"
    plt.savefig(nome_file, format='svg')
    nome_file = f"image/confronto_{name}_{metrica}.jpeg"
    plt.savefig(nome_file, format='jpeg')
    plt.close()

def grafici_fanfa_confronto_kb(lista_dizionari,name,metrica):
    processi = set()  # Insieme per memorizzare tutti i valori di 'processi'
    for dizionario in lista_dizionari:
        processi.add(dizionario['processi'])
    
    for p in processi:
        # Creazione del DataFrame per questo valore di 'processi'
        data = pd.DataFrame(lista_dizionari)
        if(metrica=="Speed_up" or metrica=="relative_err"):
            data=data[data["K"]<5000]
        data = data[data['processi'] == p]  # Filtraggio dei dati per il valore di 'processi'
        
        # Creazione dei grafici per questo valore di 'processi'
        for kb, group in data.groupby('kb'):
            plt.plot(group['K'], group[metrica], label=f'kb={kb}')
        plt.grid(True)
        plt.xlabel('K')
        plt.ylabel(metrica)
        plt.title(f'Andamento '+metrica)
        plt.legend()
        nome_file = f"image/fanfa_{name}_{metrica}_kb_p{p}.svg"
        plt.savefig(nome_file, format='svg')
        nome_file = f"image/fanfa_{name}_{metrica}_kb_p{p}.jpeg"
        plt.savefig(nome_file, format='jpeg')
        plt.close()
def grafico_kobero(lista_dizionari,name,metrica):
    processi = set()  # Insieme per memorizzare tutti i valori di 'processi'
    for dizionario in lista_dizionari:
        processi.add(dizionario['processi'])
    # Creazione del DataFrame per questo valore di 'processi'
    data = pd.DataFrame(lista_dizionari)
    if(metrica=="Speed_up" or metrica=="relative_err"):
        data=data[data["K"]<5000]
    for p, group in data.groupby('processi'):
        plt.plot(group['K'], group[metrica], label=f'process={p}')
    plt.grid(True)
    plt.xlabel('K')
    plt.ylabel(metrica)
    plt.title(f'Andamento '+metrica)
    plt.legend()
    nome_file = f"image/kobero_{name}_{metrica}.svg"
    plt.savefig(nome_file, format='svg')
    nome_file = f"image/kobero_{name}_{metrica}.jpeg"
    plt.savefig(nome_file, format='jpeg')
    plt.close()

def calcola_valori_medi(file_path,max_values):
    # Carica i dati dal file
    with open(file_path) as f:
        data = json.load(f)
    # Dizionario per mantenere i valori massimi per ogni attributo
    # Trova i valori massimi per ogni attributo tra le iterazioni
    for item in data:
        for attributo, valori in item['vettore'][0].items():
            if attributo != 'processo':
                # Ottieni solo i valori non nulli per evitare errori
                valori_non_nulli = [x[attributo] for x in item['vettore'] if x.get(attributo) is not None]
                if valori_non_nulli:
                    max_values[attributo].append(max(valori_non_nulli))
    media_valori_massimi={}
    # Calcola la media dei valori massimi per ogni attributo
    for attributo, valori in max_values.items():
        if(len(valori)!=0):
           media_valori_massimi[attributo]= sum(valori)/len(valori)
        else:
            media_valori_massimi[attributo]=0
    return media_valori_massimi

def main():
    fanfa_list_square=[]
    #carico i risultati del fanfa square
    for dim in [500,750,1000,2000,5000,10000]:
        try:
            with open(f"fanfa-result/result-{dim}-1-1") as f:
                valoreSing = json.load(f)
        except:
            valoreSing["tempo_senza_creazione"]=1
        for kb in [1,2,4,8,16]:   
            for p in [4,8,12,16,20]:
                app={}
                app["M"]=dim
                app["K"]=dim
                app["processi"]=p
                app["kb"]=kb
                max_values = {
                        "max_err": [],
                        "relative_err": [],
                        "tempo_senza_creazione": [],
                        "tempo_totale": [],
                        "flop_senza_creazione": [],
                        "flop_totali": []
                    }
                valori_medi = calcola_valori_medi("fanfa-result/result-"+str(dim)+"-"+str(kb)+"-"+str(p),max_values=max_values)
                app["result"]=valori_medi
                if "relative_err" in valori_medi.keys():
                    app["relative_err"]=valori_medi["relative_err"]
                else:
                    app["relative_err"]=0
                app["flop_totale"]=(2*dim*dim*dim)/valori_medi["tempo_totale"]
                app["Gflop"]=((2*dim*dim*dim)/valori_medi["tempo_senza_creazione"])/1000000000                
                app["Speed_up"]=valoreSing["tempo_senza_creazione"]/valori_medi["tempo_senza_creazione"]
                fanfa_list_square.append(app)
    fanfa_list_rect=[]
    for dim in [32,64,128]:
        try:
            with open(f"fanfa-result/result-{dim}-1-1") as f:
                valoreSing = json.load(f)
        except:
            valoreSing["tempo_senza_creazione"]=1
        for kb in [1,2,4,8,16]:
            for p in [4,8,12,16,20]:
                app={}
                app["M"]=15000
                app["K"]=dim
                app["processi"]=p
                app["kb"]=kb
                max_values = {
                        "max_err": [],
                        "relative_err": [],
                        "tempo_senza_creazione": [],
                        "tempo_totale": [],
                        "flop_senza_creazione": [],
                        "flop_totali": []
                    }
                valori_medi = calcola_valori_medi("fanfa-result/result-"+str(dim)+"-"+str(kb)+"-"+str(p),max_values=max_values)
                app["result"]=valori_medi
                if "relative_err" in valori_medi.keys():
                    app["relative_err"]=valori_medi["relative_err"]
                else:
                    app["relative_err"]=0
                app["flop_totale"]=(2*15000*15000*dim)/valori_medi["tempo_totale"]
                app["Gflop"]=((2*15000*15000*dim)/valori_medi["tempo_senza_creazione"])/1000000000
                app["Speed_up"]=valoreSing["tempo_senza_creazione"]/valori_medi["tempo_senza_creazione"]
                fanfa_list_rect.append(app)
    kobero_list_square=[]
    for dim in [500,750,1000,2000,5000,10000]:
        try:
            with open(f"kobero-result/result-{dim}-1") as f:
                valoreSing = json.load(f)
        except:
            valoreSing["tempo_senza_creazione"]=1
        for p in [4,8,12,16,20]:
            app={}
            app["M"]=dim
            app["K"]=dim
            app["processi"]=p
            max_values = {
                        "max_Error": [],
                        "number_error": [],
                        "tempo_senza_creazione": [],
                        "tempo_totale": [],
                        "flop_senza_creazione": [],
                        "flop_totali": []
                    }
            valori_medi = calcola_valori_medi("kobero-result/result-"+str(dim)+"-"+str(p),max_values=max_values)
            app["result"]=valori_medi
            if "relative_err" in valori_medi.keys():
                app["relative_err"]=valori_medi["relative_err"]
            else:
                app["relative_err"]=0
            app["flop_totale"]=(2*dim*dim*dim)/valori_medi["tempo_totale"]
            app["Gflop"]=((2*dim*dim*dim)/valori_medi["tempo_senza_creazione"])/1000000000
            app["Speed_up"]=valoreSing["tempo_senza_creazione"]/valori_medi["tempo_senza_creazione"]     
            kobero_list_square.append(app)
    kobero_list_rect=[]
    for dim in [32,64,128]:
        try:
            with open(f"kobero-result/result-{dim}-1") as f:
                valoreSing = json.load(f)
        except:
            valoreSing["tempo_senza_creazione"]=1
        for p in [4,8,12,16,20]:
            app={}
            app["M"]=15000
            app["K"]=dim
            app["processi"]=p
            max_values = {
                        "max_Error": [],
                        "number_error": [],
                        "relative_err":[],
                        "tempo_senza_creazione": [],
                        "tempo_totale": [],
                        "flop_senza_creazione": [],
                        "flop_totali": []
                    }
            valori_medi = calcola_valori_medi("kobero-result/result-"+str(dim)+"-"+str(p),max_values=max_values)
            if "relative_err" in valori_medi.keys():
                app["relative_err"]=valori_medi["relative_err"]
            else:
                app["relative_err"]=0
            app["result"]=valori_medi
            app["flop_totale"]=(2*15000*15000*dim)/valori_medi["tempo_totale"]
            app["Gflop"]=((2*15000*15000*dim)/valori_medi["tempo_senza_creazione"])/1000000000
            app["Speed_up"]=valoreSing["tempo_senza_creazione"]/valori_medi["tempo_senza_creazione"]         
            kobero_list_rect.append(app)
    grafici_fanfa_confronto_kb(fanfa_list_square,"square",'Gflop')
    grafici_fanfa_confronto_kb(fanfa_list_rect,"rectangular","Gflop")
    grafici_fanfa_confronto_kb(fanfa_list_square,"square","Speed_up")
    grafici_fanfa_confronto_kb(fanfa_list_rect,"rectangular","Speed_up")

    grafico_kobero(kobero_list_square,"square","Gflop")
    grafico_kobero(kobero_list_square,"square","Speed_up")

    grafico_kobero(kobero_list_rect,"rectangular","Gflop")
    grafico_kobero(kobero_list_rect,"rectangular","Speed_up")

    grafico_confronto(kobero_list_square,fanfa_list_square,"square","Gflop")
    grafico_confronto(kobero_list_rect,fanfa_list_rect,"rectangular","Gflop")
    grafico_confronto(kobero_list_square,fanfa_list_square,"square","Speed_up")
    grafico_confronto(kobero_list_rect,fanfa_list_rect,"rectangular","Speed_up")
    
    grafici_fanfa_confronto_kb(fanfa_list_square,"square","relative_err")
    grafici_fanfa_confronto_kb(fanfa_list_rect,"rectangular","relative_err")


if __name__ == "__main__":
    main()
