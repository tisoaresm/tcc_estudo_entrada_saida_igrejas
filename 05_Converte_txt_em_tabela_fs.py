#!/usr/bin/env python
# coding: utf-8

# In[1]:

import pandas as pd
import os
import re
import pyreadstat
import numpy as np
from decimal import Decimal

# In[255]:

config = pd.read_excel("config.xlsx")
config.set_index('Modelo', drop=True, inplace=True)

# In[256]:

def separar_coeficiente_asteriscos(valor):
    match = re.match(r"([0-9.]+)(\*+)?", valor)
    if match:
        coef = match.group(1)
        asteriscos = match.group(2) if match.group(2) else ''
        return asteriscos
    return ''

# In[257]:

dic = {'Churches_USA_Data':'Subset1',
       'Evangelical_And_Mainline_Churches_USA_Data':'Subset2',
       'Catholic_Churches_USA_Data':'Subset3'}

# In[258]:

caminho = 'Outputs_Regressoes'
arquivos_txt = [arquivo for arquivo in os.listdir(caminho) if arquivo.endswith('.txt') and arquivo.startswith('Regression')]
# arquivos_txt = [arquivos_txt[-1]]
for nome_arquivo in arquivos_txt:
    
    # identificando modelo
    modelo = nome_arquivo[19:nome_arquivo.find('_',19)]
    subset = nome_arquivo[26:].split('.')[0]
    
    # Lista para armazenar as linhas do arquivo
    linhas = []

    # Le o arquivo e armazena as linhas na lista
    with open(caminho+'//'+nome_arquivo, 'r') as arquivo:
        for linha in arquivo:
            linhas.append(linha.strip())

    # Remove linhas em branco
    linhas = [linha for linha in linhas if linha]
    linhas = linhas[1:]
    linhas = linhas[:-2]
    linhas = '\n'.join(linhas).replace('\n(','\t(')
    linhas = linhas.split('\n')

    # Cria um dicionario para armazenar os dados
    dados = {'VARIABLES': [], 'Coeficiente': [], 'Erro_Padrao': []}
  
    # Itera sobre as linhas para extrair os dados
    for linha in linhas:
        partes = linha.split()

        # Verifica se a linha contem dados relevantes
        if len(partes) >= 2:
            variavel = partes[0]
            coeficiente = partes[1]
            erro_padrao = partes[-1]
            
            if not erro_padrao.startswith('('):
                erro_padrao = '-'

            dados['VARIABLES'].append(variavel)
            dados['Coeficiente'].append(coeficiente)
            dados['Erro_Padrao'].append(erro_padrao)

    # Salvando os coeficientes numa tabela excel
    df = pd.DataFrame(dados)
    df.to_excel(caminho+'\\'+dic[subset]+"_"+".".join(nome_arquivo.split('.')[:-1]).replace(modelo+'_','')+'_'+modelo+'.xlsx', index=False)
    
# # Concatenar modelos

# In[14]:

def needs_more_than_five_decimals(number_str):
    number = Decimal(number_str)
    # Ajuste para remover a notacao cientifica e obter a precisao total
    number_str_full = f"{number:.30f}".rstrip('0').rstrip('.')
    # Contar os digitos apos o ponto decimal
    if '.' in number_str_full:
        decimals = len(number_str_full.split('.')[1])
    else:
        decimals = 0
    return decimals > 8

# In[58]:

# funcao para formatar os coeficientes da tabela
def format_coefficient(coef):
    if coef == '-':
        return ''
    else:
        abrep = ''
        fechap = ''
        if "(" not in coef:
            if re.match(r'([0-9\,eE\-]+)(\*+)?', coef):
                return coef
        if "(" in coef:
            coef = coef.replace('(','').replace(')','')
            abrep = '('
            fechap = ')'
        match = re.match(r'([0-9\.eE\-]+)(\*+)?', coef)
        if match:
            number_str = float(match.group(1))
            asterisks = match.group(2) if match.group(2) else ''
            if needs_more_than_five_decimals(number_str):
                return abrep + coef + fechap
            else:
                number = float(number_str)
                formatted_number = f"{number:.8f}"
                formatted_number = formatted_number+'#'
            while formatted_number[-2:]=='0#': 
                formatted_number = formatted_number.replace('0#','#')
            return abrep + formatted_number.replace('#','') + asterisks + fechap
        else:
            return coef

# In[304]:

caminho = 'Outputs_Regressoes'
arquivos_xlsx = [arquivo for arquivo in os.listdir(caminho) if arquivo.endswith('.xlsx')]
arquivos_xlsx = [arquivo for arquivo in arquivos_xlsx if not arquivo.startswith('Modelos')]
# arquivos_xlsx = arquivos_xlsx[:-2]

# In[305]:

dfs = []
modelos = []
subset = []
for arquivo in arquivos_xlsx:
    dfs.append(pd.read_excel(caminho+'//'+arquivo))
    modelos.append(arquivo[arquivo.find('Model'):arquivo.find('Model')+6])
    subset.append(arquivo[27:arquivo.find('.')])

# In[306]:

df = pd.DataFrame(data = dfs[0]['VARIABLES'][1:],
                  columns = [dfs[0]['VARIABLES'][0]])

# In[307]:

for i in range(len(dfs)):
    print(i)
    dfs[i]['Coeficiente'] = dfs[i]['Coeficiente'].apply(format_coefficient)
    dfs[i]['Erro_Padrao'] = dfs[i]['Erro_Padrao'].apply(format_coefficient)
    dfs[i]['Coeficiente'] = dfs[i].apply(lambda row: row['Coeficiente']+'\n'+row['Erro_Padrao'] if not row['Erro_Padrao']=='' else row['Coeficiente'], axis=1)
    suff = "_"+subset[i]
    df = df.merge(dfs[i], on = ['VARIABLES'], how = 'left',suffixes=['',suff], indicator = False)
    df.drop('Erro_Padrao', axis=1, inplace=True)

df.rename(columns={'Coeficiente': 'Coeficiente'+"_"+subset[0]}, inplace=True)

# In[308]:

df.to_excel(caminho+'/Modelos_concatenados.xlsx', index=False)
