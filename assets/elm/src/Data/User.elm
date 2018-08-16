module Data.User
    exposing
        ( User
        , Record
        , fragment
        , decoder
        , getId
        , getCachedData
        )

import Json.Decode as Decode exposing (Decoder, field, maybe, string, int, succeed, fail)
import GraphQL exposing (Fragment)


-- TYPES


type User
    = User Record


type alias Record =
    { id : String
    , email : String
    , firstName : String
    , lastName : String
    , avatarUrl : Maybe String
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment UserFields on User {
          id
          email
          firstName
          lastName
          avatarUrl
          fetchedAt
        }
        """
        []



-- DECODERS


decoder : Decoder User
decoder =
    Decode.map User <|
        Decode.map6 Record
            (field "id" string)
            (field "email" string)
            (field "firstName" string)
            (field "lastName" string)
            (field "avatarUrl" (maybe string))
            (field "fetchedAt" int)



-- API


getId : User -> String
getId (User { id }) =
    id


getCachedData : User -> Record
getCachedData (User record) =
    record
