module Pages.Recipes.Editor exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Ingredient exposing (fetchIngredients, newIngredient, receiveIngredients)
import Data.Recipe exposing (Recipe, findRecipeById, newRecipe, receiveRecipe, recipeSaved, saveRecipe)
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
    , newIngredientAutocomplete :
        { state : Autocomplete.State
        , data : List String
        }
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
        ( isNew, cmd ) =
            case maybeId of
                Nothing ->
                    ( True, Cmd.none )

                Just id ->
                    let
                        initCmds =
                            initMsgs id
                                |> List.map (\msg -> Task.perform (\_ -> msg) <| Process.sleep 0)
                    in
                    ( False, Cmd.batch initCmds )

        initialModel : Model
        initialModel =
            { navKey = navKey
            , saving = False
            , loading = isNew
            , isNew = isNew
            , recipe = newRecipe
            , saveError = Nothing
            , newIngredientAutocomplete = { state = Autocomplete.init, data = [] }
            }
    in
    ( initialModel, cmd )


initMsgs : String -> List Msg
initMsgs id =
    [ FetchRecipe id
    , FetchIngredients
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchRecipe id ->
            ( model, findRecipeById id )

        RecipeRecieved recipe ->
            ( { model | recipe = recipe }, Cmd.none )

        FetchIngredients ->
            ( model, fetchIngredients () )

        ReceiveIngredients ingredients ->
            let
                newIngredientAutocomplete =
                    model.newIngredientAutocomplete

                updatedNewIngredientAutocomplete =
                    { newIngredientAutocomplete | data = ingredients }

                updatedModel =
                    { model | newIngredientAutocomplete = updatedNewIngredientAutocomplete }
            in
            ( updatedModel, Cmd.none )

        UpdateName name ->
            let
                recipe =
                    model.recipe

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
                ( newState, maybeMsg ) =
                    Autocomplete.update (newIngredientAutocompleteOptions model) autocompleteMsg

                currentNewIngredientAutocomplete =
                    model.newIngredientAutocomplete

                updatedNewIngredientAutocomplete =
                    { currentNewIngredientAutocomplete | state = newState }

                newModel =
                    { model | newIngredientAutocomplete = updatedNewIngredientAutocomplete }
            in
            case maybeMsg of
                Just nextMsg ->
                    update nextMsg newModel

                Nothing ->
                    ( newModel, Cmd.none )

        SelectNewIngredient ingredient ->
            let
                recipe =
                    model.recipe

                updatedRecipe =
                    { recipe | ingredients = newIngredient ingredient :: recipe.ingredients }
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
    Sub.batch
        [ receiveRecipe <| \recipe -> RecipeRecieved recipe
        , receiveIngredients <| \ingredients -> ReceiveIngredients ingredients
        , recipeSaved <| \err -> RecipeSaved err
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
            UI.textInput
                { onChange = \s -> UpdateName s
                , text = model.recipe.name
                , placeholder = Nothing
                , label = "Title"
                }

        newIngredientInput =
            Autocomplete.view (newIngredientAutocompleteOptions model)

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
        , newIngredientInput
        , saveButton
        , errMessage
        ]


newIngredientAutocompleteOptions : Model -> Autocomplete.Options Msg
newIngredientAutocompleteOptions model =
    { placeholder = "Add Ingredient"
    , state = model.newIngredientAutocomplete.state
    , msg = \msg -> NewIngredientAutocompleteMsg msg
    , data = model.newIngredientAutocomplete.data
    , onSelect = \ingredient -> SelectNewIngredient ingredient
    }


slugifyRe : Regex.Regex
slugifyRe =
    Regex.fromString "[^a-zA-Z0-9]+"
        |> Maybe.withDefault Regex.never


slugify : String -> String
slugify =
    String.toLower >> Regex.replace slugifyRe (\_ -> "-")
