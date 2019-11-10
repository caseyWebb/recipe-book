module UI.Autocomplete exposing (Msg, Options, State, init, subscriptions, update, view)

import Element
import Html
import Html.Attributes
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
    , menu : Menu.State
    }


type Msg
    = MenuMsg Menu.Msg
    | UpdateQuery String


init : State
init =
    { query = ""
    , menu = Menu.empty
    }


view : Options msg -> Element.Element msg
view options =
    Element.column []
        [ UI.textInput
            { onChange = \s -> options.msg (UpdateQuery s)
            , text = options.state.query
            , placeholder = options.placeholder
            , label = Nothing
            }
        , Menu.view viewConfig 10 options.state.menu options.data
            |> Html.map MenuMsg
            |> Html.map options.msg
            |> Element.html
        ]


update : Options msg -> Msg -> ( State, Maybe msg )
update options msg =
    let
        state =
            options.state

        data =
            options.data
                |> List.map String.toLower
                |> List.filter (String.contains options.state.query)
    in
    case msg of
        MenuMsg menuMsg ->
            let
                ( newMenuState, maybeMsg ) =
                    Menu.update (updateConfig options) menuMsg 10 options.state.menu data
            in
            ( { state | menu = newMenuState }, maybeMsg )

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
    Menu.viewConfig
        { toId = identity
        , ul =
            []
        , li =
            \mouseFocused keyboardFocused text ->
                { attributes =
                    [ Html.Attributes.classList
                        [ ( "selected", mouseFocused || keyboardFocused )
                        , ( "mouse"
                          , mouseFocused
                          )
                        , ( "key"
                          , keyboardFocused
                          )
                        ]
                    ]
                , children =
                    [ Html.text text ]
                }
        }
