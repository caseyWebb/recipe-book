port module Data.Recipe exposing
    ( Recipe
    , RecipeList
    , fetchRecipes
    , findRecipeById
    , newRecipe
    , receiveRecipe
    , receiveRecipes
    , recipeSaved
    , saveRecipe
    )


type alias Recipe =
    { slug : String
    , name : String
    }


type alias RecipeList =
    { count : Int
    , recipes : List Recipe
    }


newRecipe : Recipe
newRecipe =
    { slug = ""
    , name = ""
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
