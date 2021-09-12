module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Review.Rule as Rule exposing (Rule)
import NoUnused.Dependencies
import NoUnused.Variables
import OnlyAllSingleUseTypeVarsEndWith_
import NoSinglePatternCase
import NoLeftPizza
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoForbiddenWords
import NoBooleanCase
import NoPrematureLetComputation
import NoRecordAliasConstructor
import LinksPointToExistingPackageMembers


config : List Rule
config =
    [ NoUnused.Dependencies.rule
    , NoUnused.Variables.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , OnlyAllSingleUseTypeVarsEndWith_.rule
    , NoSinglePatternCase.rule
        (NoSinglePatternCase.fixInArgument
            |> NoSinglePatternCase.ifAsPatternRequired
                (NoSinglePatternCase.fixInLetInstead
                    |> NoSinglePatternCase.andIfNoLetExists
                        NoSinglePatternCase.createNewLet
                )
        )
    , NoLeftPizza.rule NoLeftPizza.Any
    , NoExposingEverything.rule
    , NoImportingEverything.rule [ "Nats" ]
    , NoMissingTypeAnnotation.rule
    , NoForbiddenWords.rule [ "TODO", "todo", "REPLACEME" ]
    , NoBooleanCase.rule
    , NoPrematureLetComputation.rule
    , NoRecordAliasConstructor.rule
    , LinksPointToExistingPackageMembers.rule
    ]
