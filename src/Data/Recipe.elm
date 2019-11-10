port module Data.Recipe exposing (..)

import Data.Ingredient exposing (Ingredient)


type alias Recipe =
    { slug : String
    , name : String
    , ingredients : List Ingredient
    }


type alias RecipeList =
    { count : Int
    , recipes : List Recipe
    }


newRecipe : Recipe
newRecipe =
    { slug = ""
    , name = ""
    , ingredients = []
    }



---


port fetchRecipes : () -> Cmd msg


port receiveRecipes : (RecipeList -> msg) -> Sub msg



---


port findRecipeById : String -> Cmd msg


port receiveRecipe : (Recipe -> msg) -> Sub msg



---


port saveRecipe : Recipe -> Cmd msg


port recipeSaved : (Maybe String -> msg) -> Sub msg
