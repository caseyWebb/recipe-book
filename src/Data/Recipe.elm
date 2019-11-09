port module Data.Recipe exposing
    ( Recipe
    , RecipeList
    , createRecipe
    , fetchRecipes
    , findRecipeById
    , receiveRecipe
    , receiveRecipes
    , recipeSaved
    , saveRecipe
    )


type alias Recipe =
    { id : Maybe String
    , rev : Maybe String
    , name : String
    }


type alias RecipeList =
    { count : Int
    , recipes : List Recipe
    }


createRecipe : Recipe
createRecipe =
    { id = Nothing
    , rev = Nothing
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
