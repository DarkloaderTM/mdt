Config = {}


-- allows for 3 different sql wrappers, mysql-async, ghmattisql, oxmysql
-- make sure you edit your fxmanifest if you plan on using somethin different than mysql-async.
-- see line 1268 for the function this relates to. everything is self explanatory.
Config.Mysql = 'mysql-async'