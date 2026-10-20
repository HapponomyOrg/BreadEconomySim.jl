# ======================================================================================================================
# merge_machines.jl — bring the simulation results of two machines together in git, with one function call.
#
# USE (in the Julia REPL: `include` once per session, then call as often as you like):
#
#     include("scripts/merge_machines.jl")
#
#     merge_machines(dry_run = true)                   # LOOK ONLY: fetch, then report what a merge would do. Changes nothing.
#     merge_machines()                                 # merge, resolve data conflicts, commit
#     merge_machines(commit_results = true)            # first commit this machine's new files under results/, then merge
#     merge_machines(commit_results = true, push_afterwards = true)
#     merge_machines(prefer = :theirs)                 # on a data conflict keep the OTHER machine's file instead
#     merge_machines(require_same_code = true)         # refuse to merge when the model code differs between the sides
#     merge_machines(repo = "/path/to/BreadEconomySim.jl")   # another repository than the one this file lives in
#
#     r = merge_machines()                             # the result is a NamedTuple you can inspect; see the docstring
#     r.status, r.conflicts, r.part_conflicts, r.code_diff
#
# THE PROBLEM THIS SOLVES
#   Both machines commit files under results/. When one machine pulls what the other pushed, git cannot decide which
#   version of a file to keep if both machines changed (or created) the same file. It stops with "divergent branches" and
#   then with a list of conflicts.
#
# WHAT THE FUNCTION DOES, IN ORDER
#   1. Optionally commits this machine's new results (commit_results = true).
#   2. Fetches the other machine's work from GitHub.
#   3. Compares the model code of the two sides and reports differences.
#   4. Makes a backup branch `backup-before-merge-<date>-<time>` at your current state (to go back: `git checkout <it>`).
#   5. Merges (a real merge, never a rebase). If git reports conflicts:
#        - every conflict under `data_dirs` (default results/) is resolved by keeping one side's file (`prefer`);
#        - a conflict anywhere else stops everything and the merge is undone. Code and documents are never guessed.
#   6. Commits the merge, and pushes it if you asked.
#
# WHY IT IS SAFE TO KEEP ONE SIDE OF THE COMBINED FILES
#   run_all writes each single run as its own file under results/parts/ and rebuilds the combined files
#   (ladder2_<N>_rounds*.csv, *_summary.csv, *_rungs.csv) from all those parts. After the merge the parts of BOTH machines
#   are present, so the combined files can simply be rebuilt: run `run_all` again with the SAME MODEL_VERSION. It skips
#   every finished run and only rewrites the combined files. (A new MODEL_VERSION would start every run from scratch.)
#
# TWO THINGS IT REPORTS BECAUSE THEY MATTER SCIENTIFICALLY
#   * A conflict inside results/parts/ is a different matter. Git only conflicts on a file that exists on both sides with
#     DIFFERENT content, so the same run (rung, system, seed) was produced twice with different results. Either the two
#     machines computed different numbers (floating point, or different code under the same MODEL_VERSION), or only the
#     line endings differ (Windows CRLF versus Mac LF). One side is kept, and every such file is listed in
#     `part_conflicts` and printed as a WARNING.
#   * If the model code (src, test, scripts, Project.toml, Manifest.toml) differs between the sides, the files are listed in
#     `code_diff`. Parts of two machines may be combined under one MODEL_VERSION only if both ran the same code.
#
# Only Julia's standard library and the `git` command are used. No packages to install.
# ======================================================================================================================

using Dates

# --- small helpers around the git command (names start with _mm_ so they cannot clash with your own code) ------------

"Run git in `repo`, return its output as a String. Throws an error if git fails."
_mm_git(repo, args...) = readchomp(`git -C $repo $args`)

"Run git in `repo` and show its output. Throws an error if git fails."
_mm_run(repo, args...) = run(`git -C $repo $args`)

"Ask git a yes/no question quietly: true when the command succeeded (exit code 0)."
_mm_ok(repo, args...) = run(pipeline(ignorestatus(`git -C $repo $args`); stdout = devnull, stderr = devnull)).exitcode == 0

"""
Files in conflict, as a Dict: path => Dict(stage => blob id).
Stage 1 is the common ancestor, stage 2 is THIS machine's version ("ours"), stage 3 is the other machine's ("theirs").
A missing stage means that side does not have the file (deleted, or never existed there).
"""
function _mm_unmerged(repo)
    out = read(`git -C $repo ls-files -u -z`, String)
    stages = Dict{String, Dict{Int, String}}()
    for entry in split(out, '\0'; keepempty = false)
        meta, path = split(entry, '\t'; limit = 2)                  # "<mode> <blob id> <stage>\t<path>"
        _, blob, stage = split(meta, ' ')
        get!(stages, String(path), Dict{Int, String}())[parse(Int, stage)] = String(blob)
    end
    return stages
end

"Predict the conflicts of merging `theirs` into HEAD without touching any file (needs git 2.38 or newer)."
function _mm_predict_conflicts(repo, theirs)
    p = open(ignorestatus(`git -C $repo merge-tree --write-tree --name-only HEAD $theirs`))
    out = read(p, String)
    wait(p)
    p.exitcode in (0, 1) || return nothing                          # an older git does not know merge-tree --write-tree
    lines = split(out, '\n')
    names = String[]
    for line in lines[2:end]                                        # line 1 is the id of the merged tree
        isempty(line) && break                                      # a blank line ends the list of file names
        push!(names, String(line))
    end
    return names
end

_mm_in_data(path, data_dirs) = any(d -> startswith(path, d), data_dirs)
_mm_is_part(path) = occursin("/parts/", path)                       # one single run: results/parts/<folder>/<run>.csv
_mm_is_marker(path) = occursin("tests_passed", basename(path))      # tests_passed_<MODEL_VERSION>.txt

# --- the function --------------------------------------------------------------------------------------------------

"""
    merge_machines(; repo, remote, branch, prefer, data_dirs, code_paths, commit_results, push_afterwards,
                     dry_run, backup, require_same_code, verbose)

Merge the other machine's work into this machine's current branch and resolve the conflicts in data files.

# Keyword arguments
* `repo`              : the repository folder. Default: the folder above the one this file is in (the file lives in `scripts/`).
* `remote`            : name of the GitHub remote. Default `"origin"`.
* `branch`            : the branch to merge. Default `nothing` = the branch you are on now.
* `prefer`            : `:ours` (default) or `:theirs`. Which side's file wins in a conflict under `data_dirs`.
                        `:ours` is this machine, `:theirs` the other one. A file deleted on the winning side stays deleted.
* `data_dirs`         : folders whose conflicts may be resolved automatically. Default `["results/"]` (forward slashes, also on Windows).
* `code_paths`        : paths compared between the two sides to warn about differing model code.
* `commit_results`    : `true` = first commit everything new or changed under `data_dirs` on this machine. Default `false`.
* `push_afterwards`   : `true` = push to the remote when everything went well. Default `false`.
* `dry_run`           : `true` = only fetch and report: no commit, no merge, no backup, no file changes. Default `false`.
* `backup`            : `true` (default) = create the backup branch before merging.
* `require_same_code` : `true` = stop before merging when the code differs between the sides. Default `false` (warn only).
* `verbose`           : `false` = print nothing, only return the result. Default `true`.

# Result
A NamedTuple with
* `status`         : `:merged`, `:up_to_date`, `:dry_run`, `:stopped_dirty_tree`, `:stopped_code_differs`
                     or `:stopped_conflicts_outside_data`.  The `:stopped_…` statuses changed nothing (or undid the merge).
* `backup`         : name of the backup branch, or `nothing`.
* `conflicts`      : all files that were (or, for a dry run, would be) in conflict.
* `resolved`       : the conflicts that were resolved.
* `part_conflicts` : conflicts among single runs in results/parts/ (see the header of this file: these deserve a look).
* `code_diff`      : code files that differ between the two sides.

Ordinary problems come back as a `status`, they do not throw. Misuse (not a git repository, wrong branch name) throws.
"""
function merge_machines(; repo::AbstractString = normpath(joinpath(@__DIR__, "..")),
                          remote::AbstractString = "origin",
                          branch::Union{Nothing, AbstractString} = nothing,
                          prefer::Symbol = :ours,
                          data_dirs::Vector{String} = ["results/"],
                          code_paths::Vector{String} = ["src", "test", "scripts", "Project.toml", "Manifest.toml"],
                          commit_results::Bool = false,
                          push_afterwards::Bool = false,
                          dry_run::Bool = false,
                          backup::Bool = true,
                          require_same_code::Bool = false,
                          verbose::Bool = true)

    prefer in (:ours, :theirs) || throw(ArgumentError("prefer must be :ours or :theirs, not :$prefer"))
    repo = String(repo)

    git(args...) = _mm_git(repo, args...)
    run_git(args...) = verbose ? _mm_run(repo, args...) : run(pipeline(`git -C $repo $args`; stdout = devnull, stderr = devnull))
    ok(args...) = _mm_ok(repo, args...)
    say(args...) = verbose && println(args...)

    keep_stage = prefer == :ours ? 2 : 3                            # index stage of the side that wins
    keeper = prefer == :ours ? "this machine's" : "the other machine's"

    backup_name = nothing
    conflicts = String[]
    resolved = String[]
    part_conflicts = String[]
    code_diff = String[]
    finish(status::Symbol) = (status = status, backup = backup_name, conflicts = conflicts, resolved = resolved,
                              part_conflicts = part_conflicts, code_diff = code_diff)

    ok("rev-parse", "--git-dir") || throw(ArgumentError("$repo is not a git repository."))
    branch = String(something(branch, git("branch", "--show-current")))
    isempty(branch) && throw(ArgumentError("Not on a branch (detached HEAD). Check out your branch first, e.g. `git checkout main`."))

    already_merging = ok("rev-parse", "-q", "--verify", "MERGE_HEAD")   # a merge that was started earlier and is unfinished
    theirs = already_merging ? "MERGE_HEAD" : "$remote/$branch"

    # ---- 1. this machine's new results; refuse to go on with uncommitted changes -----------------------------------
    if !already_merging && !dry_run
        if commit_results
            dirs = filter(d -> isdir(joinpath(repo, d)), data_dirs)
            if !isempty(dirs)
                run_git("add", "-A", "--", dirs...)
                if !ok("diff", "--cached", "--quiet")               # `--quiet` succeeds when nothing is staged
                    run_git("commit", "-m", "Results from $(gethostname())")
                    say("Committed this machine's new results.")
                end
            end
        end

        pending = git("status", "--porcelain", "--untracked-files=no")
        if !isempty(pending)
            say("Uncommitted changes in tracked files:\n", pending)
            say("\nCommit or stash these first, or call merge_machines(commit_results = true) if they are all results files.")
            return finish(:stopped_dirty_tree)
        end
    end

    # ---- 2. fetch --------------------------------------------------------------------------------------------------
    if !already_merging
        say("Fetching from $remote ...")
        run_git("fetch", remote)
        ok("rev-parse", "--verify", "-q", theirs) || throw(ArgumentError("$theirs does not exist. Check `remote` and `branch`."))

        ahead, behind = parse.(Int, split(git("rev-list", "--left-right", "--count", "HEAD...$theirs")))
        say("This machine is $ahead commit(s) ahead and $behind behind $theirs.")
        if behind == 0
            say("Nothing to merge: this machine already contains everything on $theirs.")
            push_afterwards && !dry_run && ahead > 0 && run_git("push", remote, branch)
            return finish(dry_run ? :dry_run : :up_to_date)
        end
    end

    # ---- 3. does the model code of the two sides differ? -----------------------------------------------------------
    code_diff = String.(split(git("diff", "--name-only", "HEAD", theirs, "--", code_paths...), '\n'; keepempty = false))
    if isempty(code_diff)
        say("Model code is identical on both sides.")
    else
        say("\nWARNING: $(length(code_diff)) code file(s) differ between the two sides:")
        verbose && foreach(f -> println("    ", f), code_diff)
        say("  Runs from both machines may only be combined under one MODEL_VERSION if both machines ran the same model code.\n",
            "  If you ran simulations with older code on the other machine, do not combine them.\n")
        if require_same_code
            say("Stopped because require_same_code = true. Nothing was changed.")
            return finish(:stopped_code_differs)
        end
    end

    # ---- 4. dry run: report what would happen, change nothing ------------------------------------------------------
    if dry_run
        predicted = already_merging ? sort(collect(keys(_mm_unmerged(repo)))) : _mm_predict_conflicts(repo, theirs)
        if predicted === nothing
            say("A dry run needs git 2.38 or newer to predict conflicts (yours is older). The merge itself works on older versions.")
            return finish(:dry_run)
        end
        conflicts = predicted
        outside = filter(p -> !_mm_in_data(p, data_dirs), conflicts)
        parts = filter(_mm_is_part, conflicts)
        say("Dry run: a merge would have $(length(conflicts)) conflicting file(s).")
        say("    $(length(conflicts) - length(outside) - length(parts)) combined output / marker file(s): resolved automatically (rebuildable)")
        say("    $(length(parts)) single-run file(s) under results/parts/ with different content on the two machines",
            isempty(parts) ? "" : "  <- worth a look")
        say("    $(length(outside)) file(s) outside $(join(data_dirs, ", ")): the merge would STOP",
            isempty(outside) ? "" : "  <- needs a human decision")
        if verbose
            foreach(p -> println("      outside: ", p), outside)
            foreach(p -> println("      part:    ", p), parts)
        end
        part_conflicts = parts
        return finish(:dry_run)
    end

    # ---- 5. backup, merge ------------------------------------------------------------------------------------------
    if backup
        backup_name = "backup-before-merge-" * Dates.format(now(), "yyyymmdd-HHMMSS")
        run_git("branch", backup_name)
        say("Backup branch created: $backup_name   (to return: git checkout $backup_name)")
    end

    if !already_merging
        say("Merging $theirs into $branch ...")
        merge_cmd = ignorestatus(`git -C $repo merge --no-edit $theirs`)
        merged = (verbose ? run(merge_cmd) : run(pipeline(merge_cmd; stdout = devnull, stderr = devnull))).exitcode == 0
        if merged
            say("\nMerged without conflicts.")
            push_afterwards && run_git("push", remote, branch)
            verbose && _mm_next_steps()
            return finish(:merged)
        end
    end

    stages = _mm_unmerged(repo)
    if isempty(stages) && !already_merging
        # The merge failed but there is no conflict: typically untracked files that the merge would overwrite.
        throw(ErrorException("git could not merge, and it is not a conflict (see the message above). Nothing was changed."))
    end
    conflicts = sort(collect(keys(stages)))

    # ---- 6. only data conflicts may be resolved automatically ------------------------------------------------------
    outside = filter(p -> !_mm_in_data(p, data_dirs), conflicts)
    if !isempty(outside)
        say("\nSTOP: conflicts outside $(join(data_dirs, ", ")) need a human decision:")
        verbose && foreach(p -> println("    ", p), outside)
        if already_merging
            say("The merge that was already in progress is left as it is. Resolve these files in VS Code, then call again.")
        else
            run_git("merge", "--abort")
            say("The merge has been undone: your files are exactly as before. Resolve these files by hand",
                " (`git merge $theirs` and VS Code's Merge Changes), or ask for help.")
        end
        return finish(:stopped_conflicts_outside_data)
    end

    # ---- 7. resolve: keep the preferred side -----------------------------------------------------------------------
    n_combined = 0
    n_marker = 0
    for path in conflicts
        st = stages[path]
        if haskey(st, keep_stage)                                   # the preferred side has the file: keep it
            side = prefer == :ours ? "--ours" : "--theirs"
            run_git("checkout", side, "--", path)
            run_git("add", "--", path)
        else                                                        # the preferred side deleted it: keep the deletion
            run_git("rm", "-q", "--", path)
        end
        push!(resolved, path)

        if _mm_is_part(path)
            what = !haskey(st, 2) ? "deleted here, changed on the other machine" :
                   !haskey(st, 3) ? "changed here, deleted on the other machine" :
                                    "different content on the two machines"
            push!(part_conflicts, "$path   ($what)")
        elseif _mm_is_marker(path)
            n_marker += 1
        else
            n_combined += 1
        end
    end

    leftover = _mm_unmerged(repo)
    isempty(leftover) || throw(ErrorException("Still unresolved after resolving: $(join(keys(leftover), ", "))"))

    run_git("commit", "--no-edit")
    say("\nMerge committed. Resolved $(length(resolved)) conflicting file(s), all by keeping $keeper version:")
    say("    $n_combined combined output file(s) (rounds / summary / rungs), rebuildable by run_all")
    say("    $n_marker marker file(s) (tests_passed_*)")
    say("    $(length(part_conflicts)) single-run file(s) under results/parts/")

    if !isempty(part_conflicts)
        say("\nWARNING: these single runs exist on both machines with different content. $(uppercasefirst(keeper)) file was kept.")
        verbose && foreach(w -> println("    ", w), part_conflicts)
        say("  If the runs should be reproducible (same code, same seed), a difference is a finding worth looking at.\n",
            "  Compare the two versions with:  git diff HEAD^1 HEAD^2 -- <file>   (HEAD^1 = this machine, HEAD^2 = the other)\n",
            "  If only the line endings differ, run `git config core.autocrlf input` (Mac) or `true` (PC).")
    end

    push_afterwards && run_git("push", remote, branch)
    verbose && _mm_next_steps()
    return finish(:merged)
end

function _mm_next_steps()
    println("""

    NEXT STEP: rebuild the combined files from the parts of both machines.
      Run `run_all` as usual with the SAME MODEL_VERSION. It skips all finished runs and only writes the combined files.
      At the end it prints "wrote results/… (N runs)". Check N against what you expect (rungs × systems × seeds).
      Then commit the rebuilt files and push.""")
end
