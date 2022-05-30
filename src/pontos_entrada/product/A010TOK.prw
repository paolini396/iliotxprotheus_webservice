#include "TOTVS.ch"
#include "Topconn.ch"

/*/{Protheus.doc} A010TOK
Na TudOK (validação da digitação) na inclusão e alteração de Produtos.
@type function
@author Gabriel Paolini - Facile Sistemas
@since 25/03/2022
/*/

Static _cCodProd_ := "" as character

User Function A010TOK()

  _cCodProd_ := M->B1_COD

Return(.T.)

User Function GetCodB1()
Return(_cCodProd_)
