module.exports = ( obj )->
  if !obj ||
      {}.toString.call( obj ) != '[object Object]' ||
      obj.nodeType ||
      obj.setInterval
    return false

  has_own                   = {}.hasOwnProperty;
  has_own_constructor       = has_own.call( obj, 'constructor' );
  has_is_property_of_method = has_own.call( obj.constructor.prototype, 'isPrototypeOf' );

  # Not own constructor property must be Object
  if  obj.constructor &&
      !has_own_constructor &&
      !has_is_property_of_method
    return false;

  # Own properties are enumerated firstly, so to speed up,
  # if last one is own, then all properties are own.
  key == undefined
  for key in obj
      continue

  return key == undefined || has_own.call( obj, key );