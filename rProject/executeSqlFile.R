source("./sparkUtils.R")

sc <- spark_connect(master = "local")

BASE_MEXAL_EXPORT_DIR = paste0(getwd(), "/mexal_exports")
substitutions = list(
  ALIAS_CSV_PATH = paste0( BASE_MEXAL_EXPORT_DIR, "/alias.csv"),
  ARTICOLI_1_CSV_PATH = paste0( BASE_MEXAL_EXPORT_DIR, "/articoli_1.csv"),
  ARTICOLI_5_CSV_PATH = paste0( BASE_MEXAL_EXPORT_DIR, "/articoli_5.csv"),
  FORNITORI_CSV_PATH = paste0( BASE_MEXAL_EXPORT_DIR, "/fornitori.csv"),
  FOGLIO_ARTICOLI_FROM_DRIVE_CSV_PATH = paste0( BASE_MEXAL_EXPORT_DIR, "/foglio_articoli_da_drive_2026_03_01.csv")
)

executeSqlFile( sc, "./sql/compute_foglio_articoli.sql", substitutions)
executeSqlFile( sc, "./sql/check_foglio_articoli.sql", substitutions)

a = dbGetQuery( sc, "select * from foglio_articoli");

