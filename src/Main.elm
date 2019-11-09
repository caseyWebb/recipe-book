module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Element
import Pages.Recipes.Editor as EditRecipe
import Pages.Recipes.List as ListRecipes
import Pages.Recipes.Show as ShowRecipe
import Route exposing (Route)
import UI
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
    | EditRecipeMsg EditRecipe.Msg
    | ShowRecipeMsg ShowRecipe.Msg


type Page
    = NotFoundPage
    | ListRecipes ListRecipes.Model
    | EditRecipe EditRecipe.Model
    | ShowRecipe ShowRecipe.Model


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

                Route.Recipe recipeId ->
                    let
                        ( pageModel, pageCmds ) =
                            ShowRecipe.init recipeId
                    in
                    ( ShowRecipe pageModel, Cmd.map ShowRecipeMsg pageCmds )

                Route.Recipes ->
                    let
                        ( pageModel, pageCmds ) =
                            ListRecipes.init
                    in
                    ( ListRecipes pageModel, Cmd.map ListRecipesMsg pageCmds )

                Route.NewRecipe ->
                    let
                        ( pageModel, pageCmds ) =
                            EditRecipe.init model.navKey Nothing
                    in
                    ( EditRecipe pageModel, Cmd.map EditRecipeMsg pageCmds )

                Route.EditRecipe recipeId ->
                    let
                        ( pageModel, pageCmds ) =
                            EditRecipe.init model.navKey (Just recipeId)
                    in
                    ( EditRecipe pageModel, Cmd.map EditRecipeMsg pageCmds )
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


view : Model -> Document Msg
view model =
    { title = "Recipe Book"
    , body = [ currentView model |> UI.render ]
    }


currentView : Model -> Element.Element Msg
currentView model =
    case model.page of
        NotFoundPage ->
            notFoundView

        ListRecipes recipeListModel ->
            ListRecipes.view recipeListModel |> Element.map ListRecipesMsg

        ShowRecipe showRecipeModel ->
            ShowRecipe.view showRecipeModel |> Element.map ShowRecipeMsg

        EditRecipe editRecipeModel ->
            EditRecipe.view editRecipeModel |> Element.map EditRecipeMsg


notFoundView : Element.Element msg
notFoundView =
    UI.header "404"


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

        ( ListRecipesMsg subMsg, ListRecipes pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ListRecipes.update subMsg pageModel
            in
            ( { model | page = ListRecipes updatedPageModel }
            , Cmd.map ListRecipesMsg updatedCmd
            )

        ( ShowRecipeMsg subMsg, ShowRecipe pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ShowRecipe.update subMsg pageModel
            in
            ( { model | page = ShowRecipe updatedPageModel }
            , Cmd.map ShowRecipeMsg updatedCmd
            )

        ( EditRecipeMsg subMsg, EditRecipe pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    EditRecipe.update subMsg pageModel
            in
            ( { model | page = EditRecipe updatedPageModel }, Cmd.map EditRecipeMsg updatedCmd )

        ( _, _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        ListRecipes recipeListModel ->
            ListRecipes.subscriptions recipeListModel |> Sub.map ListRecipesMsg

        ShowRecipe recipeShowModel ->
            ShowRecipe.subscriptions recipeShowModel |> Sub.map ShowRecipeMsg

        EditRecipe newRecipeModel ->
            EditRecipe.subscriptions newRecipeModel |> Sub.map EditRecipeMsg

        _ ->
            Sub.none
