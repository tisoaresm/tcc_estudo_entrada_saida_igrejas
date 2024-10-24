if(!require(ggplot2)){install.packages("ggplot2");require(ggplot2)}
if(!require(sf)){install.packages("sf");require(sf)}
if(!require(tmap)){install.packages("tmap");require(tmap)}
if(!require(haven)){install.packages("haven");require(haven)}
if(!require(dplyr)){install.packages("dplyr");require(dplyr)}
if(!require(stringr)){install.packages("stringr");require(stringr)}
if(!require(writexl)){install.packages("writexl");require(writexl)}


mapa_condados <- st_read("tl_2024_us_county\\tl_2024_us_county.shp")
dados <- read_dta("Bases_Tratadas\\Churches_USA_Data.dta")
# View(dados)

dados <- dados %>% group_by(fipsmerg) %>%
  mutate(fipsmerg_original = ifelse(is.na(fipsmerg_original), first(fipsmerg_original[!is.na(fipsmerg_original)]), fipsmerg_original))

dados$fipsmerg <- str_pad(dados$fipsmerg_original, width = 5, pad = "0")


# Agrupar por condado e ano, e somar o número de templos
dados_condados <- dados %>%
  group_by(fipsmerg, year) %>%
  summarize(total_templos = sum(congreg, na.rm = TRUE)) %>%
  ungroup()
# View(dados_condados)

total_min <- quantile(dados_condados$total_templos, 0.05, na.rm = TRUE)
total_max <- quantile(dados_condados$total_templos, 0.95, na.rm = TRUE)

# Truncando os valores da coluna 'total_templos' para ficar dentro dos percentis
dados_condados <- dados_condados %>%
  mutate(total_templos_ajustado = pmin(pmax(total_templos, total_min), total_max))


# Definindo a funcao plot_map
plot_map <- function(data, ano, shapefile, output_dir) {
  # Filtrando os dados para o ano especifico
  dados_ano <- data %>% filter(year == ano)

  # Unindo os dados de templos com o shapefile
  mapa_dados <- shapefile %>%
    left_join(dados_ano, by = c("GEOID" = "fipsmerg"))

  # Verificando se a juncao retornou dados
  if (nrow(mapa_dados) == 0) {
    warning(paste("Nenhum dado encontrado para o ano", ano))
    return(NULL)  # Encerra a funcao se nao houver dados
  }

  # Criando o mapa
  mapa <- ggplot(data = mapa_dados) +
    geom_sf(aes(fill = total_templos_ajustado)) +  # Preenchimento baseado na soma de templos
    scale_fill_viridis_c(option = "plasma", na.value = "grey50",
                         limits = c(total_min, total_max)) +  # Paleta de cores
    labs(title = paste("Total de Templos por Condado - Ano", ano),
         fill = "Total de Templos") +
    coord_sf(xlim = c(-125, -65), ylim = c(25, 50), expand = FALSE) +  # Definindo os limites para focar nos EUA
    theme_minimal()

  print(mapa)

  # Salvando o plot como PNG
  ggsave(filename = file.path(output_dir, paste("mapa_tempos_", ano, ".png", sep = "")),
         plot = mapa,
         width = 10, height = 8, dpi = 300)
}

anos_unicos <- unique(dados_condados$year)  # Obtendo anos unicos
output_directory <- "figuras"

# Criando o diretorio se nao existir
if (!dir.exists(output_directory)) {
  dir.create(output_directory)
}

# Gerando e salvando mapas para cada ano
for (ano in anos_unicos) {
  resultado <- plot_map(dados_condados, ano, mapa_condados, output_directory)

  # Verifica se o resultado e NULL
  if (is.null(resultado)) {
    message(paste("Nenhum mapa gerado para o ano:", ano))
  }
}

### PARA UM ESTADO ESPECIFICO

# Definindo a funcao plot_map com filtragem por estado
plot_map <- function(data, ano, shapefile, output_dir, total_min, total_max, fips_estado) {
  # Filtrando os dados para o ano especifico
  dados_ano <- data %>% filter(year == ano)
  
  # Filtrando o shapefile e os dados para o estado especifico com base nos dois primeiros digitos do ccdigo FIPS
  shapefile_estado <- shapefile %>% filter(substr(GEOID, 1, 2) == fips_estado)
  dados_ano_estado <- dados_ano %>% filter(substr(fipsmerg, 1, 2) == fips_estado)
  
  # Unindo os dados de templos com o shapefile do estado
  mapa_dados <- shapefile_estado %>%
    left_join(dados_ano_estado, by = c("GEOID" = "fipsmerg"))
  
  # Verificando se a juncao retornou dados
  if (nrow(mapa_dados) == 0) {
    warning(paste("Nenhum dado encontrado para o ano", ano))
    return(NULL)  # Encerra a funcao se nao houver dados
  }
  
  # Criando o mapa focado no estado especifico
  mapa <- ggplot(data = mapa_dados) +
    geom_sf(aes(fill = total_templos_ajustado)) +  
    scale_fill_viridis_c(option = "plasma", na.value = "grey50", 
                         limits = c(total_min, total_max)) +  # Definindo os limites da escala
    labs(title = paste("Total de Templos por Condado - Ano", ano, "Estado", fips_estado),
         fill = "Total de Templos") +
    coord_sf(xlim = c(-170, -130), ylim = c(51, 71), expand = FALSE) +
    theme_minimal()

  print(mapa)
  
  # Salvando o plot como PNG
  ggsave(filename = file.path(output_dir, paste("mapa_tempos_", ano, "_estado_", fips_estado, ".png", sep = "")), 
         plot = mapa, 
         width = 10, height = 8, dpi = 300)
}

fips_estado <- "02"  # 02 e Codigo FIPS do Alaska
anos_unicos <- unique(dados_condados$year)


# Gerando e salvando mapas para cada ano, com a mesma escala de cores, para o estado escolhido
for (ano in anos_unicos) {
  resultado <- plot_map(dados_condados, ano, mapa_condados, output_directory, total_min, total_max, fips_estado)
  
  # Verifica se o resultado e NULL
  if (is.null(resultado)) {
    message(paste("Nenhum mapa gerado para o ano:", ano))
  }
}