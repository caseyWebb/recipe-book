module UI.Autocomplete exposing (Autocomplete, Model, Msg, Options, with)

import Dict
import Element
import Element.Background as Background
import Element.Border as Border
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Menu
import UI


type alias Options msg a =
    { placeholder : Maybe String
    , msg : Msg a -> msg
    , onSelect : a -> msg
    , mapData : a -> String
    , createNew : String -> a
    }


type alias Model a =
    { data : Dict.Dict String a
    , filteredData : List String
    , query : String
    , inputFocused : Bool
    , menu : Menu.State
    }


type Msg a
    = MenuMsg Menu.Msg
    | FocusStateChanged Bool
    | UpdateQuery String
    | OptionSelected String
    | Reset Menu.State
    | EnterDropdown


type alias Autocomplete msg a =
    { init : List a -> Model a
    , update : Model a -> Msg a -> ( Model a, Maybe msg )
    , reset : Model a -> msg
    , resetData : Model a -> List a -> ( Model a, msg )
    , subscriptions : Sub msg
    , view : Model a -> Element.Element msg
    }


with : Options msg a -> Autocomplete msg a
with options =
    { init = init options
    , update = update options
    , reset = reset options
    , resetData = resetData options
    , subscriptions = subscriptions options
    , view = view options
    }


init : Options msg a -> List a -> Model a
init options data =
    { data =
        data
            |> List.map (\d -> ( options.mapData d, d ))
            |> Dict.fromList
    , filteredData = []
    , query = ""
    , inputFocused = False
    , menu = Menu.empty
    }


update : Options msg a -> Model a -> Msg a -> ( Model a, Maybe msg )
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
                    getFilteredData options model.data updatedQuery

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

        OptionSelected selection ->
            let
                selectedOption =
                    Dict.get selection model.data |> Maybe.withDefault (options.createNew selection)
            in
            ( model, Just <| options.onSelect selectedOption )

        Reset updatedMenu ->
            update options { model | menu = updatedMenu } (UpdateQuery "")


updateConfig : Menu.UpdateConfig (Msg a) String
updateConfig =
    Menu.updateConfig
        { toId = identity
        , onKeyDown =
            \code _ ->
                case code of
                    27 ->
                        Just (FocusStateChanged False)

                    _ ->
                        Nothing
        , onTooLow = Just EnterDropdown
        , onTooHigh = Nothing
        , onMouseEnter = \_ -> Nothing
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| OptionSelected id
        , separateSelections = False
        }


reset : Options msg a -> Model a -> msg
reset options model =
    options.msg <| Reset (Menu.reset updateConfig model.menu)


resetData : Options msg a -> Model a -> List a -> ( Model a, msg )
resetData options model data =
    let
        updatedModel =
            { model
                | data =
                    data
                        |> List.map (\d -> ( options.mapData d, d ))
                        |> Dict.fromList
            }
    in
    ( updatedModel, reset options updatedModel )


subscriptions : Options msg a -> Sub msg
subscriptions options =
    Menu.subscription |> Sub.map MenuMsg |> Sub.map options.msg


view : Options msg a -> Model a -> Element.Element msg
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
            let
                ( maybeSelection, _ ) =
                    Menu.current model.menu

                noop =
                    Decode.fail "noop"

                preventDefaultAnd : Msg a -> Decode.Decoder msg
                preventDefaultAnd msg =
                    Decode.succeed <| options.msg msg
            in
            if code == 9 || code == 13 then
                case maybeSelection of
                    Just selection ->
                        preventDefaultAnd <| OptionSelected selection

                    Nothing ->
                        if String.isEmpty model.query then
                            noop

                        else
                            preventDefaultAnd <| OptionSelected model.query

            else
                noop

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
            \mouseFocused keyboardFocused item ->
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
                    [ Html.text item ]
                }
        }


getFilteredData : Options msg a -> Dict.Dict String a -> String -> List String
getFilteredData options data query =
    let
        lowerQuery =
            String.toLower query

        mappedData =
            List.map options.mapData (Dict.values data)

        searchCaseInsensitive =
            \s -> String.toLower s |> String.contains lowerQuery
    in
    List.filter searchCaseInsensitive mappedData
