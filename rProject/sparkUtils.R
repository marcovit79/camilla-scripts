library(sparklyr)
library(dplyr)
library(DBI)

make_substitutions <- function(text, substitutions ) {
  result <- text
  
  if (length(substitutions) > 0) {
    for (key in names(substitutions)) {
      # Escape $ and {} for standard regex: \\$\\{KEY\\}
      pattern <- paste0("\\$\\{", key, "\\}")
      val <- substitutions[[key]]
      
      # Replace all occurrences of the pattern in the statement
      result <- gsub(pattern, val, result)
    }
  }
  return( result )
}

split_text_blocks <- function(file_path) {
  # Legge il file riga per riga assicurando la codifica UTF-8
  lines <- readLines(file_path, encoding = "UTF-8", warn = FALSE)
  
  # Unisce tutte le righe in un'unica stringa testuale
  full_text <- paste(lines, collapse = "\n")
  
  # Divide il testo usando un'espressione regolare perl-compatibile.
  # (?m) abilita la modalità multiriga affinché ^ corrisponda all'inizio di ogni riga.
  blocks <- strsplit(full_text, "(?m)^===.*(\\n|$)", perl = TRUE)[[1]]
  
  # Rimuove eventuali spazi bianchi o ritorni a capo all'inizio e alla fine di ogni blocco
  blocks <- trimws(blocks)
  
  # Filtra il vettore per escludere le stringhe vuote
  non_blank_blocks <- blocks[blocks != ""]
  
  return(non_blank_blocks)
}


executeSqlFile <- function( sparkContext, file_path, substitutions = list() ) {
  statements = split_text_blocks(file_path) 
  for( statement in statements) {
    real_statement <- make_substitutions( statement, substitutions )
    dbExecute( sparkContext, real_statement )
  }
}

