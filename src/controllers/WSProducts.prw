#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RESTFUL.CH"

WSRestFul WSProducts Description "REST para Produtos no Protheus"

	WSData search as string optional
	WSData page as string optional
	WSData per_page as string optional
	WSData all_page as string optional

	WSMethod GET Description "Listar Produtos"     WSSYNTAX "/WSProducts/{id}" Produces APPLICATION_JSON
	WSMethod POST Description "Cria Produtos"      WSSYNTAX "/WSProducts"      Produces APPLICATION_JSON
	WSMethod PUT Description "Alterar Produtos"    WSSYNTAX "/WSProducts"      Produces APPLICATION_JSON
	WSMethod DELETE Description "Deletar Produtos" WSSYNTAX "/WSProducts"      Produces APPLICATION_JSON

END WSRESTFUL

WSMethod GET QueryParam search, page, per_page WSService WSProducts

	Local oResponse           := Nil as object

	Local oProductService    :=  TProductService():New() as object
	Local nIndexProductsList := 0 as numeric
	Local oProductData       := Nil as Object
	Local oProductJson       := Nil as Object

	Local lAllPage            := .F. as logical
	Local cSearch             := "" as character
	Local nPage               := 1 as numeric
	Local nPerPage            := 50 as numeric

	Local cId := "" as character

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

		cId := if(Len(::aURLParms) > 0, ::aURLParms[1], "")

		if !Empty(cId)

			oProductData := oProductService:Show(cId)

		else

			oProductData := oProductService:List(cSearch, nPage, nPerPage, lAllPage)

		endif

		oResponse := JsonObject():New()
		oResponse["page"] := oProductData["page"]
		oResponse["per_page"] := oProductData["per_page"]
		oResponse["total"] := oProductData["total"]
		oResponse["last_page"] := oProductData["last_page"]
		oResponse["data"] := {}

		for nIndexProductsList := 1 to oProductData["data"]:getCount()

			oProductJson := JsonObject():New()


			if !Empty(cId)

				oProductJson["id"]                := oProductData["data"]:GetItem(nIndexProductsList):cCode
				oProductJson["description"]           := oProductData["data"]:GetItem(nIndexProductsList):cDescription
				oProductJson["type"]          := oProductData["data"]:GetItem(nIndexProductsList):cType
				oProductJson["unit_measure"]          := oProductData["data"]:GetItem(nIndexProductsList):cUnitMeasure
				oProductJson["stock_warehouse"]          := oProductData["data"]:GetItem(nIndexProductsList):cStockWarehouse
				oProductJson["stock_group"]          := oProductData["data"]:GetItem(nIndexProductsList):cStockGroup
				oProductJson["percentage_icms"]          := oProductData["data"]:GetItem(nIndexProductsList):nPercentageIcms
				oProductJson["percentage_ipi"]          := oProductData["data"]:GetItem(nIndexProductsList):nPercentageIpi
				oProductJson["ncm"]          := oProductData["data"]:GetItem(nIndexProductsList):cNcm
				oProductJson["conversion_type"]          := oProductData["data"]:GetItem(nIndexProductsList):cConversionType
				oProductJson["revision_date"]          := oProductData["data"]:GetItem(nIndexProductsList):dRevisionDate
				oProductJson["cost_ref_date"]          := oProductData["data"]:GetItem(nIndexProductsList):dCostRefDate
				oProductJson["reference"]          := oProductData["data"]:GetItem(nIndexProductsList):cReference
				oProductJson["model"]          := oProductData["data"]:GetItem(nIndexProductsList):cModel

			else

				oProductJson["id"] := oProductData["data"]:GetItem(nIndexProductsList):cCode
				oProductJson["description"] := oProductData["data"]:GetItem(nIndexProductsList):cDescription
				oProductJson["type"] := oProductData["data"]:GetItem(nIndexProductsList):cType
				oProductJson["unit_measure"] := oProductData["data"]:GetItem(nIndexProductsList):cUnitMeasure
				oProductJson["model"] := oProductData["data"]:GetItem(nIndexProductsList):cModel
				oProductJson["reference"] := oProductData["data"]:GetItem(nIndexProductsList):cReference

			endIf

			Aadd(oResponse["data"], oProductJson)

		next nIndexProductsList

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

WSMethod POST WSService WSProducts

	Local oRequest            := JsonObject():New() as object
	Local oResponse           := JsonObject():New() as object

	Local oProductService     := TProductService():New() as object
	Local oProductSanitizer   := TProductSanitizer():New() as object
	Local oProductsListParsed := Nil as Object
	Local oProductsList       := Nil as Object
	Local nIndexProductsList  := 0 as numeric
	Local oProductJson        := Nil as Object

	Private cError := "" as character
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oProductsListParsed := oProductSanitizer:ToCreateOrUpdate(oRequest["data"])

		oProductsList := oProductService:Store(oProductsListParsed)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexProductsList := 1 to oProductsList:getCount()

			oProductJson := JsonObject():New()

			if (Len(oProductsList:GetItem(nIndexProductsList):aErrors) >= 1)

				oProductJson["status"] := 400
				oProductJson["errors"] := oProductsList:GetItem(nIndexProductsList):aErrors

				oResponse["error_total"] += 1

			else

				oProductJson["status"]   := 201
				oProductJson["id"] := oProductsList:GetItem(nIndexProductsList):cCode
				oProductJson["description"] := oProductsList:GetItem(nIndexProductsList):cDescription
				oProductJson["type"] := oProductsList:GetItem(nIndexProductsList):cType
				oProductJson["unit_measure"] := oProductsList:GetItem(nIndexProductsList):cUnitMeasure
				oProductJson["model"] := oProductsList:GetItem(nIndexProductsList):cModel
				oProductJson["reference"] := oProductsList:GetItem(nIndexProductsList):cReference

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oProductJson)

		next nIndexProductsList

	end sequence

	if !Empty(cError)

		oResponse := JsonObject():New()

		oResponse["error"]     := JsonObject():New()
		oResponse["error"]["status"]   := 400
		oResponse["error"]["message"]  := cError

		::SetStatus(400)

	else

		oResponse["total"]   := Len(oResponse["data"])
		::SetStatus(207)

	endif

	::SetContentType("application/json; charset=UTF-8")
	::SetResponse(oResponse:ToJson())

	ErrorBlock(bError)

Return(.T.)


WSMethod PUT WSService WSProducts

	Local oRequest             := JsonObject():New() as object
	Local oResponse            := JsonObject():New() as object

	Local oProductService     := TProductService():New() as object
	Local oProductSanitizer   := TProductSanitizer():New() as object
	Local oProductsListParsed := Nil as Object
	Local oProductsList       := Nil as Object
	Local nIndexProductsList  := 0 as numeric
	Local oProductJson        := Nil as Object

	Private cError := ""
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oProductsListParsed := oProductSanitizer:ToCreateOrUpdate(oRequest["data"])

		oProductsList := oProductService:Update(oProductsListParsed)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexProductsList := 1 to oProductsList:getCount()

			oProductJson := JsonObject():New()

			if (Len(oProductsList:GetItem(nIndexProductsList):aErrors) >= 1)

				oProductJson["status"] := 400
				oProductJson["errors"] := oProductsList:GetItem(nIndexProductsList):aErrors

				oResponse["error_total"] += 1

			else

				oProductJson["status"]   := 201
				oProductJson["id"] := oProductsList:GetItem(nIndexProductsList):cCode
				oProductJson["description"] := oProductsList:GetItem(nIndexProductsList):cDescription
				oProductJson["type"] := oProductsList:GetItem(nIndexProductsList):cType
				oProductJson["unit_measure"] := oProductsList:GetItem(nIndexProductsList):cUnitMeasure
				oProductJson["model"] := oProductsList:GetItem(nIndexProductsList):cModel
				oProductJson["reference"] := oProductsList:GetItem(nIndexProductsList):cReference

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oProductJson)

		next nIndexProductsList

	end sequence

	if !Empty(cError)

		oResponse := JsonObject():New()

		oResponse["error"]     := JsonObject():New()
		oResponse["error"]["status"]   := 400
		oResponse["error"]["message"]  := cError

		::SetStatus(400)

	else

		oResponse["total"]   := Len(oResponse["data"])
		::SetStatus(207)

	endif

	::SetContentType("application/json; charset=UTF-8")
	::SetResponse(oResponse:ToJson())

	ErrorBlock(bError)

Return(.T.)

WSMethod DELETE WSService WSProducts

	Local oRequest             := JsonObject():New() as object
	Local oResponse            := JsonObject():New() as object

	Local oProductService     := TProductService():New() as object
	Local oProductSanitizer   := TProductSanitizer():New() as object
	Local oProductsListSanitizer := Nil as Object
	Local oProductsList       := Nil as Object
	Local nIndexProductsList  := 0 as numeric
	Local oProductJson        := Nil as Object

	Private cError := ""
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oProductsListSanitizer := oProductSanitizer:ToDestroy(oRequest["data"])

		oProductsList := oProductService:Destroy(oProductsListSanitizer)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexProductsList := 1 to oProductsList:getCount()

			oProductJson := JsonObject():New()

			if (Len(oProductsList:GetItem(nIndexProductsList):aErrors) >= 1)

				oProductJson["status"] := 400
				oProductJson["id"]       := oProductsList:GetItem(nIndexProductsList):cCode
				oProductJson["errors"] := oProductsList:GetItem(nIndexProductsList):aErrors

				oResponse["error_total"] += 1

			else

				oProductJson["status"]   := 200
				oProductJson["id"]       := oProductsList:GetItem(nIndexProductsList):cCode

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oProductJson)

		next nIndexProductsList

	end sequence

	if !Empty(cError)

		oResponse := JsonObject():New()

		oResponse["error"]     := JsonObject():New()
		oResponse["error"]["status"]   := 400
		oResponse["error"]["message"]  := cError

		::SetStatus(400)

	else

		oResponse["total"]   := Len(oResponse["data"])
		::SetStatus(207)

	endif

	::SetContentType("application/json; charset=UTF-8")
	::SetResponse(oResponse:ToJson())

	ErrorBlock(bError)

Return(.T.)
