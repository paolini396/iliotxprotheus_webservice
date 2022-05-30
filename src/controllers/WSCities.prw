#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RESTFUL.CH"

WSRestFul WSCities Description "REST para Municípios (cidades) no Protheus"

	WSData search as string optional
	WSData page as string optional
	WSData per_page as string optional
	WSData all_page as string optional

	WSMethod GET Description "Listar Clientes"  WSSYNTAX "/WSCities/{state}/{id}" Produces APPLICATION_JSON

END WSRESTFUL

WSMethod GET QueryParam search, page, per_page WSService WSCities

	Local oResponse           := Nil as object

	Local oCityService    :=  TCityService():New() as object
	Local nIndexCitiesList := 0 as numeric
	Local oCityData       := Nil as Object
	Local oCityJson       := Nil as Object

	Local lAllPage            := .F. as logical
	Local cSearch             := "" as character
	Local nPage               := 1 as numeric
	Local nPerPage            := 50 as numeric

	Local cId := "" as character
	Local cState := "" as character

	Private cError := "" as character
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	Default ::search := ""
	Default ::page := "1"
	Default ::per_page := "50"
	Default ::all_page := "false"

	begin sequence

		cSearch := Upper(AllTrim(::search))
		nPage  := Val(::page)
		nPerPage := Val(::per_page)
		lAllPage := if(::all_page == "true", .T., .F.)

		cState := if(Len(::aURLParms) > 0, ::aURLParms[1], "")
		cId    := if(Len(::aURLParms) > 1, ::aURLParms[2], "")

		if !Empty(cId)

			oCityData := oCityService:Show(cId, cState)

		else

			oCityData := oCityService:List(cSearch, nPage, nPerPage, lAllPage, cState)

		endif

		oResponse := JsonObject():New()
		oResponse["page"] := oCityData["page"]
		oResponse["per_page"] := oCityData["per_page"]
		oResponse["total"] := oCityData["total"]
		oResponse["last_page"] := oCityData["last_page"]
		oResponse["data"] := {}

		for nIndexCitiesList := 1 to oCityData["data"]:getCount()

			oCityJson := JsonObject():New()

			oCityJson["state"] := oCityData["data"]:GetItem(nIndexCitiesList):cState
			oCityJson["id"]    := oCityData["data"]:GetItem(nIndexCitiesList):cCode
			oCityJson["name"]  := oCityData["data"]:GetItem(nIndexCitiesList):cName

			Aadd(oResponse["data"], oCityJson)

		next nIndexCitiesList

	end sequence

	if !Empty(cError) // error begin sequence

		oResponse := JsonObject():New()

		oResponse["error"]     := JsonObject():New()
		oResponse["error"]["status"]   := 400
		oResponse["error"]["message"]  := cError

		::SetStatus(400)

	else

		::SetStatus(200)

	endif

	::SetContentType("application/json; charset=UTF-8")
	::SetResponse(oResponse:ToJson())

	ErrorBlock(bError)

Return(.T.)
