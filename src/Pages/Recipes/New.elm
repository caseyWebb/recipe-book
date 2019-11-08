module Pages.Recipes.New exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Recipe exposing (Recipe, createRecipe, recipeSaved, saveRecipe)
import Element
import Html exposing (..)
import Html.Attributes exposing (..)
import Route exposing (..)
import Selectize
import UI


type alias Model =
    { navKey : Nav.Key
    , recipe : Recipe
    , saving : Bool
    , saveError : Maybe String
    , newIngredientSelection : Maybe String
    , newIngredientMenu : Selectize.State String
    }


type Msg
    = SaveRecipe
    | RecipeSaved (Maybe String)
    | NewIngredientMenuMsg (Selectize.Msg String)
    | SelectNewIngredient (Maybe String)
    | UpdateName String


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    let
        initialModel =
            { navKey = navKey
            , saving = False
            , recipe = createRecipe
            , saveError = Nothing
            , newIngredientSelection = Nothing
            , newIngredientMenu =
                Selectize.closed
                    "ingredient-menu"
                    identity
                    (ingredients |> List.map Selectize.entry)
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

        NewIngredientMenuMsg selectizeMsg ->
            let
                ( newMenu, menuCmd, maybeMsg ) =
                    Selectize.update SelectNewIngredient
                        model.newIngredientSelection
                        model.newIngredientMenu
                        selectizeMsg

                newModel =
                    { model | newIngredientMenu = newMenu }

                cmd =
                    menuCmd |> Cmd.map NewIngredientMenuMsg
            in
            case maybeMsg of
                Just nextMsg ->
                    update nextMsg newModel
                        |> andDo cmd

                Nothing ->
                    ( newModel, cmd )

        SelectNewIngredient ingredient ->
            ( { model | newIngredientSelection = ingredient }, Cmd.none )

        SaveRecipe ->
            ( { model | saving = True }, saveRecipe model.recipe )

        RecipeSaved maybeErr ->
            case maybeErr of
                Just _ ->
                    ( { model | saving = False, saveError = maybeErr }, Cmd.none )

                Nothing ->
                    ( { model | saving = False }, Route.pushUrl Route.Recipes model.navKey )


andDo : Cmd msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
andDo cmd ( model, cmds ) =
    ( model
    , Cmd.batch [ cmd, cmds ]
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    recipeSaved <| \err -> RecipeSaved err


view : Model -> Element.Element Msg
view model =
    Element.column
        []
        [ UI.header "New Recipe"
        , recipeForm model
        ]


recipeForm : Model -> Element.Element Msg
recipeForm model =
    let
        titleInput =
            UI.textInput
                { onChange = \s -> UpdateName s
                , text = model.recipe.name
                , placeholder = Nothing
                , label = "Title"
                }

        newIngredientInput =
            UI.autocompleteInput
                { placeholder = "Add Ingredient"
                , selection = model.newIngredientSelection
                , menu = model.newIngredientMenu
                , msg = NewIngredientMenuMsg
                }

        saveButton =
            UI.button { onPress = Just SaveRecipe, label = "Save Recipe" }
    in
    Element.column []
        [ titleInput
        , newIngredientInput
        , saveButton
        ]


ingredients : List String
ingredients =
    [ "Garlic", "Onion", "Canned Tomatoes", "Olive Oil", "Spaghetti" ]
