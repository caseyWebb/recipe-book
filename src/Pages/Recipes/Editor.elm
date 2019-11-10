module Pages.Recipes.Editor exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Ingredient exposing (Ingredient, fetchIngredients, receiveIngredients)
import Data.Recipe exposing (Recipe, findRecipeById, newRecipe, receiveRecipe, recipeSaved, saveRecipe)
import Element
import Html exposing (..)
import Html.Attributes exposing (..)
import Process
import Regex
import Route exposing (..)
import Selectize
import Task
import UI


type alias Model =
    { navKey : Nav.Key
    , recipe : Recipe
    , loading : Bool
    , saving : Bool
    , isNew : Bool
    , saveError : Maybe String
    , newIngredientSelection : Maybe String
    , newIngredientMenu : Selectize.State String
    }


type Msg
    = FetchRecipe String
    | RecipeRecieved Recipe
    | FetchIngredients
    | ReceiveIngredients (List String)
    | SaveRecipe
    | RecipeSaved (Maybe String)
    | NewIngredientMenuMsg (Selectize.Msg String)
    | SelectNewIngredient (Maybe String)
    | UpdateName String


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

        initialModel =
            { navKey = navKey
            , saving = False
            , loading = isNew
            , isNew = isNew
            , recipe = newRecipe
            , saveError = Nothing
            , newIngredientSelection = Nothing
            , newIngredientMenu = createIngredientMenu []
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
                updatedIngredientMenu =
                    createIngredientMenu ingredients
            in
            ( { model | newIngredientMenu = updatedIngredientMenu }, Cmd.none )

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
            UI.autocompleteInput
                { placeholder = "Add Ingredient"
                , selection = model.newIngredientSelection
                , menu = model.newIngredientMenu
                , msg = NewIngredientMenuMsg
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
    Element.column []
        [ titleInput
        , newIngredientInput
        , saveButton
        , errMessage
        ]


slugifyRe : Regex.Regex
slugifyRe =
    Regex.fromString "[^a-zA-Z0-9]+"
        |> Maybe.withDefault Regex.never


slugify : String -> String
slugify =
    String.toLower >> Regex.replace slugifyRe (\_ -> "-")


createIngredientMenu : List String -> Selectize.State String
createIngredientMenu ingredients =
    Selectize.closed
        "ingredient-menu"
        identity
        (ingredients |> List.map Selectize.entry)
