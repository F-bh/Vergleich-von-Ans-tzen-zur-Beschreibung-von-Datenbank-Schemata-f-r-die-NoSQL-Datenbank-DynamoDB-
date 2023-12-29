#Kommentar
billingVariable = "visioned"
table "test-table" {
    meta = {
        billingMode = "pro${billingVariable}"
        pointInTimeRecovery = false,
        deleteProtection = false,
        etc = "yes",
    }
    key = {
        partitionKey = {
            type = "string"
            name = "id",
        }
        sortKey = {
            type: "number"
            name: "numberField"
        }
    }
}