##### Pacotes:
if(!require(tidyverse)){install.packages("tidyverse");require(tidyverse)}
if(!require(wooldridge)){install.packages("wooldridge");require(wooldridge)}
if(!require(mvtnorm)){install.packages("mvtnorm");require(mvtnorm)}
if(!require(multiwayvcov)){install.packages("multiwayvcov");require(multiwayvcov)}
if(!require(lmtest)){install.packages("lmtest");require(lmtest)}
if(!require(sandwich)){install.packages("sandwich");require(sandwich)}
if(!require(foreign)){install.packages("foreign");require(foreign)}
if(!require(haven)){install.packages("haven");require(haven)}
if(!require(dplyr)){install.packages("dplyr");require(dplyr)}
if(!require(writexl)){install.packages("writexl");require(writexl)}
if(!require(zoo)){install.packages("zoo");require(zoo)}
if(!require(fixest)){install.packages("fixest");require(fixest)}
if(!require(caret)){install.packages("caret");require(caret)}


registra_log <- function(mensagem = ""){
  # Obter a data e hora atuais
  data_hora_atual <- Sys.time()
  # Formatar a saida
  formato <- "%Y-%m-%d %H:%M:%S"  # Formato desejado
  data_hora_formatada <- format(data_hora_atual, format = formato)
  # Imprimir a data e hora formatada
  cat("Data e Hora:", data_hora_formatada, "\n")
  # Gravar a data e hora e a mensagem em um arquivo de texto
  file_path <- "log\\logexecucao.txt"  # Caminho do arquivo
  file_path <- file.path(getwd(), "log", "logexecucao.txt")
  mensagem_com_data_hora <- paste(data_hora_formatada, mensagem)
  write(paste(mensagem_com_data_hora, "\n"), file = file_path, append = TRUE)  # Gravacao no arquivo
  cat("Data e Hora e mensagem gravadas em", file_path, "\n")
}

print("***** Inicio do processamento *****")
registra_log("Inicio do processamento")


# fazendo leitura da base
data1 <- read_dta("Arquivos_Originais\\RCMSMGCY.DTA")

# Filtrar e manter apenas numeros entre 1 e 3 na coluna 'reltrad'
data1 <- filter(data1, reltrad %in% c(1, 2, 3))

# Contar o numero de observacoes em cada county para cada ano
count_table <- with(data1, table(fipsmerg, year))

# Identificar os counties sem observacoes em 1980, 2010 ou qualquer outro ano
invalid_counties <- rownames(count_table)[rowSums(count_table == 0) > 0]

# Filtrar a base de dados original para remover os counties invalidos
dados_filtrados <- subset(data1, !(fipsmerg %in% invalid_counties))
num_counties <- length(unique(dados_filtrados$fipsmerg))
print(paste("Quantidade de Counties =", num_counties))
print(paste("Quantidade de observacoes =",dim(dados_filtrados)[1]))

###### REMOVENDO IGREJAS SEM OBSERVACOES ######
# Filtrar as igrejas que possuem informacoes nos quatro periodos
igrejas_quatro_anos <- dados_filtrados %>%
  group_by(grpcode) %>%
  filter(all(c(1980, 1990, 2000, 2010) %in% year))

# Filtrar as igrejas que possuem informacoes nos quatro periodos
dados_filtrados <- dados_filtrados %>%
  filter(grpcode %in% igrejas_quatro_anos$grpcode)

# # Visualizar o resultado
num_denominacoes <- length(unique(dados_filtrados$grpcode))
print(paste("Quantidade de Denominacoes =", num_denominacoes))
print(paste("Quantidade de observacoes =",dim(dados_filtrados)[1]))

###### REMOVENDO IGREJAS SEM OBSERVACOES ######


### Vamos fazer a funcaoo equivalente ao fillin do stata a partir daqui. 
# fillin
dados_filtrados$grpcode <- factor(dados_filtrados$grpcode)
dados_filtrados$fipsmerg_original <- dados_filtrados$fipsmerg
dados_filtrados$fipsmerg <- factor(dados_filtrados$fipsmerg)
periodos <- c(1980, 1990, 2000, 2010)  # Periodos desejados
combinacoes <- expand.grid(grpcode = unique(dados_filtrados$grpcode), year = periodos, fipsmerg = unique(dados_filtrados$fipsmerg))
dados_completos <- left_join(combinacoes, dados_filtrados, by = c("grpcode", "year", "fipsmerg"))
print(paste("Quantidade de observa��es =",dim(dados_completos)[1]))

### Tratando dados
# Substituir NA por zeros nas colunas
dados_completos$congreg <- ifelse(is.na(dados_completos$congreg), 0, dados_completos$congreg)
dados_completos$adherent <- ifelse(is.na(dados_completos$adherent), 0, dados_completos$adherent)

# # Preencher o fipsmerg original das linhas geradas
dados_completos <- dados_completos %>% group_by(fipsmerg) %>%
  mutate(fipsmerg_original = ifelse(is.na(fipsmerg_original), first(fipsmerg_original[!is.na(fipsmerg_original)]), fipsmerg_original))

# # Preencher o reltrad das linhas geradas
dados_completos <- dados_completos %>% group_by(grpcode) %>%
  mutate(reltrad = ifelse(is.na(reltrad), first(reltrad[!is.na(reltrad)]), reltrad)) %>% 
  mutate(grpname = ifelse(is.na(grpname), first(grpname[!is.na(grpname)]), grpname)) %>% 
  mutate(family = ifelse(is.na(family), first(family[!is.na(family)]), family))
dados_completos <- dados_completos %>% ungroup()

dados_completos <- dados_completos %>%
  group_by(fipsmerg, year) %>%
  fill(totpop, .direction = "downup") %>% 
  fill(cntynm, .direction = "downup") %>% 
  fill(stateab, .direction = "downup")
dados_completos <- dados_completos %>% ungroup()

# criando variavel a_imt (denominacao i existe no mercado m no periodo t)
dados_completos$a_imt <- ifelse(dados_completos$congreg != 0, 1, 0)

# criando variavel a_imt_1 (denominacao i existe no mercado m no periodo t-1)
# Criar a nova coluna 'nova_coluna' com base na coluna 'a', dentro de cada grupo de 'chave'
dados_completos <- dados_completos %>%
  group_by(grpcode, fipsmerg) %>%
  mutate(a_imt_1 = as.integer(lag(a_imt) == 1))

# Remover o agrupamento
dados_completos <- ungroup(dados_completos)
data <- dados_completos

# Criar uma nova coluna 'igrejas_anteriores' que contem a contagem de igrejas da mesma categoria e county no periodo anterior (se 'a_imt' for igual a 1)
data <- data %>%
  arrange(fipsmerg, reltrad, grpcode, year) %>%
  group_by(fipsmerg, reltrad, grpcode) %>%
  mutate(prev_year = lag(year))

data <- data %>%
  select(-c(NOTE_MIS, NOTE_COM, NOTE_MEA))

# Criando novas colunas de chave ano_mercado
data$ano_mercado <- paste0(data$year, data$fipsmerg)
data$prev_ano_mercado <- ifelse(is.na(data$prev_year), NA, paste0(data$prev_year, data$fipsmerg))

registra_log("Inicio soma reltrad 1")
# *******************Fazendo soma do reltrad 1*******************
# Fazendo soma do reltrad 1
data <- data %>%
  group_by(fipsmerg, prev_year) %>%
  mutate(reltrad_1 = sum(congreg[a_imt == 1 & reltrad == 1])) %>%
  ungroup()

# Separando dados das somas num dataframe separado
soma_reltrad_temp <- data[, c("ano_mercado", "reltrad_1")]
soma_reltrad_temp <- unique(soma_reltrad_temp)

# merge da base principal com os dados das somas reltrad 1
data <- merge(data, soma_reltrad_temp, by.x = "prev_ano_mercado", by.y = "ano_mercado", all.x = TRUE)

# Deletando a coluna antiga reltrad_1.x e renomeando reltrad_1.y para n_reltrad_1
data <- data %>%
  select(-reltrad_1.x) %>%  # Exclui a coluna reltrad_1.x
  rename(n_reltrad_1 = reltrad_1.y)  # Renomeia a coluna reltrad_1.y para outro_nome

registra_log("Termino soma reltrad 1")

registra_log("Inicio soma reltrad 2")
# *******************Fazendo soma do reltrad 2*******************
# Fazendo soma do reltrad 2
data <- data %>%
  group_by(fipsmerg, prev_year) %>%
  mutate(reltrad_2 = sum(congreg[a_imt == 1 & reltrad == 2])) %>%
  ungroup()

# Separando dados das somas num dataframe separado
soma_reltrad_temp <- data[, c("ano_mercado", "reltrad_2")]
soma_reltrad_temp <- unique(soma_reltrad_temp)

# merge da base principal com os dados das somas reltrad 1
data <- merge(data, soma_reltrad_temp, by.x = "prev_ano_mercado", by.y = "ano_mercado", all.x = TRUE)

# Deletando a coluna antiga reltrad_1.x e renomeando reltrad_2.y para n_reltrad_2
data <- data %>%
  select(-reltrad_2.x) %>%  # Exclui a coluna reltrad_1.x
  rename(n_reltrad_2 = reltrad_2.y)  # Renomeia a coluna reltrad_1.y para outro_nome

registra_log("Termino soma reltrad 2")

registra_log("Inicio soma reltrad 3")
# *******************Fazendo soma do reltrad 3*******************
# Fazendo soma do reltrad 3
data <- data %>%
  group_by(fipsmerg, prev_year) %>%
  mutate(reltrad_3 = sum(congreg[a_imt == 1 & reltrad == 3])) %>%
  ungroup()

# Separando dados das somas num dataframe separado
soma_reltrad_temp <- data[, c("ano_mercado", "reltrad_3")]
soma_reltrad_temp <- unique(soma_reltrad_temp)

# merge da base principal com os dados das somas reltrad 1
data <- merge(data, soma_reltrad_temp, by.x = "prev_ano_mercado", by.y = "ano_mercado", all.x = TRUE)

# Deletando a coluna antiga reltrad_1.x e renomeando reltrad_3.y para n_reltrad_3
data <- data %>%
  select(-reltrad_3.x) %>%  # Exclui a coluna reltrad_1.x
  rename(n_reltrad_3 = reltrad_3.y)  # Renomeia a coluna reltrad_1.y para outro_nome

registra_log("Termino soma reltrad 3")

# removendo para cada denominacao, a quantidade de templos dessa denominacao da contagem de competidores dessa denominacao
data$n_reltrad_1 <- ifelse(data$reltrad == 1 & data$a_imt_1 == 1, data$n_reltrad_1 - data$congreg, data$n_reltrad_1)
data$n_reltrad_2 <- ifelse(data$reltrad == 2 & data$a_imt_1 == 1, data$n_reltrad_2 - data$congreg, data$n_reltrad_2)
data$n_reltrad_3 <- ifelse(data$reltrad == 3 & data$a_imt_1 == 1, data$n_reltrad_3 - data$congreg, data$n_reltrad_3)

registra_log("Criando variáveis dummies para categorias reltrad 1 2 e 3")

data$Evangelical <- ifelse(data$reltrad == 1, 1, 0)
data$Mainline <- ifelse(data$reltrad == 2, 1, 0)
data$Catholic <- ifelse(data$reltrad == 3, 1, 0)

# Nos vamos renomear as variaveis logo em seguida, considerando que reltrad 1 sao evangelicals, reltrad 2 sao mainlines e 3 sao as catholics
names(data)[names(data) == "n_reltrad_1"] <- "n_E"
names(data)[names(data) == "n_reltrad_2"] <- "n_M"
names(data)[names(data) == "n_reltrad_3"] <- "n_C"

# criando uma coluna de populacao em milhoes
data$pop_em_milhoes <- data$totpop / 1e6

registra_log("Salvando base full")
file_path <- file.path(getwd(), "Bases_Tratadas", "Churches_USA_Data.dta")
write.dta(data, file_path)
file_path <- file.path(getwd(), "Bases_Tratadas", "Churches_USA_Data.xlsx")
write_xlsx(data, file_path)

data_evangelical_mainline <- subset(data, reltrad == 1 | reltrad == 2)
file_path <- file.path(getwd(), "Bases_Tratadas", "Evangelical_And_Mainline_Churches_USA_Data.dta")
write.dta(data_evangelical_mainline, file_path)
file_path <- file.path(getwd(), "Bases_Tratadas", "Evangelical_And_Mainline_Churches_USA_Data.xlsx")
write_xlsx(data_evangelical_mainline, file_path)

data_catholic <- subset(data, reltrad == 3)
file_path <- file.path(getwd(), "Bases_Tratadas", "Catholic_Churches_USA_Data.dta")
write.dta(data_catholic, file_path)
file_path <- file.path(getwd(), "Bases_Tratadas", "Catholic_Churches_USA_Data.xlsx")
write_xlsx(data_catholic, file_path)

print("***** Fim do processamento *****")
registra_log("Fim do processamento")

View(data)
dim(data)
nrow(data_evangelical_mainline)
ncol(data_evangelical_mainline)
nrow(data)
