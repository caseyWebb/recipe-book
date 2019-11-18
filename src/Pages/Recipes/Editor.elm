module Pages.Recipes.Editor exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Ingredient exposing (Ingredient, fetchIngredients, receiveIngredients)
import Data.Recipe exposing (Recipe, findRecipeById, receiveRecipe, recipeSaved, saveRecipe)
import Dict exposing (Dict)
import Element
import Element.Font as Font
import Element.Input as Input
import Process
import Regex
import Route
import Task
import UI
import UI.Autocomplete as Autocomplete


type alias Model =
    { navKey : Nav.Key
    , loading : Bool
    , saving : Bool
    , isNew : Bool
    , saveError : Maybe String
    , name : String
    , allIngredients : Dict String Ingredient
    , recipeIngredients : Dict String Ingredient
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
            , saveError = Nothing
            , allIngredients = Dict.empty
            , name = ""
            , recipeIngredients = Dict.empty
            , newIngredientAutocompleteModel = newIngredientAutocomplete.init Dict.empty
            }
    in
    ( initialModel, initCmds )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchRecipe id ->
            ( model, findRecipeById id )

        RecipeRecieved updatedRecipe ->
            let
                updators : List Msg
                updators =
                    UpdateName updatedRecipe.name
                        :: List.map (\i -> SelectNewIngredient i) updatedRecipe.ingredients

                accumulator : Msg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
                accumulator =
                    \fieldMsg accum ->
                        let
                            ( currentModel, currentCmd ) =
                                accum

                            ( updatedModel, nextCmd ) =
                                update fieldMsg currentModel
                        in
                        ( updatedModel, Cmd.batch [ currentCmd, nextCmd ] )
            in
            List.foldl accumulator ( model, Cmd.none ) updators

        FetchIngredients ->
            ( model, fetchIngredients () )

        ReceiveIngredients ingredients ->
            ingredients
                |> List.map (\i -> ( i.name, i ))
                |> Dict.fromList
                |> updateAllIngredients model

        UpdateName name ->
            updateName model name

        NewIngredientAutocompleteMsg autocompleteMsg ->
            let
                ( updatedAutocompleteModel, maybeMsg ) =
                    newIngredientAutocomplete.update
                        model.newIngredientAutocompleteModel
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
                    Dict.insert ingredient.name ingredient model.recipeIngredients
            in
            updateRecipeIngredients model updatedRecipeIngredients

        DeleteIngredient ingredient ->
            let
                updatedRecipeIngredients =
                    Dict.remove ingredient model.recipeIngredients
            in
            updateRecipeIngredients model updatedRecipeIngredients

        SaveRecipe ->
            let
                recipe : Recipe
                recipe =
                    { name = model.name
                    , slug = slugify model.name
                    , ingredients = Dict.values model.recipeIngredients
                    }
            in
            ( { model | saving = True }, saveRecipe recipe )

        RecipeSaved maybeErr ->
            case maybeErr of
                Just _ ->
                    ( { model | saving = False, saveError = maybeErr }, Cmd.none )

                Nothing ->
                    ( { model | saving = False }, Route.pushUrl Route.Recipes model.navKey )


updateName : Model -> String -> ( Model, Cmd Msg )
updateName model updatedName =
    ( { model | name = updatedName }, Cmd.none )


updateAllIngredients : Model -> Dict String Ingredient -> ( Model, Cmd Msg )
updateAllIngredients model updatedAllIngredients =
    updateNewIngredientAutocomplete { model | allIngredients = updatedAllIngredients }


updateRecipeIngredients : Model -> Dict String Ingredient -> ( Model, Cmd Msg )
updateRecipeIngredients model updatedRecipeIngredients =
    updateNewIngredientAutocomplete { model | recipeIngredients = updatedRecipeIngredients }


updateNewIngredientAutocomplete : Model -> ( Model, Cmd Msg )
updateNewIngredientAutocomplete model =
    let
        updatedAvailableIngredients =
            Dict.diff
                model.allIngredients
                model.recipeIngredients

        ( updatedNewIngredientAutocompleteModel, nextMsg ) =
            newIngredientAutocomplete.resetData
                model.newIngredientAutocompleteModel
                updatedAvailableIngredients

        updatedModel =
            { model | newIngredientAutocompleteModel = updatedNewIngredientAutocompleteModel }
    in
    update nextMsg updatedModel


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
        [ viewForm model
        ]


viewForm : Model -> Element.Element Msg
viewForm model =
    let
        titleInput =
            UI.textInput
                [ Font.size 36
                , Font.bold
                , Element.paddingXY 0 12
                , Element.spacing 0
                ]
                { onChange = \s -> UpdateName s
                , text = model.name
                , placeholder = Just "New Recipe"
                , label = Nothing
                }

        saveButton =
            UI.button { onPress = Just SaveRecipe, label = "Save Recipe" }

        errMessage =
            case model.saveError of
                Nothing ->
                    Element.text ""

                Just err ->
                    Element.text err
    in
    Element.column
        [ Element.spacingXY 0 50
        ]
        [ titleInput
        , viewIngredients model
        , saveButton
        , errMessage
        ]


viewIngredients : Model -> Element.Element Msg
viewIngredients model =
    let
        ingredients =
            Dict.values model.recipeIngredients

        ingredientsHeader =
            Element.el
                [ Font.size 24
                , Font.bold
                ]
                (Element.text "Ingredients")

        ingredientList =
            ingredients
                |> List.map
                    (\i ->
                        Element.row
                            [ Element.width Element.fill
                            , Font.size 16
                            , Element.onLeft <|
                                Input.button
                                    [ Element.alignRight
                                    , Element.paddingEach { left = 0, right = 10, top = 0, bottom = 0 }
                                    ]
                                    { onPress = Just <| DeleteIngredient i.name
                                    , label = Element.el [ Font.bold ] (Element.text "")
                                    }
                            ]
                            [ Element.text i.name
                            ]
                    )
                |> Element.column [ Element.width Element.fill, Element.spacing 10 ]

        newIngredientInput =
            newIngredientAutocomplete.view model.newIngredientAutocompleteModel
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 20
        ]
        [ ingredientsHeader
        , Element.column []
            [ ingredientList
            , newIngredientInput
            ]
        ]


newIngredientAutocomplete : Autocomplete.Autocomplete Msg Ingredient
newIngredientAutocomplete =
    Autocomplete.with
        { placeholder = Just "Add Ingredient"
        , msg = \msg -> NewIngredientAutocompleteMsg msg
        , onSelect = \ingredient -> SelectNewIngredient ingredient
        , createNew = \i -> { name = i, section = "Unknown", quantity = 1, unit = "" }
        }


slugifyRe : Regex.Regex
slugifyRe =
    Regex.fromString "[^a-zA-Z0-9]+"
        |> Maybe.withDefault Regex.never


slugify : String -> String
slugify =
    String.toLower >> Regex.replace slugifyRe (\_ -> "-")
