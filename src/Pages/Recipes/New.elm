module Pages.Recipes.New exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Data.Recipe exposing (Recipe, createRecipe, recipeSaved, saveRecipe)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Route exposing (..)
import Selectize


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


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "New Recipe" ]
        , recipeForm model
        ]


recipeForm : Model -> Html Msg
recipeForm model =
    Html.form [ onSubmit SaveRecipe ]
        [ div []
            [ text "Name"
            , br [] []
            , input [ type_ "text", onInput UpdateName ] []
            ]
        , br [] []
        , div []
            [ Selectize.view
                newIngredientViewConfig
                model.newIngredientSelection
                model.newIngredientMenu
                |> Html.map NewIngredientMenuMsg
            ]
        , div []
            [ button [ type_ "submit" ] [ text "Submit" ] ]
        ]


newIngredientViewConfig : Selectize.ViewConfig String
newIngredientViewConfig =
    let
        viewConfig selector =
            Selectize.viewConfig
                { container = []
                , menu =
                    [ class "selectize__menu" ]
                , ul =
                    [ class "selectize__list" ]
                , entry =
                    \tree mouseFocused keyboardFocused ->
                        { attributes =
                            [ class "selectize__item"
                            , classList
                                [ ( "selectize__item--mouse-selected"
                                  , mouseFocused
                                  )
                                , ( "selectize__item--key-selected"
                                  , keyboardFocused
                                  )
                                ]
                            ]
                        , children =
                            [ Html.text tree ]
                        }
                , divider =
                    \title ->
                        { attributes =
                            [ class "selectize__divider" ]
                        , children =
                            [ Html.text title ]
                        }
                , input = selector
                }

        textfieldSelector =
            Selectize.autocomplete <|
                { attrs =
                    \sthSelected open ->
                        [ class "selectize__textfield"
                        , classList
                            [ ( "selectize__textfield--selection", sthSelected )
                            , ( "selectize__textfield--no-selection", not sthSelected )
                            , ( "selectize__textfield--menu-open", open )
                            ]
                        ]
                , toggleButton = Nothing
                , clearButton = Nothing
                , placeholder = "Add New Ingredient"
                }
    in
    viewConfig textfieldSelector


ingredients : List String
ingredients =
    [ "Garlic", "Onion", "Canned Tomatoes", "Olive Oil", "Spaghetti" ]
