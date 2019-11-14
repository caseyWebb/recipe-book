module Pages.Recipes.List exposing (Model, Msg, init, subscriptions, update, view)

import Data.Recipe exposing (Recipe, RecipeList, fetchRecipes, receiveRecipes)
import Element
import Process
import Route
import Task


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
    case model of
        Nothing ->
            Element.text "Loading"

        Just data ->
            viewRecipes data


viewRecipes : RecipeList -> Element.Element Msg
viewRecipes recipes =
    Element.column [ Element.spacing 20 ] <| List.map viewRecipe recipes.recipes


viewRecipe : Recipe -> Element.Element Msg
viewRecipe recipe =
    let
        recipePath =
            Route.toString (Route.Recipe recipe.slug)
    in
    Element.link [] { url = recipePath, label = Element.text recipe.name }
