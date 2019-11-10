module UI.Autocomplete exposing (Msg, Options, State, init, subscriptions, update, view)

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
    , state : State
    , msg : Msg -> msg
    , data : List String
    , onSelect : String -> msg
    }


type alias State =
    { query : String
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
    | NoOp


init : State
init =
    { query = ""
    , inputFocused = False
    , menu = Menu.empty
    }


view : Options msg -> Element.Element msg
view options =
    let
        data =
            getFilteredData options

        dropdownMenu =
            if options.state.inputFocused && not (List.isEmpty data) then
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
                    (Menu.view viewConfig 10 options.state.menu data
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
        , text = options.state.query
        , placeholder = options.placeholder
        , label = Nothing
        }


update : Options msg -> Msg -> ( State, Maybe msg )
update options msg =
    let
        filteredData =
            getFilteredData options

        resetMenuState =
            Menu.resetToFirstItem updateConfig filteredData 10 options.state.menu

        currentState =
            options.state

        updatedState =
            { currentState | menu = resetMenuState }
    in
    case msg of
        MenuMsg menuMsg ->
            let
                ( newMenuState, maybeMsg ) =
                    Menu.update updateConfig menuMsg 10 options.state.menu filteredData

                mappedMsg =
                    Maybe.map options.msg maybeMsg
            in
            ( { updatedState | menu = newMenuState }, mappedMsg )

        InputFocused ->
            ( { updatedState | inputFocused = True }, Nothing )

        InputBlurred ->
            ( { updatedState | inputFocused = False }, Nothing )

        UpdateQuery newQuery ->
            ( { updatedState | query = newQuery }, Nothing )

        CreateNewOption ->
            let
                updateSelectionMsg =
                    Just <| options.onSelect options.state.query
            in
            ( { updatedState | query = "" }, updateSelectionMsg )

        OptionSelected selection ->
            let
                updateSelectionMsg =
                    Just <| options.onSelect selection
            in
            ( { updatedState | query = "" }, updateSelectionMsg )

        NoOp ->
            ( options.state, Nothing )


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


getFilteredData : Options msg -> List String
getFilteredData options =
    let
        query =
            String.toLower options.state.query

        searchCaseInsensitive =
            \s -> String.toLower s |> String.contains query
    in
    List.filter searchCaseInsensitive options.data
