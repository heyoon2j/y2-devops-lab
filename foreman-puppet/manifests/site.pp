# Foreman ENC assigns one host-level role: role::base or role::gpu_svr.
# Host Groups classify CSP only; they must not assign either role by default.
# An unclassified node intentionally receives no managed resources.
node default {
}
