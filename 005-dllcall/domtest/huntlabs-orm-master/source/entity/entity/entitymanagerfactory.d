module entity.entity.entitymanagerfactory;

import entity;

class EntityManagerFactory
{
    string name;
    DatabaseConfig config;
    Database db;
    Dialect dialect;
    
    this(string name,DatabaseConfig config)
    {
        this.name = name;
        this.config = config;
        if(config.isMysql){
            this.dialect = new MysqlDialect();
        }else if(config.isPgsql){
            this.dialect = new PostgresqlDialect(); 
        }else if(config.isSqlite){
            this.dialect = new SqliteDialect(); 
        }else{
            throw new EntityException("unkonw sql type");
        }
        this.db = new Database(config);
    }

    public EntityManager createEntityManager(T...)()
    {
        //pragma(msg,makeEntityList!(T)());
        mixin(makeEntityList!(T)());
        return new EntityManager(name,config,db,dialect,models,classMap);	
    }

    public QueryBuilder createQueryBuilder()
    {
        return new QueryBuilder(config,db,dialect);
    }
}

string makeEntityList(T...)(){
    string importCode;
    string str = "
    EntityInfo[string] models = null;
    EntityInfo[TypeInfo_Class] classMap = null;
    FieldInfo[string] fields = null;
    DlangDataType fieldType = null;
    int[] fieldAttrs = null;
    EntityInfo info;
    FieldInfo fieldInfo;
    ";
    foreach(t;T)
    {
        //pragma(msg,"fullyQualifiedName:",fullyQualifiedName!t);
        //pragma(msg,"myPackageNamePrefix:",myPackageNamePrefix!t);
        //pragma(msg,"moduleName:",moduleName!t);
        //pragma(msg,"Class Model:",t.stringof);
        //pragma(msg,"Table Name:",__traits(getAttributes,t));
        //import process
        string impcode = "";
        static if (t.stringof.startsWith("module ")) {
            impcode = "import " ~ fullyQualifiedName!t ~ ";\n";
        } else {
            impcode = generateImportFor!(t);
        }
        if (indexOf(importCode, impcode) < 0)
        importCode ~= impcode;
        //import process end
        string incrementKey = null;
        string primaryKey = null;
        string[] keys = null;
        string[string] keyType = null;
        string[] notNullKeys = null;
		string tableName = __traits(getAttributes,t)[0];
        foreach(tt; __traits(derivedMembers, t)) 
        {
            //pragma(msg,"\tField Name:",tt.stringof);
            auto key = removeDoubleQuotes(tt.stringof);
            keys ~= key;
            alias Type = typeof(__traits(getMember,t,tt));
			//pragma(msg,typeid(Type));
            str ~= "fieldType = new "~getDlangDataTypeStr!Type~"();";
            //pragma(msg,"\tField Attr:",__traits(getAttributes,__traits(getMember,t,tt)));
            foreach(k;__traits(getAttributes,__traits(getMember,t,tt))){
				str~="fieldAttrs~=cast(int)"~to!string(k)~";";
                if(k == Auto || k == AutoIncrement)incrementKey = key;
                if(k == PrimaryKey)primaryKey = key;
                if(k == NotNull)notNullKeys ~= key;
			}
            str ~= "fieldInfo = new FieldInfo("~tt.stringof~","~tt.stringof~",
                fieldType,fieldAttrs,dialect,
                function(Object obj,FieldInfo info,Dialect dialect) {
                //WriteFunc
                    "~fullyQualifiedName!t~" entity = cast("~fullyQualifiedName!t~")obj;
					entity."~removeDoubleQuotes(tt.stringof)~" = cast("~getDlangTypeStr!Type~")*(dialect.fromSqlValue(info).peek!"~getDlangTypeStr!Type~");
                },
                function(Object obj,FieldInfo info,Dialect dialect){
                //ReadFunc
                    "~fullyQualifiedName!t~" entity = cast("~fullyQualifiedName!t~")obj;";
					str ~= "return dialect.toSqlValueImpl(info.fieldType,Variant(entity."
						~removeDoubleQuotes(tt.stringof)~"));
                }
            );
            fields["~tt.stringof~"] = fieldInfo;
            ";
            str ~= "fieldInfo=null;fieldType = null;fieldAttrs = null;";
        }
        str ~= "info = new EntityInfo(\""~t.stringof~"\",\""~__traits(getAttributes,t)[0]~"\",fields,";
        str ~= "
        function(Object obj,EntityInfo info,EntityManager manager){
            //PersistFunc
            "~fullyQualifiedName!t~" entity = cast("~fullyQualifiedName!t~")obj;
            auto builder = manager.createQueryBuilder();
            builder.insert(\""~tableName~"\").values([";
            foreach(kkk;keys)
                if(kkk != incrementKey)str ~= "\""~ kkk ~ "\":info.fields[\""~kkk~"\"].read(entity) ," ;
            str ~= "]);
            //writeln(builder);
            auto stmt = manager.db.prepare(builder.toString);
            stmt.execute();
            ";
            if(incrementKey.length)str ~= "entity."~incrementKey~" = stmt.lastInsertId;";
            str ~= "return obj;
        },
        function(Object obj,EntityInfo info,EntityManager manager){
            //RemoveFunc
            "~fullyQualifiedName!t~" entity = cast("~fullyQualifiedName!t~")obj;
            auto builder = manager.createQueryBuilder();
            builder.remove(\""~tableName~"\")
                .where(\""~primaryKey~" = \" ~info.fields[\""~primaryKey~"\"].read(entity) );
            //writeln(builder);
            auto stmt = manager.db.prepare(builder.toString);
            return stmt.execute();
        },
        function(Object obj,EntityInfo info,EntityManager manager){
            //MergeFunc
            "~fullyQualifiedName!t~" entity = cast("~fullyQualifiedName!t~")obj;
            auto builder = manager.createQueryBuilder();
            builder.update(\""~tableName~"\")";
            foreach(kkk;keys)
                if(kkk != incrementKey)str ~= ".set(\""~ kkk ~ "\",info.fields[\""~kkk~"\"].read(entity))" ;
            str ~= "
                .where(\""~primaryKey~" = \" ~info.fields[\""~primaryKey~"\"].read(entity) );
            //writeln(builder);
            auto stmt = manager.db.prepare(builder.toString);
            stmt.execute();
            return obj;
        },
        function(Object obj,EntityInfo info,EntityManager manager){
            //FindFunc
            "~fullyQualifiedName!t~" entity = cast("~fullyQualifiedName!t~")obj;
            auto builder = manager.createQueryBuilder();
            builder.select(\"*\")
				.from(\""~tableName~"\")
                .where(\""~primaryKey~" = \" ~info.fields[\""~primaryKey~"\"].read(entity) );
				//writeln(builder);
				auto stmt = manager.db.prepare(builder.toString);
				auto rs = stmt.query();
				if(!rs.rows)return obj;
				auto row = rs.front();
                //writeln(row);
				";
            foreach(key;keys)
                if(key != primaryKey)str ~= "info.fields[\""~key~"\"].fieldValue = Variant(row[\""~key~"\"]);info.fields[\""~key~"\"].write(entity);";
        str ~= "
            return obj;
        }
        );";
        str ~= "models[\""~t.stringof~"\"] = info;";
        str ~= "classMap[cast(TypeInfo_Class)"~t.stringof~".classinfo] = info;";
        str ~= "info = null;fields = null;";
        }
        return importCode ~ str;
    }


template myPackageNamePrefix(alias T)
{
    static if (is(typeof(__traits(parent, T))))
    enum parent = myPackageNamePrefix!(__traits(parent, T));
    else
    enum string parent = null;

    static if (T.stringof.startsWith("package "))
    enum myPackageNamePrefix = (parent ? parent ~ '.' : "") ~ T.stringof[8 .. $] ~ ".";
    else static if (parent)
    enum myPackageNamePrefix = parent;
    else
    enum myPackageNamePrefix = "";
}

string generateImportFor(T)() {
    static if (T.stringof.startsWith("module ")) {
        return "import " ~ fullyQualifiedName!T ~ ";\n";
    } else {
        return "import " ~ myPackageNamePrefix!T ~ moduleName!T ~ ";\n";
    }
}

string removeDoubleQuotes(string str)
{
    return str[1..$-1];
}

