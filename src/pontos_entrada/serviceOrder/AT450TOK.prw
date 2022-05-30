#include "TOTVS.ch"

/*/{Protheus.doc} AT450TOK
Na TudOK (valida��o da digita��o) na inclus�o e altera��o de Ordem de Servi�o.
@type function
@author Gabriel Paolini - Facile Sistemas
@since 23/05/2022
/*/

Static _cCodOS_ := "" as character

User Function AT450TOK()

  _cCodOS_ := M->AB6_NUMOS

Return(.T.)

User Function GetCodAB6()
Return(_cCodOS_)


