# PPOL 6818 course project: when RStudio opens this project, finish setup the
# first time, and afterwards accept course invitations and clone new course
# repositories.
if (interactive() && requireNamespace("ppol6818", quietly = TRUE)) {
  setHook("rstudio.sessionInit", function(newSession) ppol6818::on_open(), action = "append")
}
