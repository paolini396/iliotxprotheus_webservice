#include "TOTVS.ch"
#include "Topconn.ch"

/*/{Protheus.doc} MA030TOK
Na TudOK (validação da digitação) na inclusão e alteração de clientes.
@type function
@author Gabriel Paolini - Facile Sistemas
@since 25/03/2022
/*/

Static _cMCodCli_ := "" as character
Static _cMSLojaCli_ := "" as character

User Function MA030TOK()

  _cMCodCli_ := M->A1_COD
  _cMSLojaCli_ := M->A1_LOJA

Return(.T.)

User Function GetMCodA1()
Return(_cMCodCli_)

User Function GetMLojaA1()
Return(_cMSLojaCli_)

