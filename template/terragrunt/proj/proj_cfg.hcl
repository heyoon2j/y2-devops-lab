locals {
    name = "dr-proj"
    region="ap-northeast-2"

    acl_dr = {
        enviroment = "dr"
        naming_rule = "acl-dr-an2"
        naming_rule_global = "acl-dr"
    }

    dmz_dr = {
        enviroment = "dr"
        naming_rule = "dmz-dr-an2"
        naming_rule_global = "dmz-dr"
    }

    shared_dr = {
        enviroment = "dr"
        naming_rule = "shared-dr-an2"
        naming_rule_global = "shared-dr"
    }

}