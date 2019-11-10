module UI exposing (TextInputOptions, button, header, link, render, textInput)

import Element exposing (Element, el, text)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Route


render : Element msg -> Html.Html msg
render el =
    Element.layout
        [ Font.family
            [ Font.typeface "Source Sans Pro"
            , Font.typeface "Helvetica Neue"
            , Font.sansSerif
            ]
        ]
    <|
        el


header : String -> Element msg
header t =
    el
        [ Font.size 24
        , Font.bold
        ]
    <|
        text t


link : String -> Route.Route -> Element msg
link label route =
    Element.link [] { label = Element.text label, url = Route.toString route }


type alias ButtonOptions msg =
    { onPress : Maybe msg
    , label : String
    }


button : ButtonOptions msg -> Element msg
button opts =
    Input.button []
        { onPress = opts.onPress
        , label = text opts.label
        }


type alias TextInputOptions msg =
    { onChange : String -> msg
    , text : String
    , placeholder : Maybe String
    , label : Maybe String
    }


textInput : TextInputOptions msg -> Element msg
textInput opts =
    let
        placeholder =
            Maybe.map (\p -> Input.placeholder [] (Element.text p)) opts.placeholder
    in
    Input.text
        [ Border.widthEach { bottom = 1, top = 0, left = 0, right = 0 }
        , Element.spacing 10
        ]
        { onChange = opts.onChange
        , text = opts.text
        , placeholder = placeholder
        , label = inputLabel opts.label
        }


inputLabel : Maybe String -> Input.Label msg
inputLabel maybeText =
    let
        ( attrs, text ) =
            case maybeText of
                Nothing ->
                    ( [ Element.width (Element.px 0), Element.height (Element.px 0) ], "" )

                Just t ->
                    ( [ Element.alignBottom ], t )
    in
    Input.labelLeft attrs (Element.text text)
