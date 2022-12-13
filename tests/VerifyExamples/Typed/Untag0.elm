module VerifyExamples.Typed.Untag0 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import Typed exposing (..)
import Typed exposing (untag)

type PrimeTag
    = Prime
type alias Prime =
    Typed Checked PrimeTag Public Int

n5 : Prime
n5 =
    5 |> tag Prime
n3 : Prime
n3 =
    3 |> tag Prime



spec0 : Test.Test
spec0 =
    Test.test "#untag: \n\n    (n3 |> untag) < (n5 |> untag)\n    --> True" <|
        \() ->
            Expect.equal
                (
                (n3 |> untag) < (n5 |> untag)
                )
                (
                True
                )