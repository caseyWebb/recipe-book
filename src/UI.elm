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
    , placeholder : Maybe (Input.Placeholder msg)
    , label : String
    }


textInput : TextInputOptions msg -> Element msg
textInput opts =
    Input.text
        [ Border.widthEach { bottom = 1, top = 0, left = 0, right = 0 }
        , Element.spacing 10
        ]
        { onChange = opts.onChange
        , text = opts.text
        , placeholder = opts.placeholder
        , label = inputLabel opts.label
        }


inputLabel : String -> Input.Label msg
inputLabel text =
    Input.labelLeft [ Element.alignBottom ] (Element.text text)
