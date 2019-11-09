module Route exposing (Route(..), parseUrl, pushUrl)

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Recipes
    | Recipe String
    | NewRecipe


parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Recipes top
        , map Recipes (s "recipes")
        , map NewRecipe (s "recipes" </> s "new")
        , map Recipe (s "recipes" </> string)
        ]


pushUrl : Route -> Nav.Key -> Cmd msg
pushUrl route navKey =
    routeToString route |> Nav.pushUrl navKey


routeToString : Route -> String
routeToString route =
    case route of
        NotFound ->
            "/not-found"

        NewRecipe ->
            "/recipes/new"

        Recipes ->
            "/recipes"

        Recipe id ->
            "/recipe/" ++ id
