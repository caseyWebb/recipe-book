module UI.Autocomplete exposing (Msg, Options, State, init, subscriptions, update, view)

import Element
import Element.Background as Background
import Element.Border as Border
import Html
import Html.Attributes
import Html.Events
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


init : State
init =
    { query = ""
    , inputFocused = False
    , menu = Menu.empty
    }


view : Options msg -> Element.Element msg
view options =
    let
        query =
            String.toLower options.state.query

        data =
            options.data |> List.filter (\s -> String.toLower s |> String.contains query)

        dropdownMenu =
            if options.state.inputFocused then
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
                        |> Element.minimum 50
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

        onFocus =
            wrapHandler <| Html.Events.onFocus (options.msg InputFocused)

        onBlur =
            wrapHandler <| Html.Events.onBlur (options.msg InputBlurred)
    in
    UI.textInput
        [ Element.below dropdownMenu
        , onFocus
        , onBlur
        ]
        { onChange = \s -> options.msg (UpdateQuery s)
        , text = options.state.query
        , placeholder = options.placeholder
        , label = Nothing
        }


update : Options msg -> Msg -> ( State, Maybe msg )
update options msg =
    let
        state =
            options.state
    in
    case msg of
        MenuMsg menuMsg ->
            let
                ( newMenuState, maybeMsg ) =
                    Menu.update (updateConfig options) menuMsg 10 options.state.menu options.data
            in
            ( { state | menu = newMenuState }, maybeMsg )

        InputFocused ->
            ( { state | inputFocused = True }, Nothing )

        InputBlurred ->
            ( { state | inputFocused = False }, Nothing )

        UpdateQuery newQuery ->
            ( { state | query = newQuery }, Nothing )


updateConfig : Options msg -> Menu.UpdateConfig msg String
updateConfig options =
    Menu.updateConfig
        { toId = identity
        , onKeyDown =
            \code maybeId ->
                if code == 13 then
                    Maybe.map options.onSelect maybeId

                else
                    Nothing
        , onTooLow = Nothing
        , onTooHigh = Nothing
        , onMouseEnter = \_ -> Nothing
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| options.onSelect id
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
