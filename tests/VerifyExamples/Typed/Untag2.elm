module VerifyExamples.Typed.Untag2 exposing (..)

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



spec2 : Test.Test
spec2 =
    Test.test "#untag: \n\n    ( n3, n5 ) |> Tuple.mapBoth untag untag\n    --> ( 3, 5 )" <|
        \() ->
            Expect.equal
                (
                ( n3, n5 ) |> Tuple.mapBoth untag untag
                )
                (
                ( 3, 5 )
                )