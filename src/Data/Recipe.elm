port module Data.Recipe exposing (Recipe, RecipeList, fetchRecipes, receiveRecipes)


type alias Recipe =
    { id : String
    , name : String
    }


type alias RecipeList =
    { count : Int
    , recipes : List Recipe
    }


port fetchRecipes : () -> Cmd msg


port receiveRecipes : (RecipeList -> msg) -> Sub msg
