#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RESTFUL.CH"

WSRestFul WSCustomers Description "REST para Clientes no Protheus"

	WSData search as string optional
	WSData page as string optional
	WSData per_page as string optional
	WSData all_page as string optional
	WSData store as string optional
	
	WSMethod GET Description "Listar Clientes"     WSSYNTAX "/WSCustomers/{id}" Produces APPLICATION_JSON
	WSMethod POST Description "Cria Clientes"      WSSYNTAX "/WSCustomers"      Produces APPLICATION_JSON
	WSMethod PUT Description "Alterar Clientes"    WSSYNTAX "/WSCustomers"      Produces APPLICATION_JSON
	WSMethod DELETE Description "Deletar Clientes" WSSYNTAX "/WSCustomers"      Produces APPLICATION_JSON

END WSRESTFUL

WSMethod GET QueryParam search, page, per_page WSService WSCustomers

	Local oResponse           := Nil as object

	Local oCustomerService    :=  TCustomerService():New() as object
	Local nIndexCustomersList := 0 as numeric
	Local oCustomerData       := Nil as Object
	Local oCustomerJson       := Nil as Object

	Local lAllPage            := .F. as logical
	Local cSearch             := "" as character
	Local nPage               := 1 as numeric
	Local nPerPage            := 50 as numeric
	Local cStore              := "" as character

	Local cId := "" as character

	Private cError := "" as character
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	Default ::search := ""
	Default ::page := "1"
	Default ::per_page := "50"
	Default ::all_page := "false"
	Default ::store := ""

	begin sequence

		cSearch := Upper(AllTrim(::search))
		nPage  := Val(::page)
		nPerPage := Val(::per_page)
		lAllPage := if(::all_page == "true", .T., .F.)
		cStore := ::store

		cId := if(Len(::aURLParms) > 0, ::aURLParms[1], "")

		if !Empty(cId)

			oCustomerData := oCustomerService:Show(cId, cStore)

		else

			oCustomerData := oCustomerService:List(cSearch, nPage, nPerPage, lAllPage)

		endif

		oResponse := JsonObject():New()
		oResponse["page"] := oCustomerData["page"]
		oResponse["per_page"] := oCustomerData["per_page"]
		oResponse["total"] := oCustomerData["total"]
		oResponse["last_page"] := oCustomerData["last_page"]
		oResponse["data"] := {}

		for nIndexCustomersList := 1 to oCustomerData["data"]:getCount()

			oCustomerJson := JsonObject():New()


			if !Empty(cId)

				oCustomerJson["store"]                := oCustomerData["data"]:GetItem(nIndexCustomersList):cStore
				oCustomerJson["first_name"]           := oCustomerData["data"]:GetItem(nIndexCustomersList):cFirstName
				oCustomerJson["person_type"]          := oCustomerData["data"]:GetItem(nIndexCustomersList):cPersonType
				oCustomerJson["type"]                 := oCustomerData["data"]:GetItem(nIndexCustomersList):cType
				oCustomerJson["last_name"]            := oCustomerData["data"]:GetItem(nIndexCustomersList):cLastName
				oCustomerJson["cpf_cnpj"]             := oCustomerData["data"]:GetItem(nIndexCustomersList):cCpfCnpj
				oCustomerJson["address"]              := oCustomerData["data"]:GetItem(nIndexCustomersList):cAddress
				oCustomerJson["neighborhood"]         := oCustomerData["data"]:GetItem(nIndexCustomersList):cNeighborhood
				oCustomerJson["state"]                := oCustomerData["data"]:GetItem(nIndexCustomersList):cState
				oCustomerJson["zip_code"]             := oCustomerData["data"]:GetItem(nIndexCustomersList):cZipCode
				oCustomerJson["city_id"]              := oCustomerData["data"]:GetItem(nIndexCustomersList):cCityId
				oCustomerJson["credit_limit"]         := oCustomerData["data"]:GetItem(nIndexCustomersList):nCreditLimit
				oCustomerJson["risk_level"]           := oCustomerData["data"]:GetItem(nIndexCustomersList):cRiskLevel
				oCustomerJson["complement"]           := oCustomerData["data"]:GetItem(nIndexCustomersList):cComplement
				oCustomerJson["ddd"]                  := oCustomerData["data"]:GetItem(nIndexCustomersList):cDDD
				oCustomerJson["phone"]                := oCustomerData["data"]:GetItem(nIndexCustomersList):cPhone
				oCustomerJson["city"]                 := oCustomerData["data"]:GetItem(nIndexCustomersList):cCity
				oCustomerJson["fax"]                  := oCustomerData["data"]:GetItem(nIndexCustomersList):cFax
				oCustomerJson["contact"]              := oCustomerData["data"]:GetItem(nIndexCustomersList):cContact
				oCustomerJson["billing_address"]      := oCustomerData["data"]:GetItem(nIndexCustomersList):cBillingAddress
				oCustomerJson["billing_state"]        := oCustomerData["data"]:GetItem(nIndexCustomersList):cBillingState
				oCustomerJson["billing_city"]         := oCustomerData["data"]:GetItem(nIndexCustomersList):cBillingCity
				oCustomerJson["billing_neighborhood"] := oCustomerData["data"]:GetItem(nIndexCustomersList):cBillingNeighborhood
				oCustomerJson["billing_zip_code"]     := oCustomerData["data"]:GetItem(nIndexCustomersList):cBillingZipCode
				oCustomerJson["is_taxpayer"]          := oCustomerData["data"]:GetItem(nIndexCustomersList):lIsTaxpayer
				oCustomerJson["is_zero_hunger"]       := oCustomerData["data"]:GetItem(nIndexCustomersList):lIsZeroHunger
				oCustomerJson["country_code"]         := oCustomerData["data"]:GetItem(nIndexCustomersList):cCountryCode
				oCustomerJson["state_inscription"]    := oCustomerData["data"]:GetItem(nIndexCustomersList):cStateInscription
				oCustomerJson["city_inscription"]     := oCustomerData["data"]:GetItem(nIndexCustomersList):cCityInscription
				oCustomerJson["email"]                := oCustomerData["data"]:GetItem(nIndexCustomersList):cEmail

			else

				oCustomerJson["id"] := oCustomerData["data"]:GetItem(nIndexCustomersList):cCode
				oCustomerJson["store"] := oCustomerData["data"]:GetItem(nIndexCustomersList):cStore
				oCustomerJson["first_name"] := oCustomerData["data"]:GetItem(nIndexCustomersList):cFirstName
				oCustomerJson["cpf_cnpj"] := oCustomerData["data"]:GetItem(nIndexCustomersList):cCpfCnpj

			endIf

			Aadd(oResponse["data"], oCustomerJson)

		next nIndexCustomersList

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

WSMethod POST WSService WSCustomers

	Local oRequest             := JsonObject():New() as object
	Local oResponse            := JsonObject():New() as object

	Local oCustomerService     :=  TCustomerService():New() as object
	Local oCustomerSanitizer   := TCustomerSanitizer():New() as object
	Local oCustomersListParsed := Nil as Object
	Local oCustomersList       := Nil as Object
	Local nIndexCustomersList  := 0 as numeric
	Local oCustomerJson        := Nil as Object

	Private cError := "" as character
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oCustomersListParsed := oCustomerSanitizer:ToCreateOrUpdate(oRequest["data"])

		oCustomersList := oCustomerService:Store(oCustomersListParsed)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexCustomersList := 1 to oCustomersList:getCount()

			oCustomerJson := JsonObject():New()

			if (Len(oCustomersList:GetItem(nIndexCustomersList):aErrors) >= 1)

				oCustomerJson["status"] := 400
				oCustomerJson["errors"] := oCustomersList:GetItem(nIndexCustomersList):aErrors

				oResponse["error_total"] += 1

			else

				oCustomerJson["status"]   := 201
				oCustomerJson["id"]       := oCustomersList:GetItem(nIndexCustomersList):cCode
				oCustomerJson["first_name"]     := oCustomersList:GetItem(nIndexCustomersList):cFirstName
				oCustomerJson["cpf_cnpj"]     := oCustomersList:GetItem(nIndexCustomersList):cCpfCnpj
				oCustomerJson["store"]     := oCustomersList:GetItem(nIndexCustomersList):cStore

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oCustomerJson)

		next nIndexCustomersList

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


WSMethod PUT WSService WSCustomers

	Local oRequest             := JsonObject():New() as object
	Local oResponse            := JsonObject():New() as object

	Local oCustomerService     :=  TCustomerService():New() as object
	Local oCustomerSanitizer   := TCustomerSanitizer():New() as object
	Local oCustomersListParsed := Nil as Object
	Local oCustomersList       := Nil as Object
	Local nIndexCustomersList  := 0 as numeric
	Local oCustomerJson        := Nil as Object

	Private cError := ""
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oCustomersListParsed := oCustomerSanitizer:ToCreateOrUpdate(oRequest["data"])

		oCustomersList := oCustomerService:Update(oCustomersListParsed)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexCustomersList := 1 to oCustomersList:getCount()

			oCustomerJson := JsonObject():New()

			if (Len(oCustomersList:GetItem(nIndexCustomersList):aErrors) >= 1)

				oCustomerJson["status"] := 400
				oCustomerJson["errors"] := oCustomersList:GetItem(nIndexCustomersList):aErrors

				oResponse["error_total"] += 1

			else

				oCustomerJson["status"]   := 200
				oCustomerJson["id"]       := oCustomersList:GetItem(nIndexCustomersList):cCode
				oCustomerJson["first_name"]     := oCustomersList:GetItem(nIndexCustomersList):cFirstName
				oCustomerJson["cpf_cnpj"]     := oCustomersList:GetItem(nIndexCustomersList):cCpfCnpj
				oCustomerJson["store"]     := oCustomersList:GetItem(nIndexCustomersList):cStore

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oCustomerJson)

		next nIndexCustomersList

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

WSMethod DELETE WSService WSCustomers

	Local oRequest             := JsonObject():New() as object
	Local oResponse            := JsonObject():New() as object

	Local oCustomerService     :=  TCustomerService():New() as object
	Local oCustomerSanitizer   := TCustomerSanitizer():New() as object
	Local oCustomersListSanitizer := Nil as Object
	Local oCustomersList       := Nil as Object
	Local nIndexCustomersList  := 0 as numeric
	Local oCustomerJson        := Nil as Object

	Private cError := ""
	Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

	begin Sequence

		oRequest:FromJSON(::GetContent())

		oCustomersListSanitizer := oCustomerSanitizer:ToDestroy(oRequest["data"])

		oCustomersList := oCustomerService:Destroy(oCustomersListSanitizer)

		oResponse["data"]          := {}
		oResponse["success_total"] := 0
		oResponse["error_total"]   := 0
		oResponse["total"]   := 0

		for nIndexCustomersList := 1 to oCustomersList:getCount()

			oCustomerJson := JsonObject():New()

			if (Len(oCustomersList:GetItem(nIndexCustomersList):aErrors) >= 1)

				oCustomerJson["status"] := 400
				oCustomerJson["id"]       := oCustomersList:GetItem(nIndexCustomersList):cCode
				oCustomerJson["errors"] := oCustomersList:GetItem(nIndexCustomersList):aErrors

				oResponse["error_total"] += 1

			else

				oCustomerJson["status"]   := 200
				oCustomerJson["id"]       := oCustomersList:GetItem(nIndexCustomersList):cCode

				oResponse["success_total"] += 1

			endif

			aAdd(	oResponse["data"], oCustomerJson)

		next nIndexCustomersList

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
