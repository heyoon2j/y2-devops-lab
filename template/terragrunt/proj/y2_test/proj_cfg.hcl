locals {
    name = "y2-test"
    region="ap-south-1"

    test_dev = {
        enviroment = "dev"
        naming_rule = "test-dev-as1"
        naming_rule_global = "test-dev"
    }

    test_k8s_dev = {
        enviroment = "dev"
        naming_rule = "test-k8s-dev-as1"
        naming_rule_global = "test-k8s-dev-as1"
    }
}