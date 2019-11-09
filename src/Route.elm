module Route exposing (Route(..), parseUrl, pushUrl, toString)

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Recipes
    | Recipe String
    | NewRecipe
    | EditRecipe String


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
        , map EditRecipe (s "recipes" </> string </> s "edit")
        ]


pushUrl : Route -> Nav.Key -> Cmd msg
pushUrl route navKey =
    toString route |> Nav.pushUrl navKey


toString : Route -> String
toString route =
    case route of
        NotFound ->
            "/not-found"

        NewRecipe ->
            "/recipes/new"

        Recipes ->
            "/recipes"

        Recipe id ->
            "/recipes/" ++ id

        EditRecipe id ->
            "/recipes/" ++ id ++ "/edit"
