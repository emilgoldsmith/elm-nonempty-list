module Test where
{-| -}

import Graphics.Element exposing (above)
import Html
import Check exposing (..)
import Check.Investigator exposing (..)
import Check.Runner.Browser exposing (..)
import ElmTest.Test exposing (equals)
import ElmTest.Runner.Element exposing (runDisplay)
import List.Nonempty as NE exposing ((:::))
import Debug
import String

nonemptylist elem = tuple (elem, list elem)

isEven n = n % 2 == 0

testSuite =
    suite "Nonempty List Test Suite"
    [ claim
        "dropping tail makes singleton"
      `true`
        (\(x,xs) -> NE.isSingleton (NE.dropTail (NE.Nonempty x xs)))
      `for`
        nonemptylist int
    , claim
        "converting to and from a normal list is the identity"
      `that`
        (\(x,xs) -> NE.Nonempty x xs |> NE.toList |> NE.fromList)
      `is`
        (\(x,xs) -> Just (NE.Nonempty x xs))
      `for`
        nonemptylist int
    , claim
        "length is 1 more than `length tail`"
     `that`
        (\(x,xs) -> NE.Nonempty x xs |> NE.length)
     `is`
        (\(x,xs) -> List.length xs + 1)
      `for`
        nonemptylist int
    , claim
        "cons works"
     `that`
        (\(y, (x,xs)) -> y ::: (NE.Nonempty x xs) |> NE.toList)
     `is`
        (\(y, (x,xs)) -> y :: x :: xs)
      `for`
        tuple (int, nonemptylist int)
    , claim
        "fromElement results in a singleton"
     `true`
       (\x -> NE.isSingleton (NE.fromElement x))
     `for`
       int
    , claim
        "append works"
     `that`
        (\((x,xs), (y,ys)) ->
            let xz = (NE.Nonempty x xs)
                yz = (NE.Nonempty y ys)
            in NE.toList <| xz `NE.append` yz)
     `is`
        (\((x,xs), (y,ys)) -> x :: xs ++ y :: ys)
      `for`
        tuple (nonemptylist int, nonemptylist int)
    , claim
        "append never results in a singleton"
     `false`
       (\((x,xs), (y,ys)) ->
           let xz = (NE.Nonempty x xs)
               yz = (NE.Nonempty y ys)
           in NE.isSingleton <| xz `NE.append` yz)
     `for`
       tuple (nonemptylist int, nonemptylist int)
    , claim
        "fromList fails only for the empty List"
     `true`
       (\xs -> case NE.fromList xs of
                Just _ -> not (List.isEmpty xs)
                Nothing -> List.isEmpty xs
                )
     `for`
       list int
    , claim
        "map then toList == List.map"
     `that`
        (\(x,xs) -> NE.Nonempty x xs |> NE.map ((*) 2) |> NE.toList)
     `is`
        (\(x,xs) -> x::xs |> List.map ((*) 2))
      `for`
        nonemptylist int
    , claim
        "length (map2 (,) xs ys) == min (length xs) (length ys)"
     `that`
        (\((x,xs), (y,ys)) -> NE.length (NE.map2 (,) (NE.Nonempty x xs) (NE.Nonempty y ys)))
     `is`
        (\((x,xs), (y,ys)) -> 1 + min (List.length xs) (List.length ys))
      `for`
        tuple (nonemptylist int, nonemptylist string)
    , claim
        "map2 (,) xs ys == map (,) xs `andMap` ys "
     `that`
        (\((x,xs), (y,ys)) -> NE.map2 (,) (NE.Nonempty x xs) (NE.Nonempty y ys))
     `is`
        (\((x,xs), (y,ys)) -> NE.map (,) (NE.Nonempty x xs) `NE.andMap` (NE.Nonempty y ys))
      `for`
        tuple (nonemptylist int, nonemptylist string)
    , claim
        "head (map (,,) xs `andMap` ys `andMap` zs) == (head xs, head ys, head zs)"
     `that`
        (\((x,xs), (y,ys), (z,zs)) -> NE.head
            (NE.map (,,) (NE.Nonempty x xs) `NE.andMap` (NE.Nonempty y ys) `NE.andMap` (NE.Nonempty z zs)))
     `is`
        (\((x,xs), (y,ys), (z,zs)) -> (x,y,z))
      `for`
        tuple3 (nonemptylist int, nonemptylist string, nonemptylist char)
    , claim
        "filter works"
     `that`
        (\(x,xs) -> NE.Nonempty x xs |> NE.filter isEven -99 |> NE.toList)
     `is`
        (\(x,xs) -> let filtered = List.filter isEven (x::xs)
                    in if List.isEmpty filtered then [-99] else filtered)
      `for`
        nonemptylist int
    , claim
        "Filtering everything out results in the default value"
     `that`
        (\((x,xs), d) -> NE.Nonempty x xs |> NE.filter (always False) d |> NE.toList)
     `is`
        (\((x,xs), d) -> [d])
      `for`
        tuple (nonemptylist int, int)
    , claim
        "Filtering nothing out is the identity"
     `that`
        (\((x,xs), d) -> NE.Nonempty x xs |> NE.filter (always True) d)
     `is`
        (\((x,xs), d) -> NE.Nonempty x xs)
      `for`
        tuple (nonemptylist int, int)
    , claim
        "Equal lists equate true"
     `true`
        (\(x,xs) -> NE.Nonempty x xs == NE.map identity (NE.Nonempty x xs))
      `for`
        nonemptylist int
    , claim
        "Unequal lists equate false"
     `false`
        (\((x,xs), d) -> NE.Nonempty x xs == d ::: NE.Nonempty x xs)
      `for`
        tuple (nonemptylist int, int)
    , claim
        "popping reduces the length by 1 except for singleton lists"
     `true`
        (\(x,xs) -> let ys = NE.Nonempty x xs
                        lengthReduced = (NE.length ys) - 1 == NE.length (NE.pop ys)
                    in lengthReduced || NE.isSingleton ys)
      `for`
        nonemptylist int
    , claim
        "pop xs == tail xs except for singleton lists"
     `true`
        (\(x,xs) -> let ys = NE.Nonempty x xs
                        tailEquals = NE.toList (NE.pop ys) == xs
                    in tailEquals || NE.isSingleton ys)
      `for`
        nonemptylist int
    , claim
        "reversing twice is the identity"
     `that`
        (\(x,xs) -> let ys = NE.Nonempty x xs
                    in NE.reverse (NE.reverse ys))
      `is`
        (\(x,xs) -> NE.Nonempty x xs)
      `for`
        nonemptylist int
    , claim
        "reversing is equal to the ordinary list reverse"
     `that`
        (\(x,xs) -> let ys = NE.Nonempty x xs
                    in NE.reverse ys |> NE.toList)
      `is`
        (\(x,xs) -> List.reverse (x::xs))
      `for`
        nonemptylist int
    , claim
        "replaceTail is equal to doing so with an ordinary list"
     `that`
        (\(ys, x, xs) -> let zs = NE.Nonempty x xs
                    in NE.replaceTail ys zs |> NE.toList)
      `is`
        (\(ys, x, xs) -> x::ys)
      `for`
        tuple3 (list int, int, list int)
    , claim
        "concat is equal to doing so with an ordinary list"
     `that`
        (\((x, xs), ys) ->
            let zs : NE.Nonempty (NE.Nonempty Int)
                zs = NE.Nonempty (NE.Nonempty x xs) (List.map (uncurry NE.Nonempty) ys)
            in NE.concat zs |> NE.toList)
      `is`
        (\((x, xs), ys) -> let ys' = List.map (uncurry (::)) ys
                           in List.concat ((x::xs)::ys'))
      `for`
        nonemptylist (nonemptylist int)
    , claim
        "member checks the head and the tail"
     `that`
        (\(x, xs, y) -> let zs = NE.Nonempty x xs
                    in NE.member y zs)
      `is`
        (\(x, xs, y) -> x == y || List.member y xs)
      `for`
        tuple3 (int, list int, int)
    , claim
        "foldl is the same as for a list"
     `that`
        (\(x,xs) -> let ys = NE.Nonempty x xs
                    in NE.foldl (++) "" ys)
      `is`
        (\(x,xs) -> List.foldl (++) "" (x::xs))
      `for`
        nonemptylist string
    , claim
        "foldl1 is the same as for a list"
     `that`
        (\(x,xs) -> let ys = NE.Nonempty x xs
                    in NE.foldl1 (++) ys)
      `is`
        (\(x,xs) -> List.foldl (++) "" (x::xs))
      `for`
        nonemptylist string
    , suite "scanning"
        [ claim
            "scanl is the same as for a list"
         `that`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                        in NE.scanl (++) "" ys |> NE.toList)
          `is`
            (\(x,xs) -> List.scanl (++) "" (x::xs))
          `for`
            nonemptylist string
        , claim
            "The head of the result of scanl is the base case"
         `that`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                            scanned = NE.scanl (++) "" ys
                        in NE.head scanned)
          `is`
            (\(x,xs) -> "")
          `for`
            nonemptylist string
        , claim
            "The tail of the result of scanl is the result of scanl1"
         `that`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                            scanned = NE.scanl (++) "" ys
                        in NE.tail scanned)
          `is`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                            scanned = NE.scanl1 (++) ys
                        in NE.toList scanned)
          `for`
            nonemptylist string
        , claim
            "scanl adds 1 to the length"
         `that`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                            scanned = NE.scanl (+) 0 ys
                        in NE.length scanned)
          `is`
            (\(x,xs) -> 2 + List.length xs)
          `for`
            nonemptylist int
        , claim
            "scanl1 does not change the length"
         `that`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                            scanned = NE.scanl1 (+) ys
                        in NE.length scanned)
          `is`
            (\(x,xs) -> 1 + List.length xs)
          `for`
            nonemptylist int
        , claim
            "scanl with string concatenation never decreases the length"
         `true`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                            scanned = NE.scanl1 (++) ys
                            counts = NE.map String.length scanned
                            countPairs = List.map2 (,) (NE.toList counts) (NE.tail counts)
                            bools = List.map (\(a,b) -> a <= b) countPairs
                        in List.all identity bools)
          `for`
            nonemptylist string
        , claim
            "scanl1 does not change the head"
         `that`
            (\(x,xs) -> let ys = NE.Nonempty x xs
                            scanned = NE.scanl1 (++) ys
                        in NE.head scanned)
          `is`
            (\(x,xs) -> x)
          `for`
            nonemptylist string
        ]
    ]

dedupeSuite =
    let mk x xs = NE.Nonempty x xs |> NE.dedup |> NE.toList
    in ElmTest.Test.suite "deduplication"
        [ [1] `equals` mk 1 []
        , [1, 2] `equals` mk 1 [2]
        , [1, 2] `equals` mk 1 [2, 2]
        , [1, 2] `equals` mk 1 [1, 2]
        , [1, 2, 1] `equals` mk 1 [1, 2, 2, 1]
        , [1, 2, 1] `equals` mk 1 [1, 2, 2, 2, 2, 2, 1]
        , [1, 2, 3, 4, 5] `equals` mk 1 [1, 2, 2, 3, 4, 4, 5]
        , [1, 2, 3, 2, 1] `equals` mk 1 [1, 2, 2, 3, 2, 2, 1, 1]
        , [1..4] `equals` mk 1 [1..4]
        , [3, 1, 2, 3] `equals` mk 3 [1..3]
        ]
uniqSuite =
    let mk x xs = NE.Nonempty x xs |> NE.uniq |> NE.toList
    in ElmTest.Test.suite "uniq"
        [ [1] `equals` mk 1 []
        , [1, 2] `equals` mk 1 [2]
        , [1, 2] `equals` mk 1 [2, 2]
        , [1, 2] `equals` mk 1 [1, 2]
        , [1, 2] `equals` mk 1 [1, 2, 2, 1]
        , [1, 2] `equals` mk 1 [1, 2, 2, 2, 2, 2, 1]
        , [1, 2, 3, 4, 5] `equals` mk 1 [1, 2, 2, 3, 4, 4, 5]
        , [1, 2, 3] `equals` mk 1 [1, 2, 2, 3, 2, 2, 1, 1]
        , [1..4] `equals` mk 1 [1..4]
        , [3, 1, 2] `equals` mk 3 [1..3]
        ]

unitSuite = ElmTest.Test.suite "all unit tests"
    [dedupeSuite, uniqSuite]

result = quickCheck testSuite

main = Html.div [] [display result, Html.fromElement (runDisplay unitSuite)]
