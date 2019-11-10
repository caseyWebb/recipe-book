port module Data.Ingredient exposing (..)


type alias Ingredient =
    { name : String }


newIngredient : String -> Ingredient
newIngredient name =
    { name = name }



---


port fetchIngredients : () -> Cmd msg


port receiveIngredients : (List String -> msg) -> Sub msg
