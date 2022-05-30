    #INCLUDE "TOTVS.CH"
    #INCLUDE "TOPCONN.CH"
    #INCLUDE "RESTFUL.CH"

    WSRestFul WSPlaces Description "REST para Localidades no Protheus"

    WSData search as string optional
    WSData page as string optional
    WSData per_page as string optional
    WSData all_page as string optional

    WSMethod GET Description "Listar Localidades" WSSYNTAX "/WSPlaces/{id}" Produces APPLICATION_JSON
    WSMethod POST Description "Cria Localidade" WSSYNTAX "/WSPlaces" Produces APPLICATION_JSON
    WSMethod PUT Description "Alterar Localidade" WSSYNTAX "/WSPlaces" Produces APPLICATION_JSON
    WSMethod DELETE Description "Deletar Localidade" WSSYNTAX "/WSPlaces" Produces APPLICATION_JSON

    END WSRESTFUL

    WSMethod GET QueryParam search, page, per_page WSService WSPlaces

    Local oResponse := Nil as object

    Local oPlaceService := TPlaceService():New() as object
    Local nIndexPlacesList := 0 as numeric
    Local oPlaceData := Nil as Object
    Local oPlaceJson := Nil as Object

    Local lAllPage := .F. as logical
    Local cSearch := "" as character
    Local nPage := 1 as numeric
    Local nPerPage := 50 as numeric

    Local cId := "" as character

    Private cError := "" as character
    Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

    Default ::search := ""
    Default ::page := "1"
    Default ::per_page := "50"
    Default ::all_page := "false"

    begin sequence

    ::SetContentType("application/json; charset=UTF-8")

    cSearch := Upper(AllTrim(::search))
    nPage := Val(::page)
    nPerPage := Val(::per_page)
    lAllPage := if(::all_page == "true", .T., .F.)

    cId := if(Len(::aURLParms) > 0, ::aURLParms[1], "")

    if !Empty(cId)

      oPlaceData := oPlaceService:Show(cId)

    else

      oPlaceData := oPlaceService:List(cSearch, nPage, nPerPage, lAllPage)

    endif

    oResponse := JsonObject():New()
    oResponse["page"] := oPlaceData["page"]
    oResponse["per_page"] := oPlaceData["per_page"]
    oResponse["total"] := oPlaceData["total"]
    oResponse["last_page"] := oPlaceData["last_page"]
    oResponse["data"] := {}

    for nIndexPlacesList := 1 to oPlaceData["data"]:getCount()

      oPlaceJson := JsonObject():New()

      oPlaceJson["id"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cCode
      oPlaceJson["description"] := (oPlaceData["data"]:GetItem(nIndexPlacesList):cDescription)
      oPlaceJson["entity_type"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cEntityType
      oPlaceJson["customer_id"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cCustomerId
      oPlaceJson["customer_store"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cCustomerStore
      oPlaceJson["region"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cRegion
      oPlaceJson["address"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cAddress
      oPlaceJson["neighborhood"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cNeighborhood
      oPlaceJson["city"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cCity
      oPlaceJson["state"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cState
      oPlaceJson["zip_code"] := oPlaceData["data"]:GetItem(nIndexPlacesList):cZipCode

      Aadd(oResponse["data"], oPlaceJson)

    next nIndexPlacesList

    end sequence

    if !Empty(cError) // error begin sequence

      oResponse := JsonObject():New()

      oResponse["error"] := JsonObject():New()
      oResponse["error"]["status"] := 400
      oResponse["error"]["message"] := cError

      ::SetStatus(400)

    else

      ::SetStatus(200)

    endif

    ::SetResponse(oResponse:ToJson())

    ErrorBlock(bError)

    Return(.T.)

    WSMethod POST WSService WSPlaces

    Local oRequest := JsonObject():New() as object
    Local oResponse := JsonObject():New() as object

    Local oPlaceService := TPlaceService():New() as object
    Local oPlaceSanitizer := TPlaceSanitizer():New() as object
    Local oPlacesListParsed := Nil as Object
    Local oPlacesList := Nil as Object
    Local nIndexPlacesList := 0 as numeric
    Local oPlaceJson := Nil as Object

    Private cError := "" as character
    Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

    begin Sequence

    oRequest:FromJSON(::GetContent())

    oPlacesListParsed := oPlaceSanitizer:ToCreateOrUpdate(oRequest["data"])

    oPlacesList := oPlaceService:Store(oPlacesListParsed)

    oResponse["data"] := {}
    oResponse["success_total"] := 0
    oResponse["error_total"] := 0
    oResponse["total"] := 0

    for nIndexPlacesList := 1 to oPlacesList:getCount()

      oPlaceJson := JsonObject():New()

      if (Len(oPlacesList:GetItem(nIndexPlacesList):aErrors) >= 1)

        oPlaceJson["status"] := 400
        oPlaceJson["errors"] := oPlacesList:GetItem(nIndexPlacesList):aErrors

        oResponse["error_total"] += 1

      else

        oPlaceJson["status"] := 201
        oPlaceJson["id"] := oPlacesList:GetItem(nIndexPlacesList):cCode
        oPlaceJson["description"] := oPlacesList:GetItem(nIndexPlacesList):cDescription
        oPlaceJson["entity_type"] := oPlacesList:GetItem(nIndexPlacesList):cEntityType
        oPlaceJson["customer_id"] := oPlacesList:GetItem(nIndexPlacesList):cCustomerId
        oPlaceJson["customer_store"] := oPlacesList:GetItem(nIndexPlacesList):cCustomerStore
        oPlaceJson["region"] := oPlacesList:GetItem(nIndexPlacesList):cRegion
        oPlaceJson["address"] := oPlacesList:GetItem(nIndexPlacesList):cAddress
        oPlaceJson["neighborhood"] := oPlacesList:GetItem(nIndexPlacesList):cNeighborhood
        oPlaceJson["city"] := oPlacesList:GetItem(nIndexPlacesList):cCity
        oPlaceJson["state"] := oPlacesList:GetItem(nIndexPlacesList):cState
        oPlaceJson["zip_code"] := oPlacesList:GetItem(nIndexPlacesList):cZipCode

        oResponse["success_total"] += 1

      endif

      aAdd( oResponse["data"], oPlaceJson)

    next nIndexPlacesList

    end sequence

    if !Empty(cError)

      oResponse := JsonObject():New()

      oResponse["error"] := JsonObject():New()
      oResponse["error"]["status"] := 400
      oResponse["error"]["message"] := cError

      ::SetStatus(400)

    else

      oResponse["total"] := Len(oResponse["data"])
      ::SetStatus(207)

    endif

    ::SetContentType("application/json; charset=UTF-8")
    ::SetResponse(oResponse:ToJson())

    ErrorBlock(bError)

    Return(.T.)


    WSMethod PUT WSService WSPlaces

    Local oRequest := JsonObject():New() as object
    Local oResponse := JsonObject():New() as object

    Local oPlaceService := TPlaceService():New() as object
    Local oPlaceSanitizer := TPlaceSanitizer():New() as object
    Local oPlacesListParsed := Nil as Object
    Local oPlacesList := Nil as Object
    Local nIndexPlacesList := 0 as numeric
    Local oPlaceJson := Nil as Object

    Private cError := ""
    Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

    begin Sequence

    ::SetContentType("application/json; charset=UTF-8")

    oRequest:FromJSON(::GetContent())

    oPlacesListParsed := oPlaceSanitizer:ToCreateOrUpdate(oRequest["data"])

    oPlacesList := oPlaceService:Update(oPlacesListParsed)

    oResponse["data"] := {}
    oResponse["success_total"] := 0
    oResponse["error_total"] := 0
    oResponse["total"] := 0

    for nIndexPlacesList := 1 to oPlacesList:getCount()

      oPlaceJson := JsonObject():New()

      if (Len(oPlacesList:GetItem(nIndexPlacesList):aErrors) >= 1)

        oPlaceJson["status"] := 400
        oPlaceJson["errors"] := oPlacesList:GetItem(nIndexPlacesList):aErrors

        oResponse["error_total"] += 1

      else

        oPlaceJson["status"] := 201
        oPlaceJson["id"] := oPlacesList:GetItem(nIndexPlacesList):cCode
        oPlaceJson["description"] := oPlacesList:GetItem(nIndexPlacesList):cDescription
        oPlaceJson["entity_type"] := oPlacesList:GetItem(nIndexPlacesList):cEntityType
        oPlaceJson["customer_id"] := oPlacesList:GetItem(nIndexPlacesList):cCustomerId
        oPlaceJson["customer_store"] := oPlacesList:GetItem(nIndexPlacesList):cCustomerStore
        oPlaceJson["region"] := oPlacesList:GetItem(nIndexPlacesList):cRegion
        oPlaceJson["address"] := oPlacesList:GetItem(nIndexPlacesList):cAddress
        oPlaceJson["neighborhood"] := oPlacesList:GetItem(nIndexPlacesList):cNeighborhood
        oPlaceJson["city"] := oPlacesList:GetItem(nIndexPlacesList):cCity
        oPlaceJson["state"] := oPlacesList:GetItem(nIndexPlacesList):cState
        oPlaceJson["zip_code"] := oPlacesList:GetItem(nIndexPlacesList):cZipCode

        oResponse["success_total"] += 1

      endif

      aAdd( oResponse["data"], oPlaceJson)

    next nIndexPlacesList

    end sequence

    if !Empty(cError)

      oResponse := JsonObject():New()

      oResponse["error"] := JsonObject():New()
      oResponse["error"]["status"] := 400
      oResponse["error"]["message"] := cError

      ::SetStatus(400)

    else

      oResponse["total"] := Len(oResponse["data"])
      ::SetStatus(207)

    endif

    ::SetResponse(oResponse:ToJson())

    ErrorBlock(bError)

    Return(.T.)

    WSMethod DELETE WSService WSPlaces

    Local oRequest := JsonObject():New() as object
    Local oResponse := JsonObject():New() as object

    Local oPlaceService := TPlaceService():New() as object
    Local oPlaceSanitizer := TPlaceSanitizer():New() as object
    Local oPlacesListSanitizer := Nil as Object
    Local oPlacesList := Nil as Object
    Local nIndexPlacesList := 0 as numeric
    Local oPlaceJson := Nil as Object

    Private cError := ""
    Private bError := ErrorBlock({ |oError| cError := oError:Description}) as codeblock

    begin Sequence

    oRequest:FromJSON(::GetContent())

    oPlacesListSanitizer := oPlaceSanitizer:ToDestroy(oRequest["data"])

    oPlacesList := oPlaceService:Destroy(oPlacesListSanitizer)

    oResponse["data"] := {}
    oResponse["success_total"] := 0
    oResponse["error_total"] := 0
    oResponse["total"] := 0

    for nIndexPlacesList := 1 to oPlacesList:getCount()

      oPlaceJson := JsonObject():New()

      if (Len(oPlacesList:GetItem(nIndexPlacesList):aErrors) >= 1)

        oPlaceJson["status"] := 400
        oPlaceJson["id"] := oPlacesList:GetItem(nIndexPlacesList):cCode
        oPlaceJson["errors"] := oPlacesList:GetItem(nIndexPlacesList):aErrors

        oResponse["error_total"] += 1

      else

        oPlaceJson["status"] := 200
        oPlaceJson["id"] := oPlacesList:GetItem(nIndexPlacesList):cCode

        oResponse["success_total"] += 1

      endif

      aAdd( oResponse["data"], oPlaceJson)

    next nIndexPlacesList

    end sequence

    if !Empty(cError)

      oResponse := JsonObject():New()

      oResponse["error"] := JsonObject():New()
      oResponse["error"]["status"] := 400
      oResponse["error"]["message"] := cError

      ::SetStatus(400)

    else

      oResponse["total"] := Len(oResponse["data"])
      ::SetStatus(207)

    endif

    ::SetContentType("application/json; charset=UTF-8")
    ::SetResponse(oResponse:ToJson())

    ErrorBlock(bError)

    Return(.T.)
