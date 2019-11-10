port module Data.Ingredient exposing (..)


type alias Ingredient =
    { name : String }



---


port fetchIngredients : () -> Cmd msg


port receiveIngredients : (List String -> msg) -> Sub msg
