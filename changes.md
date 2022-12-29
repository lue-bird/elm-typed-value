# changelog

## 8.2.0

  - `mapUnwrap` add

### 8.1.0

  - `replace` add

#### 8.0.1

  - documentation examples correct

## 8.0.0

- `isChecked` name → `toChecked` with type correct
- `mapTo` add
- `toPublic` add
- `wrapAnd` add
- `mapToWrap` add
- `wrapInternal` add
- `wrapToChecked` add
- `wrapToPublic` add

#### 7.0.1

- updated readme examples

## 7.0.0

- removed `map2 (\a b -> ...) a b` in favor of `a |> and b |> map (\( a, b ) -> ...)`
- removed `val2`
- removed `internalVal2`
- removed `serialize`
- removed `serializeChecked`
- removed `min`
- removed `max`
- changed `tag value` to `tag tag value`
- renamed `val` to `untag`
- renamed `internalVal` to `internal`
- added `mapToTyped`
- added `and`

#### 6.0.1

- now doesn't crash anymore when `Typed`s are checked with `==`

## 6.0.0

- now crashes when `Typed`s are checked with `(==)`
- corrected `isChecked` argument annotation (`accessRight` needs to be the same as of the result)
- allowed calling `internalVal` on `Public` `Typed`s too
- allowed calling `theSmaller` and `theGreater` with `Internal` too
- allowed calling `map2` with different `value`s
- allowed `internalVal` and `internalVal2` to extract from `Public`
- renamed `theSmaller` to `min` and `theGreater` to `max`
- changed `internalVal2 f aTag a bTag b` to `internalVal2 f tag a b`

### 5.1.0

- added `theSmaller` and `theGreater`

#### 5.0.3

- added limit section

#### 5.0.2

- updated typesafe-array example

#### 5.0.1

- added Pet example

## 5.0.0

- changed type of `serializeChecked` to be able to map from & to a different value (like `Serialize.mapValid` already does).

## 4.0.0

- added `internalVal2`
- renamed `internal` to `internalVal`
- changed `map2` type to `value -> value -> valueMapped` like in `map`

## 3.0.0

Renamed `Val` module & type back to `Typed`

- changed `map2` type to `tag -> tag -> tag` & `value -> value -> value`

## 2.0.0

Changed `Typed tag value { createdBy : creator, canAccess : accessRight }` to `Val creator tag accessRight value`.

- `Checked tag value` is now `Val Checked tag Public value`
- `Tagged tag value` is now `Val Tagged tag Public value`
- `CheckedHidden tag value` is now `Val Checked tag Internal value`
- `TaggedHidden tag value` is now `Val Tagged tag Internal value`
- renamed module `Typed` to `Val`
- renamed `value` to `val`
- renamed `values2` to `val2`
- renamed `hiddenValueIn` to `Val.internal`
- `map` now returns a `Tagged` with the same `tag`
- added `serialize` & `serializeChecked`
