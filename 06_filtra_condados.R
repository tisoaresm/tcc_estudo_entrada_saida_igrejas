if(!require(haven)){install.packages("haven");require(haven)}
if(!require(foreign)){install.packages("foreign");require(foreign)}
if(!require(haven)){install.packages("haven");require(haven)}
if(!require(dplyr)){install.packages("dplyr");require(dplyr)}
if(!require(writexl)){install.packages("writexl");require(writexl)}
if(!require(tidyverse)){install.packages("tidyverse");require(tidyverse)}


dados <- read_dta("Bases_Tratadas\\Churches_USA_Data.dta")

# Filtrar os counties que tinham menos de 50000 habitantes em 1980
counties_1980 <- dados %>%
  filter(year == 1980 & totpop <= 50000) %>%
  select(fipsmerg) %>%
  distinct()  # Remover duplicados

# Filtrar os dados para incluir apenas os counties identificados acima
dados_filtrados <- dados %>%
  filter(fipsmerg %in% counties_1980$fipsmerg)

# Verificar os dados filtrados
print(dados_filtrados)

imprime_data_hora("Salvando base full")
write.dta(dados_filtrados, "subamostra_de_condados\\Bases_Filtradas\\Churches_USA_Data.dta")
write_xlsx(dados_filtrados, "subamostra_de_condados\\Bases_Filtradas\\Churches_USA_Data.xlsx")

data_evangelical_mainline <- subset(dados_filtrados, reltrad == 1 | reltrad == 2)
write.dta(data_evangelical_mainline, "subamostra_de_condados\\Bases_Filtradas\\Evangelical_And_Mainline_Churches_USA_Data.dta")
write_xlsx(data_evangelical_mainline, "subamostra_de_condados\\Bases_Filtradas\\Evangelical_And_Mainline_Churches_USA_Data.xlsx")

data_catholic <- subset(dados_filtrados, reltrad == 3)
write.dta(data_catholic, "subamostra_de_condados\\Bases_Filtradas\\Catholic_Churches_USA_Data.dta")
write_xlsx(data_catholic, "subamostra_de_condados\\Bases_Filtradas\\Catholic_Churches_USA_Data.xlsx")