module Pages.Recipes.New exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Recipe exposing (Recipe, createRecipe, recipeSaved, saveRecipe)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Route exposing (..)


type alias Model =
    { navKey : Nav.Key
    , recipe : Recipe
    , saving : Bool
    , saveError : Maybe String
    }


type Msg
    = SaveRecipe
    | RecipeSaved (Maybe String)
    | UpdateName String


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    let
        initialModel =
            { navKey = navKey
            , saving = False
            , recipe = createRecipe
            , saveError = Nothing
            }
    in
    ( initialModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateName name ->
            let
                recipe =
                    model.recipe

                updatedRecipe =
                    { recipe | name = name }
            in
            ( { model | recipe = updatedRecipe }, Cmd.none )

        SaveRecipe ->
            ( { model | saving = True }, saveRecipe model.recipe )

        RecipeSaved maybeErr ->
            case maybeErr of
                Just _ ->
                    ( { model | saving = False, saveError = maybeErr }, Cmd.none )

                Nothing ->
                    ( { model | saving = False }, Route.pushUrl Route.Recipes model.navKey )


subscriptions : Model -> Sub Msg
subscriptions _ =
    recipeSaved <| \err -> RecipeSaved err


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "New Recipe" ]
        , recipeForm
        ]


recipeForm : Html Msg
recipeForm =
    Html.form []
        [ div []
            [ text "Name"
            , br [] []
            , input [ type_ "text", onInput UpdateName ] []
            ]
        , br [] []
        , div []
            [ button [ type_ "button", onClick SaveRecipe ] [ text "Submit" ] ]
        ]
