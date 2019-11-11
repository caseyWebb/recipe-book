module UI.Autocomplete exposing (Model, Msg, Options, init, reset, subscriptions, update, view)

import Element
import Element.Background as Background
import Element.Border as Border
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Menu
import UI


type alias Options msg =
    { placeholder : Maybe String
    , msg : Msg -> msg
    , onSelect : String -> msg
    }


type alias Model =
    { data : List String
    , filteredData : List String
    , query : String
    , inputFocused : Bool
    , menu : Menu.State
    }


type Msg
    = MenuMsg Menu.Msg
    | FocusStateChanged Bool
    | UpdateQuery String
    | OptionSelected String
    | CreateNewOption
    | Reset Menu.State
    | EnterDropdown
    | NoOp


init : List String -> Model
init data =
    { data = data
    , filteredData = data
    , query = ""
    , inputFocused = False
    , menu = Menu.empty
    }


update : Options msg -> Model -> Msg -> ( Model, Maybe msg )
update options model msg =
    case msg of
        MenuMsg menuMsg ->
            let
                ( newMenuModel, maybeMsg ) =
                    Menu.update updateConfig menuMsg 10 model.menu model.filteredData

                mappedMsg =
                    Maybe.map options.msg maybeMsg
            in
            ( { model | menu = newMenuModel }, mappedMsg )

        FocusStateChanged focused ->
            let
                updatedMenu =
                    if focused then
                        model.menu

                    else
                        Menu.reset updateConfig model.menu
            in
            ( { model | inputFocused = focused, menu = updatedMenu }, Nothing )

        EnterDropdown ->
            let
                updatedMenu =
                    Menu.resetToFirstItem updateConfig model.filteredData 10 model.menu

                updatedModel =
                    { model | menu = updatedMenu }
            in
            ( updatedModel, Nothing )

        UpdateQuery updatedQuery ->
            let
                updatedFilteredData =
                    getFilteredData model.data updatedQuery

                updatedMenuModel =
                    if String.isEmpty updatedQuery then
                        Menu.reset updateConfig model.menu

                    else
                        Menu.resetToFirstItem updateConfig updatedFilteredData 10 model.menu
            in
            ( { model
                | query = updatedQuery
                , filteredData = updatedFilteredData
                , menu = updatedMenuModel
              }
            , Nothing
            )

        CreateNewOption ->
            ( model, Just <| options.onSelect model.query )

        OptionSelected selection ->
            ( model, Just <| options.onSelect selection )

        Reset updatedMenu ->
            update options { model | menu = updatedMenu } (UpdateQuery "")

        NoOp ->
            ( model, Nothing )


updateConfig : Menu.UpdateConfig Msg String
updateConfig =
    Menu.updateConfig
        { toId = identity
        , onKeyDown =
            \code maybeId ->
                case code of
                    13 ->
                        Maybe.map OptionSelected maybeId
                            |> Maybe.withDefault CreateNewOption
                            |> Just

                    -- ESC
                    27 ->
                        Just (FocusStateChanged False)

                    _ ->
                        Just (FocusStateChanged True)
        , onTooLow = Just EnterDropdown
        , onTooHigh = Nothing
        , onMouseEnter = \_ -> Nothing
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| OptionSelected id
        , separateSelections = False
        }


reset : Options msg -> Model -> msg
reset options model =
    options.msg <| Reset (Menu.reset updateConfig model.menu)


subscriptions : Options msg -> Sub msg
subscriptions options =
    Menu.subscription |> Sub.map MenuMsg |> Sub.map options.msg


view : Options msg -> Model -> Element.Element msg
view options model =
    let
        dropdownMenu =
            if not (List.isEmpty model.filteredData) then
                Element.el
                    [ Element.transparent (not model.inputFocused)
                    , Element.width Element.fill
                    , Border.solid
                    , Border.color <| Element.rgba 0 0 0 0.15
                    , Border.width 1
                    , Border.rounded 2
                    , Background.color <| Element.rgb 1 1 1
                    , Border.shadow
                        { offset = ( 0, 0 )
                        , size = 3
                        , blur = 10
                        , color = Element.rgba 0 0 0 0.175
                        }
                    , Element.fill
                        |> Element.maximum 300
                        |> Element.height
                    ]
                    (Menu.view viewConfig 10 model.menu model.filteredData
                        |> Html.map MenuMsg
                        |> Html.map options.msg
                        |> Element.html
                    )

            else
                Element.none

        wrapHandler handler =
            handler |> Element.htmlAttribute

        tabEnterDecoderHelper code =
            if code == 13 then
                Decode.succeed (options.msg NoOp)

            else
                Decode.fail "not handling that key"

        tabEnterDecoder =
            Html.Events.keyCode
                |> Decode.andThen tabEnterDecoderHelper
                |> Decode.map (\msg -> ( msg, True ))
    in
    UI.textInput
        [ Element.below dropdownMenu
        , wrapHandler <| Html.Events.onFocus (options.msg (FocusStateChanged True))
        , wrapHandler <| Html.Events.onBlur (options.msg (FocusStateChanged False))
        , wrapHandler <| Html.Events.preventDefaultOn "keydown" tabEnterDecoder
        ]
        { onChange = \s -> options.msg (UpdateQuery s)
        , text = model.query
        , placeholder = options.placeholder
        , label = Nothing
        }


viewConfig : Menu.ViewConfig String
viewConfig =
    let
        inlineStyles : List ( String, String, Bool ) -> List (Html.Attribute Never)
        inlineStyles styles =
            styles
                |> List.filter (\( _, _, use ) -> use)
                |> List.map (\( rule, value, _ ) -> Html.Attributes.style rule value)
    in
    Menu.viewConfig
        { toId = identity
        , ul =
            inlineStyles
                [ ( "list-style", "none", True )
                , ( "padding", "0", True )
                , ( "margin", "0", True )
                , ( "overflow-y", "auto", True )
                ]
        , li =
            \mouseFocused keyboardFocused text ->
                { attributes =
                    inlineStyles
                        [ ( "display", "block", True )
                        , ( "padding", "9px 8px", True )
                        , ( "cursor", "pointer", True )
                        , ( "font-size", "16px", True )
                        , ( "line-height", "24px", True )
                        , ( "color", "#555", True )
                        , ( "background-color", "#f5fafd", mouseFocused || keyboardFocused )
                        , ( "color", "495c68", mouseFocused || keyboardFocused )
                        ]
                , children =
                    [ Html.text text ]
                }
        }


getFilteredData : List String -> String -> List String
getFilteredData data query =
    let
        lowerQuery =
            String.toLower query

        searchCaseInsensitive =
            \s -> String.toLower s |> String.contains lowerQuery
    in
    List.filter searchCaseInsensitive data
