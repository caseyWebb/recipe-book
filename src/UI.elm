module UI exposing (TextInputOptions, button, header, link, render, textInput)

import Element exposing (Element, el, text)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Route


render : Element msg -> Html.Html msg
render el =
    let
        rightMenu =
            Element.column []
                [ Element.link []
                    { url = Route.toString Route.NewRecipe
                    , label = Element.text "Add New Recipe"
                    }
                ]
    in
    Element.layout
        [ Font.family
            [ Font.typeface "Source Sans Pro"
            , Font.typeface "Helvetica Neue"
            , Font.sansSerif
            ]
        , Font.color <| Element.rgb255 196 196 196
        , Background.color <| Element.rgb 0 0 0
        , Element.paddingXY 0 50
        ]
    <|
        Element.el
            [ Element.width <| (Element.fill |> Element.maximum 800)
            , Element.centerX
            , Element.onRight rightMenu
            ]
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


textInput : List (Element.Attribute msg) -> TextInputOptions msg -> Element msg
textInput attrs opts =
    let
        placeholder =
            Maybe.map (\p -> Input.placeholder [] (Element.text p)) opts.placeholder
    in
    Input.text
        (List.concat
            [ [ Border.widthEach { bottom = 1, top = 0, left = 0, right = 0 }
              , Element.spacing 10
              , Element.focused
                    [ Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = Element.rgb 0 0 0 }
                    ]
              ]
            , attrs
            ]
        )
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
