# When and how to submit a batch job

## The rule

Development nodes (`dev-amd24` and friends) are shared, interactive machines for
editing, testing, and small runs. Move to SLURM when a job will:

- run more than a few minutes
- need more than a few GB of memory
- use multiple cores in earnest
- need to run unattended

Running a long job on a dev node degrades the machine for everyone and can get
the process killed without warning.

## Checking what is available

```bash
module spider Stata          # list installed Stata versions
module load Stata/18-MP      # then: stata-mp
```

Stata MP licenses are limited campus-wide and are checked out per running
process. Request only the cores you will use, and let the job exit promptly.
Match `--cpus-per-task` to what the license permits — check current ICER
documentation rather than assuming.

## Resource requests are estimates — say so

You cannot know the right `--cpus-per-task`, `--mem`, or `--time` for a dataset
you have not profiled. When you write an sbatch script, state plainly that the
resource figures are starting estimates the user must confirm, and say what they
should check:

- **Cores**: Stata MP is licensed per-process for a fixed maximum. Requesting
  more cores than the license permits wastes an allocation. ICER's published
  figures may lag the installed version — direct the user to current ICER
  documentation or `module spider Stata` rather than asserting a number.
- **Memory**: size it from the dataset. A rough floor is
  (rows × variables × 8 bytes) for doubles, then several times that for the
  estimation itself. After a first run, `sacct -j <jobid> --format=MaxRSS` gives
  the real figure — tell the user to right-size from that rather than guessing
  high forever.
- **Time**: over-requesting delays scheduling. Under-requesting kills the job at
  the wall clock. Suggest a generous first run, then tighten using `Elapsed`
  from `sacct`.

Never present these numbers as if they were verified against MSU's limits. Say
which ones are guesses.

## Batch script template

Save as `run_analysis.sb` in the project folder:

```bash
#!/bin/bash --login
#SBATCH --job-name=stata-analysis
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --output=/mnt/home/<netid>/<project>/logs/slurm-%j.out
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<netid>@msu.edu

module purge
module load Stata/18-MP

cd /mnt/home/<netid>/<project>
stata-mp -b do 03_analysis.do

scontrol show job $SLURM_JOB_ID
```

Submit and monitor:

```bash
sbatch run_analysis.sb
squeue -u $USER              # what is queued or running
scancel <jobid>              # kill a job
sacct -j <jobid> --format=JobID,JobName,State,Elapsed,MaxRSS
```

`MaxRSS` from `sacct` tells you what the job actually used — use it to right-size
`--mem` next time instead of guessing high.

## Notes

- `stata-mp -b do file.do` writes output to `file.log` in the working directory,
  not to the SLURM `.out` file. Check both when debugging.
- Ask for time you will plausibly use. Shorter requests schedule sooner.
- ICER ships examples: `module load powertools && getexample`
- Storage: home directories have quotas. Large intermediate files belong in
  scratch space, not `$HOME`.
