import sys
import re
from pyspark.sql import SparkSession

def parse_arguments(args):
    sql_files, substitutions, exports = [], {}, {}
    for arg in args:
        if arg.startswith("--sql-file="):
            sql_files.append(arg.split("=", 1)[1])
        elif arg.startswith("--subst-"):
            key, val = arg[8:].split("=", 1)
            substitutions[key] = val
        elif arg.startswith("--export-"):
            key, val = arg[9:].split("=", 1)
            exports[key] = val
            
    if not sql_files:
        raise ValueError("Missing required argument: --sql-file=<path>")
    return sql_files, substitutions, exports

def read_and_substitute(file_path, substitutions):
    with open(file_path, 'r', encoding='utf-8') as f:
        sql_text = f.read()
        
    for key, val in substitutions.items():
        pattern = re.compile(rf'\$\{{{key}\}}')
        sql_text = pattern.sub(val, sql_text)
    return sql_text

def validate_no_missing_vars(sql_text):
    missing_keys = re.findall(r'\$\{([a-zA-Z0-9_]+)\}', sql_text)
    if missing_keys:
        raise ValueError(f"Unvalorized keys found in SQL: {set(missing_keys)}")

def extract_statements(sql_text):
    statements = re.split(r'(?m)^===.*$', sql_text)
    return [stmt.strip() for stmt in statements if stmt.strip()]

def create_spark_session():
    return SparkSession.builder \
        .appName("LocalSQLRunner") \
        .master("local[*]") \
        .getOrCreate()

def execute_statements(spark, statements):
    for stmt in statements:
        spark.sql(stmt)

def export_results(spark, exports):
    for table_name, dest_path in exports.items():
        print(f"Exporting {table_name} to {dest_path}...")
        df = spark.table(table_name).toPandas()
        df.to_csv(dest_path, sep=';', index=False, header=True)

def main():
    sql_files, substitutions, exports = parse_arguments(sys.argv[1:])
    spark = create_spark_session()
    try:
        for sql_file in sql_files:
            print(f"Executing file: {sql_file}")
            sql_text = read_and_substitute(sql_file, substitutions)
            validate_no_missing_vars(sql_text)
            statements = extract_statements(sql_text)
            execute_statements(spark, statements)
            
        export_results(spark, exports)
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
