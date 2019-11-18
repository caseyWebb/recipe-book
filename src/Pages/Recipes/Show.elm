module Pages.Recipes.Show exposing (Model, Msg, init, subscriptions, update, view)

import Data.Ingredient exposing (Ingredient)
import Data.Recipe exposing (Recipe, findRecipeById, receiveRecipe)
import Element
import Element.Background as Background
import Element.Font as Font
import Process
import Route
import Task
import UI


type alias Model =
    { id : String
    , recipe : Maybe Recipe
    }


type Msg
    = Ready ()
    | RecipeRecieved Recipe


init : String -> ( Model, Cmd Msg )
init id =
    ( { id = id, recipe = Nothing }, Task.perform Ready <| Process.sleep 0 )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Ready _ ->
            ( model, findRecipeById model.id )

        RecipeRecieved recipe ->
            ( { model | recipe = Just recipe }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveRecipe RecipeRecieved


view : Model -> Element.Element Msg
view model =
    case model.recipe of
        Nothing ->
            Element.text "loading"

        Just recipe ->
            let
                titleHeader =
                    Element.el
                        [ Font.bold
                        , Font.size 36
                        , Element.paddingEach { top = 12, bottom = 63, left = 0, right = 0 }
                        ]
                    <|
                        Element.text recipe.name

                editRecipeButton =
                    Element.column []
                        [ Element.link
                            [ Background.color <| Element.rgb255 170 170 170
                            , Element.paddingXY 18 12
                            , Font.color UI.white
                            , Font.bold
                            , Font.size 14
                            ]
                            { url = Route.toString <| Route.EditRecipe model.id
                            , label = Element.text "Edit Recipe"
                            }
                        ]
            in
            Element.column
                [ Element.onRight editRecipeButton
                , Element.width Element.fill
                ]
                [ titleHeader
                , viewIngredients recipe.ingredients
                ]


viewIngredients : List Ingredient -> Element.Element Msg
viewIngredients ingredients =
    Element.column [ Element.spacing 10 ] <|
        [ Element.el
            [ Font.bold
            , Font.size 24
            , Element.paddingEach { top = 0, bottom = 10, right = 0, left = 0 }
            ]
          <|
            Element.text "Ingredients"
        ]
            ++ (ingredients
                    |> List.map
                        (\i ->
                            Element.el
                                [ Font.size 16
                                ]
                            <|
                                Element.text i.name
                        )
               )
