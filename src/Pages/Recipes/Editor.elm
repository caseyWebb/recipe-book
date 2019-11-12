module Pages.Recipes.Editor exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Ingredient exposing (Ingredient, fetchIngredients, receiveIngredients)
import Data.Recipe exposing (Recipe, findRecipeById, newRecipe, receiveRecipe, recipeSaved, saveRecipe)
import Dict
import Element
import Process
import Regex
import Route
import Task
import UI
import UI.Autocomplete as Autocomplete


type alias Model =
    { navKey : Nav.Key
    , recipe : Recipe
    , loading : Bool
    , saving : Bool
    , isNew : Bool
    , saveError : Maybe String
    , allIngredients : List Ingredient
    , newIngredientAutocompleteModel : Autocomplete.Model Ingredient
    }


type Msg
    = FetchRecipe String
    | RecipeRecieved Recipe
    | FetchIngredients
    | ReceiveIngredients (List Ingredient)
    | SaveRecipe
    | RecipeSaved (Maybe String)
    | SelectNewIngredient Ingredient
    | DeleteIngredient String
    | UpdateName String
    | NewIngredientAutocompleteMsg (Autocomplete.Msg Ingredient)


init : Nav.Key -> Maybe String -> ( Model, Cmd Msg )
init navKey maybeId =
    let
        ( isNew, fetchRecipeMsg ) =
            case maybeId of
                Nothing ->
                    ( True, Nothing )

                Just id ->
                    ( False, Just (FetchRecipe id) )

        fetchIngredientsMsg =
            Just FetchIngredients

        initCmds =
            [ fetchRecipeMsg, fetchIngredientsMsg ]
                |> List.filterMap (Maybe.map (\msg -> Task.perform (\_ -> msg) <| Process.sleep 0))
                |> Cmd.batch

        initialModel : Model
        initialModel =
            { navKey = navKey
            , saving = False
            , loading = isNew
            , isNew = isNew
            , recipe = newRecipe
            , saveError = Nothing
            , allIngredients = []
            , newIngredientAutocompleteModel = newIngredientAutocomplete.init []
            }
    in
    ( initialModel, initCmds )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        availableIngredients : List Ingredient -> List Ingredient -> List Ingredient
        availableIngredients allIngredients addedIngredients =
            let
                toDict : List Ingredient -> Dict.Dict String Ingredient
                toDict data =
                    data
                        |> List.map (\i -> ( i.name, i ))
                        |> Dict.fromList
            in
            Dict.diff
                (toDict allIngredients)
                (toDict addedIngredients)
                |> Dict.values

        updateIngredients updatedRecipeIngredients =
            let
                updatedAvailableIngredients =
                    availableIngredients
                        model.allIngredients
                        updatedRecipeIngredients

                ( updatedNewIngredientAutocompleteModel, nextMsg ) =
                    newIngredientAutocomplete.resetData
                        newIngredientAutocompleteModel
                        updatedAvailableIngredients

                updatedModel =
                    { model
                        | recipe =
                            { recipe
                                | ingredients = updatedRecipeIngredients
                            }
                        , newIngredientAutocompleteModel =
                            updatedNewIngredientAutocompleteModel
                    }
            in
            update nextMsg updatedModel

        recipe =
            model.recipe

        newIngredientAutocompleteModel =
            model.newIngredientAutocompleteModel
    in
    case msg of
        FetchRecipe id ->
            ( model, findRecipeById id )

        RecipeRecieved updatedRecipe ->
            ( { model | recipe = updatedRecipe }, Cmd.none )

        FetchIngredients ->
            ( model, fetchIngredients () )

        ReceiveIngredients ingredients ->
            let
                ( updatedNewIngredientAutocompleteModel, nextMsg ) =
                    newIngredientAutocomplete.resetData
                        newIngredientAutocompleteModel
                        ingredients

                updatedModel =
                    { model
                        | allIngredients = ingredients
                        , newIngredientAutocompleteModel = updatedNewIngredientAutocompleteModel
                    }
            in
            update nextMsg updatedModel

        UpdateName name ->
            let
                updatedSlug =
                    if model.isNew then
                        slugify name

                    else
                        model.recipe.slug

                updatedRecipe =
                    { recipe | name = name, slug = updatedSlug }
            in
            ( { model | recipe = updatedRecipe }, Cmd.none )

        NewIngredientAutocompleteMsg autocompleteMsg ->
            let
                ( updatedAutocompleteModel, maybeMsg ) =
                    newIngredientAutocomplete.update
                        newIngredientAutocompleteModel
                        autocompleteMsg

                newModel =
                    { model | newIngredientAutocompleteModel = updatedAutocompleteModel }
            in
            case maybeMsg of
                Just nextMsg ->
                    update nextMsg newModel

                Nothing ->
                    ( newModel, Cmd.none )

        SelectNewIngredient ingredient ->
            let
                updatedRecipeIngredients =
                    ingredient :: recipe.ingredients
            in
            updateIngredients updatedRecipeIngredients

        DeleteIngredient ingredient ->
            let
                updatedRecipeIngredients =
                    recipe.ingredients |> List.filter (\i -> i.name /= ingredient)
            in
            updateIngredients updatedRecipeIngredients

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
    Sub.batch
        [ receiveRecipe <| \recipe -> RecipeRecieved recipe
        , receiveIngredients <| \ingredients -> ReceiveIngredients ingredients
        , recipeSaved <| \err -> RecipeSaved err
        , newIngredientAutocomplete.subscriptions
        ]


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
            UI.textInput []
                { onChange = \s -> UpdateName s
                , text = model.recipe.name
                , placeholder = Nothing
                , label = Just "Title"
                }

        ingredientList =
            model.recipe.ingredients
                |> List.map
                    (\i ->
                        Element.row []
                            [ Element.text i.name
                            , UI.button { onPress = Just <| DeleteIngredient i.name, label = "Delete" }
                            ]
                    )
                |> Element.column []

        newIngredientInput =
            newIngredientAutocomplete.view model.newIngredientAutocompleteModel

        saveButton =
            UI.button { onPress = Just SaveRecipe, label = "Save Recipe" }

        errMessage =
            case model.saveError of
                Nothing ->
                    Element.text ""

                Just err ->
                    Element.text err
    in
    Element.column []
        [ titleInput
        , ingredientList
        , newIngredientInput
        , saveButton
        , errMessage
        ]


newIngredientAutocomplete : Autocomplete.Autocomplete Msg Ingredient
newIngredientAutocomplete =
    Autocomplete.with
        { placeholder = Just "Add Ingredient"
        , msg = \msg -> NewIngredientAutocompleteMsg msg
        , onSelect = \ingredient -> SelectNewIngredient ingredient
        , mapData = .name
        }


slugifyRe : Regex.Regex
slugifyRe =
    Regex.fromString "[^a-zA-Z0-9]+"
        |> Maybe.withDefault Regex.never


slugify : String -> String
slugify =
    String.toLower >> Regex.replace slugifyRe (\_ -> "-")
