# package-private env + singleton instance
.pkgenv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .pkgenv$advisor <- AIPolicyAdvisor$new()
}