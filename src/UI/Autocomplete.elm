module UI.Autocomplete exposing (Msg, Options, State, init, update, view)

import Element
import Html
import Html.Attributes
import Menu


type alias Options msg =
    { placeholder : String
    , state : State
    , msg : Msg -> msg
    , data : List String
    , onSelect : String -> msg
    }


type alias State =
    Menu.State


type alias Msg =
    Menu.Msg


init : Menu.State
init =
    Menu.empty


view : Options msg -> Element.Element msg
view options =
    Menu.view viewConfig 10 options.state options.data
        |> Html.map options.msg
        |> Element.html


update : Options msg -> Menu.Msg -> ( Menu.State, Maybe msg )
update options msg =
    Menu.update (updateConfig options) msg 10 options.state options.data


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
