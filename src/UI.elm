module UI exposing (TextInputOptions, autocompleteInput, button, header, link, render, textInput)

import Element exposing (Element, el, text)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Route
import Selectize


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
    { onPress : Maybe msg, label : String }


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


type alias AutocompleteInputOptions msg =
    { placeholder : String
    , selection : Maybe String
    , menu : Selectize.State String
    , msg : Selectize.Msg String -> msg
    }


autocompleteInput : AutocompleteInputOptions msg -> Element.Element msg
autocompleteInput options =
    Selectize.view (autocompleteConfig options.placeholder) options.selection options.menu
        |> Html.map options.msg
        |> Element.html


autocompleteConfig : String -> Selectize.ViewConfig String
autocompleteConfig placeholder =
    let
        viewConfig selector =
            Selectize.viewConfig
                { container = [ Html.Attributes.class "selectize-container" ]
                , menu =
                    [ Html.Attributes.class "selectize-menu" ]
                , ul =
                    []
                , entry =
                    \tree mouseFocused keyboardFocused ->
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
                            [ Html.text tree ]
                        }
                , divider =
                    \title ->
                        { attributes =
                            [ Html.Attributes.class "divider" ]
                        , children =
                            [ Html.text title ]
                        }
                , input = selector
                }

        textFieldStyles =
            \hasSelection open ->
                [ Html.Attributes.class "selectize-input"
                , Html.Attributes.classList
                    [ ( "has-selection", hasSelection )
                    , ( "no-selection", not hasSelection )
                    , ( "open", open )
                    ]
                ]

        textfieldSelector =
            Selectize.autocomplete <|
                { attrs = textFieldStyles
                , toggleButton = Nothing
                , clearButton = Nothing
                , placeholder = placeholder
                }
    in
    viewConfig textfieldSelector
