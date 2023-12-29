let BillingMode
    : Type
    = < OnDemand | Provisioned >

let TableMeta
    : Type
    = { billingMode : Optional BillingMode
      , pointInTimeRecovery : Bool
      , deleteProtection : Bool
      , etc : Optional Text
      }

let KeyType
    : Type
    = < Text | Number >

let Key 
    : Type
    = { name : Text, type : KeyType }

let Table
    : Type
    = { name : Text
      , meta : TableMeta
      , key : { partitionKey : Key, sortKey : Optional Key }
      }

let func = \(x: Natural) -> x*2

let table
    : Table
    = {
        name = "test"
      , meta = 
        { billingMode = Some BillingMode.OnDemand
        , pointInTimeRecovery = True
        , deleteProtection = True
        , etc = None Text
        }
      , key = 
        { partitionKey = { type = KeyType.Text, name = "1" }
        , sortKey = { type = KeyType.Number, name = "2" }
        }
    }