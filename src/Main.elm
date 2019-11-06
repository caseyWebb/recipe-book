module Main exposing (main)

import Browser
import Page.Recipes.List as ListRecipes


main : Program () ListRecipes.Model ListRecipes.Msg
main =
    Browser.element
        { init = ListRecipes.init
        , view = ListRecipes.view
        , update = ListRecipes.update
        , subscriptions = ListRecipes.subscriptions
        }
