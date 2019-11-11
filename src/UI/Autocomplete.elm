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
    , query : String
    , inputFocused : Bool
    , menu : Menu.State
    }


type Msg
    = MenuMsg Menu.Msg
    | InputFocused
    | InputBlurred
    | UpdateQuery String
    | OptionSelected String
    | CreateNewOption
    | Reset Menu.State
    | NoOp


init : List String -> Model
init data =
    { data = data
    , query = ""
    , inputFocused = False
    , menu = Menu.empty
    }


view : Options msg -> Model -> Element.Element msg
view options model =
    let
        data =
            getFilteredData model

        dropdownMenu =
            if model.inputFocused && not (List.isEmpty data) then
                Element.el
                    [ Element.width Element.fill
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
                    (Menu.view viewConfig 10 model.menu data
                        |> Html.map MenuMsg
                        |> Html.map options.msg
                        |> Element.html
                    )

            else
                Element.none

        wrapHandler handler =
            handler |> Element.htmlAttribute

        tabEnterDecoderHelper code =
            if code == 9 || code == 13 then
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
        , wrapHandler <| Html.Events.onFocus (options.msg InputFocused)
        , wrapHandler <| Html.Events.onBlur (options.msg InputBlurred)
        , wrapHandler <| Html.Events.preventDefaultOn "keydown" tabEnterDecoder
        ]
        { onChange = \s -> options.msg (UpdateQuery s)
        , text = model.query
        , placeholder = options.placeholder
        , label = Nothing
        }


update : Options msg -> Model -> Msg -> ( Model, Maybe msg )
update options model msg =
    let
        filteredData =
            getFilteredData model

        resetMenuModel =
            Menu.resetToFirstItem updateConfig filteredData 10 model.menu

        updatedModel =
            { model | menu = resetMenuModel }
    in
    case msg of
        MenuMsg menuMsg ->
            let
                ( newMenuModel, maybeMsg ) =
                    Menu.update updateConfig menuMsg 10 model.menu filteredData

                mappedMsg =
                    Maybe.map options.msg maybeMsg
            in
            ( { updatedModel | menu = newMenuModel }, mappedMsg )

        InputFocused ->
            ( { updatedModel | inputFocused = True }, Nothing )

        InputBlurred ->
            ( { updatedModel | inputFocused = False }, Nothing )

        UpdateQuery newQuery ->
            ( { updatedModel | query = newQuery }, Nothing )

        CreateNewOption ->
            let
                updateSelectionMsg =
                    Just <| options.onSelect model.query
            in
            ( { updatedModel | query = "" }, updateSelectionMsg )

        OptionSelected selection ->
            let
                updateSelectionMsg =
                    Just <| options.onSelect selection
            in
            ( { updatedModel | query = "" }, updateSelectionMsg )

        Reset updatedMenu ->
            ( { model | query = "", menu = updatedMenu }, Nothing )

        NoOp ->
            ( model, Nothing )


updateConfig : Menu.UpdateConfig Msg String
updateConfig =
    Menu.updateConfig
        { toId = identity
        , onKeyDown =
            \code maybeId ->
                if code == 9 then
                    Maybe.map OptionSelected maybeId

                else if code == 13 then
                    Just CreateNewOption

                else
                    Nothing
        , onTooLow = Nothing
        , onTooHigh = Nothing
        , onMouseEnter = \_ -> Nothing
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| OptionSelected id
        , separateSelections = False
        }


reset : Options msg -> Model -> msg
reset options model =
    let
        filteredData =
            getFilteredData model
    in
    options.msg <| Reset (Menu.resetToFirstItem updateConfig filteredData 10 model.menu)


subscriptions : Options msg -> Sub msg
subscriptions options =
    Menu.subscription |> Sub.map MenuMsg |> Sub.map options.msg


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
                        , ( "background-color", "#fafafa", mouseFocused )
                        , ( "background-color", "#f5fafd", keyboardFocused )
                        , ( "color", "495c68", mouseFocused || keyboardFocused )
                        ]
                , children =
                    [ Html.text text ]
                }
        }


getFilteredData : Model -> List String
getFilteredData model =
    let
        query =
            String.toLower model.query

        searchCaseInsensitive =
            \s -> String.toLower s |> String.contains query
    in
    List.filter searchCaseInsensitive model.data
