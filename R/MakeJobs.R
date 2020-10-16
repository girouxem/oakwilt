# FUNCTION CREATES .JOB SCRIPTS TO BE RUN IN THE GPSC given:
# cmd : a command or commands
# prefix : name of the new directory where the scripts will be, which will also be the basename of scripts
# node: number of nodes
# memory: how much memory (MB) 
# walltime: time for the job (seconds)
# yes/no: for making a master job that will submit all the jobs. 
# Note the "master job" that submits all jobs is set for one week walltime, however the job will end once all the jobs have been submitted
# eg. To run the function so that each cmd has 4 cores, 1800 MB of memory and 1600s and make a master job to run all
# cmd <- (ls, pwd)
# MakeJobs(cmd, prefix, 4, 1800, 1600, "yes")

MakeJobs <- function(cmd, prefix, node, mem, walltime, makeAlljobSub ) {
  dir.create(paste(sharedPathAn, prefix, sep = ""), showWarnings = TRUE, recursive = FALSE) 
  outPath <- paste(sharedPathAn, prefix, "/", sep="") 
  jobsub_all = ""
  for(k in 1:length(cmd)) { 
    cat(paste("#!/bin/bash\n\n",
              "##$ -j y\n",
              "#$ -pe dev 1\n",
              "#$ -l res_cpus=", node, "\n",
              "#$ -l res_mem=", mem, "\n",
              "#$ -l h_rt=", walltime, "\n",
              "#$ -S /bin/bash\n",
              "#$ -o ", outPath, "\n",
              "#$ -e ", outPath, "\n",
              "#$ -l res_image=cfia_all_grdi_centos-6.8-amd64_latest\n\n",
              cmd[k],
              sep=""),
        file=paste(outPath, prefix, k, ".job", sep="")
    )
    jobsub_all = paste(jobsub_all, "jobsub ", outPath, prefix, k, ".job\n", sep="")
  }
  if(makeAlljobSub == "yes"){
    cat(paste("#!/bin/bash\n\n",
              "##$ -j y\n",
              "#$ -pe dev 1\n",
              "#$ -l res_cpus=1\n",
              "#$ -l res_mem=1800\n",
              "#$ -l h_rt=604800\n", #one week
              "#$ -S /bin/bash\n",
              "#$ -o ", outPath, "\n",
              "#$ -e ", outPath, "\n",
              "#$ -l res_image=cfia_all_grdi_centos-6.8-amd64_latest\n\n",
              jobsub_all,
              sep=""),
        file=paste(outPath, "jobsub_all.job", sep="")
    )
  }
}
