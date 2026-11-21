# Set a typed Boolean global/host parameter in Foreman; do not use a Fact.
class profile::management {
  $managed = getvar('::puppet_managed')
  if $managed !~ Boolean {
    fail('puppet_managed must be a Boolean ENC parameter; set true or false in Foreman')
  }
}
