{- PP

Copyright (C) 2015, 2016, 2017 Christophe Delord

http://www.cdsoft.fr/pp

This file is part of PP.

PP is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PP is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PP.  If not, see <http://www.gnu.org/licenses/>.
-}

import Test.Hspec

import Environment

import Data.List

main :: IO ()
main = hspec $

    describe "Preprocessor" $
        it "defines disjoint character sets" $ do
            let sets = concat [ defaultMacroChars, defaultBlockChars, defaultLiterateMacroChars ]
            nub sets `shouldBe` sets
