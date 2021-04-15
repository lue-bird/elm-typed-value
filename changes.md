# changelog

## 2.0.0

Changed `Typed tag value { createdBy : whoCreated, canAccess : whoCanAccess }` to `Val whoCanCreate tag whoCanAccess value`.

- `Checked tag value` became `Val Checked tag Public value`
- `Tagged tag value` became `Val Tagged tag Public value`
- `CheckedHidden tag value` became `Val Checked tag Internal value`
- `TaggedHidden tag value` became `Val Tagged tag Internal value`
- renamed module `Typed` to `Val`
- renamed `value` to `val`
- renamed `values2` to `val2`
- renamed `hiddenValueIn` to `Val.internal`
- `map` doesn't return a `Tagged` with the same `tag`
- add `serialize` & `serializeChecked`
