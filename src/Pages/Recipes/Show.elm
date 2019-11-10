module Pages.Recipes.Show exposing (Model, Msg, init, subscriptions, update, view)

import Data.Ingredient exposing (Ingredient)
import Data.Recipe exposing (Recipe, findRecipeById, receiveRecipe)
import Element
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
            Element.column []
                [ Element.row []
                    [ Element.text recipe.name
                    , UI.link "Edit" (Route.EditRecipe model.id)
                    ]
                , viewIngredients recipe.ingredients
                ]


viewIngredients : List Ingredient -> Element.Element Msg
viewIngredients ingredients =
    Element.column []
        (ingredients
            |> List.map (\i -> Element.el [] <| Element.text i.name)
        )
