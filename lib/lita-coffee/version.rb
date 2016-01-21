module LitaCoffee
  # lita-coffee version
  VERSION = '0.2.0'
  # lita-github version split amongst different revisions
  MAJOR_VERSION, MINOR_VERSION, REVISION = VERSION.split('.').map(&:to_i)
end
