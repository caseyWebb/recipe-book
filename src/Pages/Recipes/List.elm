module Pages.Recipes.List exposing (Model, Msg, init, subscriptions, update, view)

import Data.Recipe exposing (Recipe, RecipeList, fetchRecipes, receiveRecipes)
import Element
import Element.Background as Background
import Element.Font as Font
import Process
import Route
import Task
import UI


type alias Model =
    Maybe RecipeList


type Msg
    = Ready ()
    | RecipesRecieved RecipeList


init : ( Model, Cmd Msg )
init =
    ( Nothing, Task.perform Ready <| Process.sleep 0 )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Ready _ ->
            ( model, fetchRecipes () )

        RecipesRecieved response ->
            ( Just response, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveRecipes RecipesRecieved


view : Model -> Element.Element Msg
view model =
    let
        addNewRecipeButton =
            Element.column []
                [ Element.link
                    [ Background.color UI.green
                    , Element.paddingXY 18 12
                    , Font.color UI.white
                    , Font.bold
                    , Font.size 14
                    ]
                    { url = Route.toString Route.NewRecipe
                    , label = Element.text "Add New Recipe"
                    }
                ]
    in
    case model of
        Nothing ->
            Element.text "Loading"

        Just data ->
            Element.el
                [ Element.width Element.fill
                , Element.onRight addNewRecipeButton
                ]
            <|
                viewRecipes data


viewRecipes : RecipeList -> Element.Element Msg
viewRecipes recipes =
    Element.column [ Element.spacing 20 ] <| List.map viewRecipe recipes.recipes


viewRecipe : Recipe -> Element.Element Msg
viewRecipe recipe =
    let
        recipePath =
            Route.toString (Route.Recipe recipe.slug)

        viewStarRecipe =
            Element.el
                [ Element.paddingXY 10 0
                ]
            <|
                Element.text "☆"
    in
    Element.el
        [ Element.onLeft <| viewStarRecipe
        , Font.bold
        , Font.color <| Element.rgb 1 1 1
        , Element.mouseOver [ Font.color <| Element.rgb 0 0 0 ]
        ]
    <|
        Element.link
            [ Font.color <| Element.rgb 0 0 0
            , Element.onLeft viewStarRecipe
            ]
            { url = recipePath, label = Element.text recipe.name }
