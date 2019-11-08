module Pages.Recipes.List exposing (Model, Msg, init, subscriptions, update, view)

import Data.Recipe exposing (Recipe, RecipeList, fetchRecipes, receiveRecipes)
import Element


type alias Model =
    RecipeList


type Msg
    = RecipesRecieved RecipeList


init : ( Model, Cmd Msg )
init =
    ( { count = 0, recipes = [] }, fetchRecipes () )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        RecipesRecieved response ->
            ( response, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveRecipes RecipesRecieved


view : Model -> Element.Element Msg
view model =
    Element.column []
        [ Element.link [] { url = "/recipes/new", label = Element.text "New Recipe" }
        , viewRecipes model
        ]


viewRecipes : RecipeList -> Element.Element Msg
viewRecipes recipes =
    Element.table []
        { data = recipes.recipes
        , columns =
            [ { header = Element.text "Title", width = Element.fill, view = viewRecipe }
            ]
        }


viewRecipe : Recipe -> Element.Element Msg
viewRecipe recipe =
    let
        recipePath =
            case recipe.id of
                Just id ->
                    "/recipes/" ++ id

                Nothing ->
                    "#"
    in
    Element.link [] { url = recipePath, label = Element.text recipe.name }
