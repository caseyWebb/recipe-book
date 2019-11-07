module UI exposing (TextInputOptions, header, textInput)

import Element exposing (Element, el, text)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


header : String -> Element msg
header t =
    el
        [ Font.size 24
        , Font.bold
        ]
    <|
        text t


type alias TextInputOptions msg =
    { onChange : String -> msg
    , text : String
    , placeholder : Maybe (Input.Placeholder msg)
    , label : Input.Label msg
    }


textInput : TextInputOptions msg -> Element msg
textInput =
    Input.text
        [ Border.widthEach { bottom = 1, top = 0, left = 0, right = 0 }
        ]
