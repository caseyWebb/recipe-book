module Pages.Recipes.Editor exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Ingredient exposing (Ingredient, fetchIngredients, newIngredient, receiveIngredients)
import Data.Recipe exposing (Recipe, findRecipeById, newRecipe, receiveRecipe, recipeSaved, saveRecipe)
import Element
import Process
import Regex
import Route
import Set
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
    , allIngredients : List String
    , availableIngredients : List String
    , newIngredientAutocomplete : Autocomplete.Model
    }


type Msg
    = FetchRecipe String
    | RecipeRecieved Recipe
    | FetchIngredients
    | ReceiveIngredients (List String)
    | SaveRecipe
    | RecipeSaved (Maybe String)
    | SelectNewIngredient String
    | UpdateName String
    | NewIngredientAutocompleteMsg Autocomplete.Msg


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
            , availableIngredients = []
            , newIngredientAutocomplete = Autocomplete.init []
            }
    in
    ( initialModel, initCmds )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        availableIngredients : List String -> List Ingredient -> List String
        availableIngredients allIngredients addedIngredients =
            Set.diff
                (Set.fromList allIngredients)
                (Set.fromList (List.map .name addedIngredients))
                |> Set.toList

        recipe =
            model.recipe

        newIngredientAutocomplete =
            model.newIngredientAutocomplete
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
                updatedNewIngredientAutocomplete =
                    { newIngredientAutocomplete | data = ingredients }

                nextMsg =
                    Autocomplete.reset
                        (newIngredientAutocompleteOptions model)
                        updatedNewIngredientAutocomplete

                updatedModel =
                    { model | newIngredientAutocomplete = updatedNewIngredientAutocomplete }
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
                ( updatedAutocomplete, maybeMsg ) =
                    Autocomplete.update
                        (newIngredientAutocompleteOptions model)
                        newIngredientAutocomplete
                        autocompleteMsg

                newModel =
                    { model | newIngredientAutocomplete = updatedAutocomplete }
            in
            case maybeMsg of
                Just nextMsg ->
                    update nextMsg newModel

                Nothing ->
                    ( newModel, Cmd.none )

        SelectNewIngredient ingredient ->
            let
                updatedRecipeIngredients =
                    newIngredient ingredient :: recipe.ingredients

                updatedAvailableIngredients =
                    availableIngredients
                        model.allIngredients
                        updatedRecipeIngredients

                updatedRecipe =
                    { recipe | ingredients = updatedRecipeIngredients }

                updatedAutocompleteModel =
                    { newIngredientAutocomplete | data = updatedAvailableIngredients }

                updatedModel =
                    { model
                        | recipe = updatedRecipe
                        , newIngredientAutocomplete = updatedAutocompleteModel
                    }

                nextMsg =
                    Autocomplete.reset
                        (newIngredientAutocompleteOptions model)
                        updatedAutocompleteModel
            in
            update nextMsg updatedModel

        SaveRecipe ->
            ( { model | saving = True }, saveRecipe model.recipe )

        RecipeSaved maybeErr ->
            case maybeErr of
                Just _ ->
                    ( { model | saving = False, saveError = maybeErr }, Cmd.none )

                Nothing ->
                    ( { model | saving = False }, Route.pushUrl Route.Recipes model.navKey )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveRecipe <| \recipe -> RecipeRecieved recipe
        , receiveIngredients <| \ingredients -> ReceiveIngredients ingredients
        , recipeSaved <| \err -> RecipeSaved err
        , Autocomplete.subscriptions (newIngredientAutocompleteOptions model)
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
                |> List.map (\i -> Element.el [] (Element.text i.name))
                |> Element.column []

        newIngredientInput =
            Autocomplete.view (newIngredientAutocompleteOptions model) model.newIngredientAutocomplete

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


newIngredientAutocompleteOptions : Model -> Autocomplete.Options Msg
newIngredientAutocompleteOptions model =
    { placeholder = Just "Add Ingredient"
    , msg = \msg -> NewIngredientAutocompleteMsg msg
    , onSelect = \ingredient -> SelectNewIngredient ingredient
    }


slugifyRe : Regex.Regex
slugifyRe =
    Regex.fromString "[^a-zA-Z0-9]+"
        |> Maybe.withDefault Regex.never


slugify : String -> String
slugify =
    String.toLower >> Regex.replace slugifyRe (\_ -> "-")
