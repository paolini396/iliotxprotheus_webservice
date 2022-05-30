#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RESTFUL.CH"

WSRestFul WSServiceOrders Description "REST para Ordem de Serviço no Protheus"

	WSData search as string optional
	WSData page as string optional
	WSData per_page as string optional
	WSData all_page as string optional

	WSMethod GET Description "Listar Ordens de Serviço"     WSSYNTAX "/WSServiceOrders/{id}" Produces APPLICATION_JSON
	WSMethod POST Description "Cria Ordem de Serviço"       WSSYNTAX "/WSServiceOrders"      Produces APPLICATION_JSON
	WSMethod PUT Description "Alterar Ordem de Serviço"     WSSYNTAX "/WSServiceOrders"      Produces APPLICATION_JSON
	WSMethod DELETE Description "Deletar Ordem de Serviço"  WSSYNTAX "/WSServiceOrders"      Produces APPLICATION_JSON

END WSRESTFUL

WSMethod GET QueryParam search, page, per_page WSService WSServiceOrders

	Local oResponse           := Nil as object

	Local oServiceOrderService    :=  TServiceOrderService():New() as object
	Local nIndexServiceOrdersList := 0 as numeric
	Local oServiceOrderData       := Nil as Object
	Local oServiceOrderJson       := Nil as Object

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

			oServiceOrderData := oServiceOrderService:Show(cId)

		else

			oServiceOrderData := oServiceOrderService:List(cSearch, nPage, nPerPage, lAllPage)

		endif

		oResponse := JsonObject():New()
		oResponse["page"] := oServiceOrderData["page"]
		oResponse["per_page"] := oServiceOrderData["per_page"]
		oResponse["total"] := oServiceOrderData["total"]
		oResponse["last_page"] := oServiceOrderData["last_page"]
		oResponse["data"] := {}

		for nIndexServiceOrdersList := 1 to oServiceOrderData["data"]:getCount()

			oServiceOrderJson := JsonObject():New()


			if !Empty(cId)

				oServiceOrderJson["id"]                := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cCode
				oServiceOrderJson["description"]           := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cDescription
				oServiceOrderJson["type"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cType
				oServiceOrderJson["unit_measure"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cUnitMeasure
				oServiceOrderJson["stock_warehouse"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cStockWarehouse
				oServiceOrderJson["stock_group"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cStockGroup
				oServiceOrderJson["percentage_icms"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):nPercentageIcms
				oServiceOrderJson["percentage_ipi"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):nPercentageIpi
				oServiceOrderJson["ncm"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cNcm
				oServiceOrderJson["conversion_type"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cConversionType
				oServiceOrderJson["revision_date"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):dRevisionDate
				oServiceOrderJson["cost_ref_date"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):dCostRefDate
				oServiceOrderJson["reference"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cReference
				oServiceOrderJson["model"]          := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cModel

			else

				oServiceOrderJson["id"] := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cCode
				oServiceOrderJson["description"] := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cDescription
				oServiceOrderJson["type"] := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cType
				oServiceOrderJson["unit_measure"] := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cUnitMeasure
				oServiceOrderJson["model"] := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cModel
				oServiceOrderJson["reference"] := oServiceOrderData["data"]:GetItem(nIndexServiceOrdersList):cReference

			endIf

			Aadd(oResponse["data"], oServiceOrderJson)

		next nIndexServiceOrdersList

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

WSMethod POST WSService WSServiceOrders

	Local oRequest            := JsonObject():New() as object
	Local oResponse           := JsonObject():New() as object

	Local oServiceOrderService     := TServiceOrderService():New() as object
	Local oServiceOrderSanitizer   := TServiceOrderSanitizer():New() as object
	Local oServiceOrdersListParsed := Nil as Object
	Local oServiceOrdersList       := Nil as Object
	Local nIndexServiceOrdersList  := 0 as numeric
	Local oServiceOrderJson        := Nil as Object

	Private cError := "" as character
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oServiceOrdersListParsed := oServiceOrderSanitizer:ToCreateOrUpdate(oRequest["data"])
		oServiceOrdersList := oServiceOrderService:Store(oServiceOrdersListParsed)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexServiceOrdersList := 1 to oServiceOrdersList:getCount()

			oServiceOrderJson := JsonObject():New()

			if (Len(oServiceOrdersList:GetItem(nIndexServiceOrdersList):aErrors) >= 1)

				oServiceOrderJson["status"] := 400
				oServiceOrderJson["errors"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):aErrors

				oResponse["error_total"] += 1

			else

				oServiceOrderJson["status"]   := 201
				oServiceOrderJson["id"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cCode
				oServiceOrderJson["customer_code"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cCustomerCode
				oServiceOrderJson["customer_store"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cCustomerStore
				oServiceOrderJson["created_at"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):dCreatedAt
				oServiceOrderJson["model"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cModel
				oServiceOrderJson["reference"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cReference

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oServiceOrderJson)

		next nIndexServiceOrdersList

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


WSMethod PUT WSService WSServiceOrders

	Local oRequest             := JsonObject():New() as object
	Local oResponse            := JsonObject():New() as object

	Local oServiceOrderService     := TServiceOrderService():New() as object
	Local oServiceOrderSanitizer   := TServiceOrderSanitizer():New() as object
	Local oServiceOrdersListParsed := Nil as Object
	Local oServiceOrdersList       := Nil as Object
	Local nIndexServiceOrdersList  := 0 as numeric
	Local oServiceOrderJson        := Nil as Object

	Private cError := ""
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oServiceOrdersListParsed := oServiceOrderSanitizer:ToCreateOrUpdate(oRequest["data"])

		oServiceOrdersList := oServiceOrderService:Update(oServiceOrdersListParsed)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexServiceOrdersList := 1 to oServiceOrdersList:getCount()

			oServiceOrderJson := JsonObject():New()

			if (Len(oServiceOrdersList:GetItem(nIndexServiceOrdersList):aErrors) >= 1)

				oServiceOrderJson["status"] := 400
				oServiceOrderJson["errors"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):aErrors

				oResponse["error_total"] += 1

			else

				oServiceOrderJson["status"]   := 201
				oServiceOrderJson["id"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cCode
				oServiceOrderJson["description"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cDescription
				oServiceOrderJson["type"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cType
				oServiceOrderJson["unit_measure"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cUnitMeasure
				oServiceOrderJson["model"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cModel
				oServiceOrderJson["reference"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cReference

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oServiceOrderJson)

		next nIndexServiceOrdersList

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

WSMethod DELETE WSService WSServiceOrders

	Local oRequest             := JsonObject():New() as object
	Local oResponse            := JsonObject():New() as object

	Local oServiceOrderService     := TServiceOrderService():New() as object
	Local oServiceOrderSanitizer   := TServiceOrderSanitizer():New() as object
	Local oServiceOrdersListSanitizer := Nil as Object
	Local oServiceOrdersList       := Nil as Object
	Local nIndexServiceOrdersList  := 0 as numeric
	Local oServiceOrderJson        := Nil as Object

	Private cError := ""
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oServiceOrdersListSanitizer := oServiceOrderSanitizer:ToDestroy(oRequest["data"])

		oServiceOrdersList := oServiceOrderService:Destroy(oServiceOrdersListSanitizer)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexServiceOrdersList := 1 to oServiceOrdersList:getCount()

			oServiceOrderJson := JsonObject():New()

			if (Len(oServiceOrdersList:GetItem(nIndexServiceOrdersList):aErrors) >= 1)

				oServiceOrderJson["status"] := 400
				oServiceOrderJson["id"]       := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cCode
				oServiceOrderJson["errors"] := oServiceOrdersList:GetItem(nIndexServiceOrdersList):aErrors

				oResponse["error_total"] += 1

			else

				oServiceOrderJson["status"]   := 200
				oServiceOrderJson["id"]       := oServiceOrdersList:GetItem(nIndexServiceOrdersList):cCode

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oServiceOrderJson)

		next nIndexServiceOrdersList

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
