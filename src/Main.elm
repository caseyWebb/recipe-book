module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Pages.Recipes.List as ListRecipes
import Pages.Recipes.New as NewRecipe
import Route exposing (Route)
import Url exposing (Url)


type alias Model =
    { route : Route
    , page : Page
    , navKey : Nav.Key
    }


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | ListRecipesMsg ListRecipes.Msg
    | NewRecipeMsg NewRecipe.Msg


type Page
    = NotFoundPage
    | RecipeList ListRecipes.Model
    | NewRecipe NewRecipe.Model


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    let
        model =
            { route = Route.parseUrl url
            , page = NotFoundPage
            , navKey = navKey
            }
    in
    initCurrentPage ( model, Cmd.none )


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Recipes ->
                    let
                        ( pageModel, pageCmds ) =
                            ListRecipes.init
                    in
                    ( RecipeList pageModel, Cmd.map ListRecipesMsg pageCmds )

                Route.NewRecipe ->
                    let
                        ( pageModel, pageCmds ) =
                            NewRecipe.init model.navKey
                    in
                    ( NewRecipe pageModel, Cmd.map NewRecipeMsg pageCmds )
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


view : Model -> Document Msg
view model =
    { title = "Recipe Book"
    , body = [ currentView model ]
    }


currentView : Model -> Html Msg
currentView model =
    case model.page of
        NotFoundPage ->
            notFoundView

        RecipeList recipeListModel ->
            ListRecipes.view recipeListModel |> Html.map ListRecipesMsg

        NewRecipe newRecipeModel ->
            NewRecipe.view newRecipeModel |> Html.map NewRecipeMsg


notFoundView : Html msg
notFoundView =
    h3 [] [ text "404" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none ) |> initCurrentPage

        ( ListRecipesMsg subMsg, RecipeList pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ListRecipes.update subMsg pageModel
            in
            ( { model | page = RecipeList updatedPageModel }
            , Cmd.map ListRecipesMsg updatedCmd
            )

        ( NewRecipeMsg subMsg, NewRecipe pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    NewRecipe.update subMsg pageModel
            in
            ( { model | page = NewRecipe updatedPageModel }, Cmd.map NewRecipeMsg updatedCmd )

        ( _, _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        RecipeList recipeListModel ->
            ListRecipes.subscriptions recipeListModel |> Sub.map ListRecipesMsg

        NewRecipe newRecipeModel ->
            NewRecipe.subscriptions newRecipeModel |> Sub.map NewRecipeMsg

        _ ->
            Sub.none
