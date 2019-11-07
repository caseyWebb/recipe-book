module Pages.Recipes.List exposing (Model, Msg, init, subscriptions, update, view)

import Data.Recipe exposing (Recipe, RecipeList, fetchRecipes, receiveRecipes)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type alias Model =
    RecipeList


type Msg
    = FetchRecipes
    | RecipesRecieved RecipeList


init : ( Model, Cmd Msg )
init =
    ( { count = 0, recipes = [] }, fetchRecipes () )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchRecipes ->
            ( model, fetchRecipes () )

        RecipesRecieved response ->
            ( response, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick FetchRecipes ] [ text "Refresh Recipes" ]
        , br [] []
        , br [] []
        , a [ href "/recipes/new" ]
            [ text "New Recipe" ]
        , viewRecipes model
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveRecipes RecipesRecieved


viewRecipes : RecipeList -> Html Msg
viewRecipes recipes =
    div []
        [ h3 [] [ text "Recipes" ]
        , table []
            (viewTableHeader :: List.map viewRecipe recipes.recipes)
        ]


viewTableHeader : Html Msg
viewTableHeader =
    tr []
        [ th []
            [ text "Title" ]
        ]


viewRecipe : Recipe -> Html Msg
viewRecipe recipe =
    let
        recipePath =
            case recipe.id of
                Just id ->
                    "/recipes/" ++ id

                Nothing ->
                    "#"
    in
    tr []
        [ td []
            [ text recipe.name ]
        , td []
            [ a [ href recipePath ] [ text "Edit" ] ]
        ]
