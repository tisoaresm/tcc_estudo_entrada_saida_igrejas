para garantir a correta reprodução do estudo realizado, é necessário que os scripts sejam executados na ordem em que estão enumerados, sendo:
01_Tratamento_Base.R
02_regressoes_Churches_USA_Data.do
03_regressoes_Evangelical_And_Mainline_Churches_USA_Data.do
04_regressoes_Catholic_Churches_USA_Data.do
05_Converte_txt_em_tabela_fs.py
06_filtra_condados.R
07_regressoes_subamostra_Churches_USA_Data.do
08_regressoes_subamostra_Evangelical_And_Mainline_Churches_USA_Data.do
09_regressoes_subamostra_Catholic_Churches_USA_Data.do
10_Converte_txt_em_tabela_subamostra.py
11_gerando_mapas.R

É necessário que os softwares Stata, R e Python bem como os pacotes e bibliotecas indicados nos códigos estejam instalados.

Estando todos os requisitor atendidos, basta executar cada um dos códigos. Os códigos partirão dos arquivos originais baixados diretamente do site indicado no artigo sem nenhum pré tratamento e suas saídas serão nas pastas:
Bases_Tratadas (Bases pós tratamento e balanceamento)
figuras (mapas gerados automaticamente)
Outputs_Regressoes (Tabelas com as saídas das regressões do Stata e Tratamento do Python)
subamostra_de_condados (as mesmas saídas, apenas para condados com população total em 1980 inferior a 50 mil habitantes)