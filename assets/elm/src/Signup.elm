module Signup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, onBlur)
import Regex exposing (regex)
import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (decodeString)
import Time exposing (Time, second)
import Navigation


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { csrf_token : String
    , team_name : String
    , slug : String
    , first_name : String
    , last_name : String
    , username : String
    , email : String
    , password : String
    , errors : List ValidationError
    , lastCheckedSlug : String
    , formState : FormState
    }


type FormState
    = Idle
    | Submitting


type alias Flags =
    { csrf_token : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( (initialState flags), Cmd.none )


initialState : Flags -> Model
initialState flags =
    { csrf_token = flags.csrf_token
    , team_name = ""
    , slug = ""
    , first_name = ""
    , last_name = ""
    , username = ""
    , email = ""
    , password = ""
    , errors = []
    , lastCheckedSlug = ""
    , formState = Idle
    }



-- UPDATE


type Msg
    = TeamNameChanged String
    | SlugChanged String
    | UsernameChanged String
    | FirstNameChanged String
    | LastNameChanged String
    | EmailChanged String
    | PasswordChanged String
    | TeamNameBlurred
    | SlugBlurred
    | UsernameBlurred
    | FirstNameBlurred
    | LastNameBlurred
    | EmailBlurred
    | PasswordBlurred
    | Submit
    | Submitted (Result Http.Error String)
    | Validate
    | Validated String (Result Http.Error (List ValidationError))
    | Tick Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TeamNameChanged val ->
            ( { model | team_name = val, slug = (slugify val) }, Cmd.none )

        SlugChanged val ->
            ( { model | slug = val }, Cmd.none )

        FirstNameChanged val ->
            ( { model | first_name = val }, Cmd.none )

        LastNameChanged val ->
            ( { model | last_name = val }, Cmd.none )

        UsernameChanged val ->
            ( { model | username = val }, Cmd.none )

        EmailChanged val ->
            ( { model | email = val }, Cmd.none )

        PasswordChanged val ->
            ( { model | password = val }, Cmd.none )

        TeamNameBlurred ->
            validateIfPresent model "team_name" model.team_name

        SlugBlurred ->
            validateIfPresent model "slug" model.slug

        FirstNameBlurred ->
            validateIfPresent model "first_name" model.first_name

        LastNameBlurred ->
            validateIfPresent model "last_name" model.last_name

        UsernameBlurred ->
            validateIfPresent model "username" model.username

        EmailBlurred ->
            validateIfPresent model "email" model.email

        PasswordBlurred ->
            validateIfPresent model "password" model.password

        Submit ->
            ( { model | formState = Submitting }, submit model )

        Submitted (Ok redirectUrl) ->
            ( model, Navigation.load redirectUrl )

        Submitted (Err (Http.BadStatus resp)) ->
            case decodeString errorDecoder resp.body of
                Ok value ->
                    ( { model | formState = Idle, errors = value }, Cmd.none )

                Err _ ->
                    ( { model | formState = Idle }, Cmd.none )

        Submitted (Err _) ->
            ( { model | formState = Idle }, Cmd.none )

        Validate ->
            ( model, Cmd.none )

        Validated attribute (Ok errors) ->
            let
                newErrors =
                    (errorsFor attribute errors)
                        ++ (errorsNotFor attribute model.errors)
            in
                ( { model | errors = newErrors }, Cmd.none )

        Validated _ (Err _) ->
            ( model, Cmd.none )

        Tick _ ->
            if not (model.slug == "") && not (model.slug == model.lastCheckedSlug) then
                ( { model | lastCheckedSlug = model.slug }, validate "slug" model )
            else
                ( model, Cmd.none )


validateIfPresent : Model -> String -> String -> ( Model, Cmd Msg )
validateIfPresent model attribute value =
    if not (value == "") then
        ( model, validate attribute model )
    else
        ( model, Cmd.none )


slugify : String -> String
slugify teamName =
    teamName
        |> String.toLower
        |> (Regex.replace Regex.All (regex "[^a-z0-9]+") (\_ -> "-"))
        |> (Regex.replace Regex.All (regex "(^-|-$)") (\_ -> ""))
        |> String.slice 0 20



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every second Tick



-- VIEW


type alias FormField =
    { type_ : String
    , name : String
    , label : String
    , value : String
    , onInput : String -> Msg
    , onBlur : Msg
    }


view : Model -> Html Msg
view model =
    div [ class "signup-form" ]
        [ div [ class "signup-form__header" ]
            [ h1 [] [ text "Join Neuron" ]
            , p [] [ text "Neuron is a smarter communication platform built for teams that value their focus. Take it for a spin!" ]
            ]
        , div [ class "signup-form__section" ]
            [ div [ class "signup-form__section-header" ]
                [ span [ class "signup-form__section-number" ] [ text "1" ]
                , text "Tell us about yourself!"
                ]
            , div [ class "signup-form__section-body" ]
                [ div [ class "inline-field-group" ]
                    [ textField (FormField "text" "first_name" "First Name" model.first_name FirstNameChanged FirstNameBlurred) (errorsFor "first_name" model.errors)
                    , textField (FormField "text" "last_name" "Last Name" model.last_name LastNameChanged LastNameBlurred) (errorsFor "last_name" model.errors)
                    ]
                , textField (FormField "text" "username" "Username" model.username UsernameChanged UsernameBlurred) (errorsFor "username" model.errors)
                , textField (FormField "email" "email" "Email Address" model.email EmailChanged EmailBlurred) (errorsFor "email" model.errors)
                , textField (FormField "password" "password" "Password" model.password PasswordChanged PasswordBlurred) (errorsFor "password" model.errors)
                ]
            ]
        , div [ class "signup-form__section" ]
            [ div [ class "signup-form__section-header" ]
                [ span [ class "signup-form__section-number" ] [ text "2" ]
                , text "Configure your team"
                ]
            , div [ class "signup-form__section-body" ]
                [ textField (FormField "text" "team_name" "Team Name" model.team_name TeamNameChanged TeamNameBlurred) (errorsFor "team_name" model.errors)
                , slugField (FormField "text" "slug" "URL" model.slug SlugChanged SlugBlurred) (errorsFor "slug" model.errors)
                ]
            ]
        , div [ class "signup-form__controls" ]
            [ button
                [ type_ "submit"
                , class "button button--primary button--full button--large"
                , onClick Submit
                , disabled (model.formState == Submitting)
                ]
                [ text "Sign up" ]
            ]
        , div [ class "signup-form__footer" ]
            [ p []
                [ text "Already have an team? "
                , a [ href "/teams/search" ] [ text "Sign in" ]
                , text "."
                ]
            ]
        ]


errorsFor : String -> List ValidationError -> List ValidationError
errorsFor attribute errors =
    List.filter (\error -> error.attribute == attribute) errors


errorsNotFor : String -> List ValidationError -> List ValidationError
errorsNotFor attribute errors =
    List.filter (\error -> not (error.attribute == attribute)) errors


textField : FormField -> List ValidationError -> Html Msg
textField field errors =
    div [ class (String.join " " [ "form-field", (errorClass errors) ]) ]
        [ label [ for field.name, class "form-label" ] [ text field.label ]
        , input
            [ id field.name
            , type_ field.type_
            , class "text-field text-field--full text-field--large"
            , name field.name
            , value field.value
            , onInput field.onInput
            , onBlur field.onBlur
            ]
            []
        , formErrors errors
        ]


slugField : FormField -> List ValidationError -> Html Msg
slugField field errors =
    div [ class (String.join " " [ "form-field", (errorClass errors) ]) ]
        [ label [ for "slug", class "form-label" ] [ text "URL" ]
        , div [ class "slug-field" ]
            [ div [ class "slug-field__slug" ]
                [ input
                    [ id field.name
                    , type_ field.type_
                    , class "text-field text-field--large"
                    , name field.name
                    , value field.value
                    , onInput field.onInput
                    , onBlur field.onBlur
                    ]
                    []
                ]
            , div [ class "slug-field__domain" ] [ text ".neuron.chat" ]
            ]
        , formErrors errors
        ]


errorClass : List ValidationError -> String
errorClass errors =
    case errors of
        [] ->
            ""

        _ ->
            "form-field--error"


formErrors : List ValidationError -> Html a
formErrors errors =
    case errors of
        error :: _ ->
            div [ class "form-errors" ] [ text error.message ]

        [] ->
            text ""



-- HTTP


type alias ValidationError =
    { attribute : String
    , message : String
    }


submit : Model -> Cmd Msg
submit model =
    Http.send Submitted (buildSubmitRequest model)


validate : String -> Model -> Cmd Msg
validate attribute model =
    Http.send (Validated attribute) (buildValidationRequest model)


buildSubmitRequest : Model -> Http.Request String
buildSubmitRequest model =
    postWithCsrfToken model.csrf_token "/api/teams" (buildBody model) successDecoder


buildValidationRequest : Model -> Http.Request (List ValidationError)
buildValidationRequest model =
    postWithCsrfToken model.csrf_token "/api/signup/errors" (buildBody model) errorDecoder


postWithCsrfToken : String -> String -> Http.Body -> Decode.Decoder a -> Http.Request a
postWithCsrfToken token url body decoder =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-Csrf-Token" token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


buildBody : Model -> Http.Body
buildBody model =
    Http.jsonBody
        (Encode.object
            [ ( "signup"
              , Encode.object
                    [ ( "team_name", Encode.string model.team_name )
                    , ( "slug", Encode.string model.slug )
                    , ( "first_name", Encode.string model.first_name )
                    , ( "last_name", Encode.string model.last_name )
                    , ( "username", Encode.string model.username )
                    , ( "email", Encode.string model.email )
                    , ( "password", Encode.string model.password )
                    ]
              )
            ]
        )



-- DECODERS


successDecoder : Decode.Decoder String
successDecoder =
    Decode.at [ "redirect_url" ] Decode.string


errorDecoder : Decode.Decoder (List ValidationError)
errorDecoder =
    Decode.field "errors"
        (Decode.list
            (Decode.map2 ValidationError
                (Decode.field "attribute" Decode.string)
                (Decode.field "message" Decode.string)
            )
        )
