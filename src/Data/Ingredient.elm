port module Data.Ingredient exposing (..)


type alias Ingredient =
    { name : String
    , section : String
    , quantity : Float
    , unit : String
    }


newIngredient : String -> Ingredient
newIngredient name =
    { name = name
    , section = "Unknown"
    , unit = ""
    , quantity = 1
    }



---


port fetchIngredients : () -> Cmd msg


port receiveIngredients : (List Ingredient -> msg) -> Sub msg
