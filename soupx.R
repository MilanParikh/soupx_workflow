library(SoupX)
library(Matrix)

args <- commandArgs(trailingOnly = TRUE)

path <- args[1]
matrix_file <- args[2]

sc = load10X(path)
sc = autoEstCont(sc)
out = adjustCounts(sc)
writeMM(out, matrix_file)