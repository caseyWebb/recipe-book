port module Data.Recipe exposing
    ( Recipe
    , RecipeList
    , createRecipe
    , fetchRecipes
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


port fetchRecipes : () -> Cmd msg


port receiveRecipes : (RecipeList -> msg) -> Sub msg


port saveRecipe : Recipe -> Cmd msg


port recipeSaved : (Maybe String -> msg) -> Sub msg


createRecipe : Recipe
createRecipe =
    { id = Nothing
    , rev = Nothing
    , name = ""
    }
