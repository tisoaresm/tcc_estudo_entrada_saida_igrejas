********** AMOSTRA Catholic_Churches_USA_Data **********
* Modelo 1 - Interacoes
set maxvar 13000

use grpcode year fipsmerg cntynm stateab pop_em_milhoes grpname adherent congreg reltrad family a_imt a_imt_1 prev_year n_E n_M n_C ano_mercado Evangelical Mainline Catholic using "subamostra_de_condados\Bases_Filtradas\Catholic_Churches_USA_Data.dta"
destring ano_mercado, generate(ano_mercado_numeric)

capture reghdfe a_imt a_imt_1 pop_em_milhoes c.n_E#c.Catholic c.n_M#c.Catholic, absorb(i.grpcode) cluster(fipsmerg)

* Salvar os resultados em um arquivo de texto
if _rc == 0 {
    outreg2 using "subamostra_de_condados\Outputs_Regressoes\Regression_reghdfe_Model1_Catholic_Churches_USA_Data.txt", replace
} 
else {
    display "Regressão 1 falhou devido a colinearidade."
}

* Modelo 2 - Interacoes

capture reghdfe a_imt a_imt_1 pop_em_milhoes c.n_E#c.Catholic c.n_M#c.Catholic, absorb(i.grpcode i.fipsmerg) cluster(fipsmerg)

* Salvar os resultados em um arquivo de texto
if _rc == 0 {
    outreg2 using "subamostra_de_condados\Outputs_Regressoes\Regression_reghdfe_Model2_Catholic_Churches_USA_Data.txt", replace
} 
else {
    display "Regressão 2 falhou devido a colinearidade."
}

* Modelo 3 - Interacoes

capture reghdfe a_imt a_imt_1 pop_em_milhoes c.n_E#c.Catholic c.n_M#c.Catholic, absorb(i.grpcode i.fipsmerg i.year) cluster(fipsmerg)

* Salvar os resultados em um arquivo de texto
if _rc == 0 {
    outreg2 using "subamostra_de_condados\Outputs_Regressoes\Regression_reghdfe_Model3_Catholic_Churches_USA_Data.txt", replace
} 
else {
    display "Regressão 3 falhou devido a colinearidade."
}

* Modelo 4 - Interacoes

capture reghdfe a_imt a_imt_1 pop_em_milhoes c.n_E#c.Catholic c.n_M#c.Catholic, absorb(i.grpcode i.ano_mercado_numeric) cluster(fipsmerg)

* Salvar os resultados em um arquivo de texto
if _rc == 0 {
    outreg2 using "subamostra_de_condados\Outputs_Regressoes\Regression_reghdfe_Model4_Catholic_Churches_USA_Data.txt", replace
} 
else {
    display "Regressão 4 falhou devido a colinearidade."
}
